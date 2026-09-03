import 'dart:js_interop';

import 'package:korean_profanity/korean_profanity.dart';
import 'package:web/web.dart';

final KoreanProfanityFilter _filter = KoreanProfanityFilter();

void main() {
  final form = _element<HTMLFormElement>('checker-form');
  final input = _element<HTMLTextAreaElement>('checker-input');

  form.addEventListener(
    'submit',
    ((Event event) {
      event.preventDefault();
      _renderResult(input.value);
    }).toJS,
  );

  final presets = document.querySelectorAll('[data-preset]');
  for (var index = 0; index < presets.length; index++) {
    final button = presets.item(index)! as Element;
    button.addEventListener(
      'click',
      ((Event _) {
        input.value = button.getAttribute('data-preset') ?? '';
        input.focus();
      }).toJS,
    );
  }

  final copyButtons = document.querySelectorAll('[data-copy-target]');
  for (var index = 0; index < copyButtons.length; index++) {
    final button = copyButtons.item(index)! as Element;
    button.addEventListener(
      'click',
      ((Event _) {
        _copy(button as HTMLButtonElement);
      }).toJS,
    );
  }

  document.addEventListener(
    'keydown',
    ((Event event) {
      final keyboardEvent = event as KeyboardEvent;
      if ((keyboardEvent.metaKey || keyboardEvent.ctrlKey) &&
          keyboardEvent.key.toLowerCase() == 'k') {
        keyboardEvent.preventDefault();
        input.focus();
      }
    }).toJS,
  );
}

void _renderResult(String text) {
  final matches = _filter.findAll(text);
  final hasMatch = matches.isNotEmpty;
  final masked = _filter.mask(text);

  _text('contains-output', hasMatch ? 'true' : 'false');
  _text('count-output', '${matches.length}건');
  _text('mask-output', masked.isEmpty ? '(빈 입력)' : masked);

  final badge = _element<HTMLElement>('result-badge');
  badge.textContent = hasMatch ? '검출' : '미검출';
  badge.classList.toggle('is-detected', hasMatch);

  final detail = _element<HTMLElement>('match-detail');
  if (hasMatch) {
    detail.removeAttribute('hidden');
  } else {
    detail.setAttribute('hidden', '');
  }
  if (hasMatch) {
    final match = matches.first;
    _text('match-slice', match.text);
    _text('match-word', match.word);
    _text('match-range', '${match.start}–${match.end}');
    _text('match-tier', match.tier.name);
    _text('match-gap', match.isGapMatch ? 'true' : 'false');
    _text('demo-status', '검출되었습니다. strict 사전에서 ${matches.length}건을 찾았습니다.');
  } else {
    _text(
      'demo-status',
      text.isEmpty
          ? '입력이 비어 있습니다. 검사할 문장을 입력하세요.'
          : 'strict 사전에서 일치 항목을 찾지 못했습니다.',
    );
  }
}

Future<void> _copy(HTMLButtonElement button) async {
  final targetId = button.getAttribute('data-copy-target');
  if (targetId == null) return;
  final source = document.getElementById(targetId);
  final label = button.querySelector('span');
  if (source == null || label == null) return;

  final originalLabel = targetId == 'install-command' ? '명령어 복사' : '코드 복사';
  try {
    await window.navigator.clipboard.writeText(source.textContent ?? '').toDart;
    button.setAttribute('data-state', 'success');
    label.textContent = '복사됨';
  } catch (_) {
    button.setAttribute('data-state', 'error');
    label.textContent = '복사 실패';
  }

  window.setTimeout(
    (() {
      button.removeAttribute('data-state');
      label.textContent = originalLabel;
    }).toJS,
    1800.toJS,
  );
}

T _element<T extends Element>(String id) => document.getElementById(id) as T;

void _text(String id, String value) {
  _element<HTMLElement>(id).textContent = value;
}
