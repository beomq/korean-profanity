import 'dart:collection';
import 'dart:typed_data';

/// One automaton output ending at an exclusive Unicode-scalar offset.
final class AhoHit {
  const AhoHit({required this.patternId, required this.end});

  final int patternId;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is AhoHit && patternId == other.patternId && end == other.end;

  @override
  int get hashCode => Object.hash(patternId, end);

  @override
  String toString() => 'AhoHit(patternId: $patternId, end: $end)';
}

/// Immutable Aho-Corasick automaton whose pattern IDs are input-list indexes.
///
/// [scan] reads Unicode scalars and returns every matching ID, including
/// overlaps. IDs ending at the same scalar are emitted in ascending order.
final class AhoCorasick {
  factory AhoCorasick(List<String> patterns) => _Builder(patterns).build();

  const AhoCorasick._(
    this._transitions,
    this._failure,
    this._outputStart,
    this._outputCount,
    this._patternId,
  );

  final List<Map<int, int>> _transitions;
  final Int32List _failure;
  final Int32List _outputStart;
  final Int32List _outputCount;
  final Int32List _patternId;

  /// Returns all matching pattern IDs in end-position then ID order.
  List<int> scan(String input) => [
        for (final hit in scanHits(input)) hit.patternId,
      ];

  /// Returns matching IDs with exclusive Unicode-scalar end positions.
  List<AhoHit> scanHits(String input) {
    final matches = <AhoHit>[];
    var state = 0;
    var end = 0;
    for (final scalar in input.runes) {
      end++;
      var target = _transitions[state][scalar];
      while (target == null && state != 0) {
        state = _failure[state];
        target = _transitions[state][scalar];
      }
      state = target ?? 0;

      final outputEnd = _outputStart[state] + _outputCount[state];
      for (var index = _outputStart[state]; index < outputEnd; index++) {
        matches.add(AhoHit(patternId: _patternId[index], end: end));
      }
    }
    return matches;
  }
}

final class _Builder {
  _Builder(this.patterns);

  final List<String> patterns;
  final List<_BuildNode> _nodes = [_BuildNode()];

  AhoCorasick build() {
    _buildTrie();
    _buildFailures();
    return _freeze();
  }

  void _buildTrie() {
    final seen = <String>{};
    for (var id = 0; id < patterns.length; id++) {
      final pattern = patterns[id];
      if (pattern.isEmpty) {
        throw ArgumentError.value(
            pattern, 'patterns[$id]', 'must not be empty');
      }
      if (!seen.add(pattern)) {
        throw ArgumentError.value(pattern, 'patterns[$id]', 'must be unique');
      }

      var node = 0;
      for (final scalar in pattern.runes) {
        node = _nodes[node].edges.putIfAbsent(scalar, () {
          _nodes.add(_BuildNode());
          return _nodes.length - 1;
        });
      }
      _nodes[node].outputs.add(id);
    }
  }

  void _buildFailures() {
    final queue = Queue<int>();
    for (final child in _nodes[0].edges.values) {
      queue.add(child);
    }

    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      for (final edge in _nodes[node].edges.entries) {
        final target = edge.value;
        var fallback = _nodes[node].failure;
        while (fallback != 0 && !_nodes[fallback].edges.containsKey(edge.key)) {
          fallback = _nodes[fallback].failure;
        }
        _nodes[target].failure = _nodes[fallback].edges[edge.key] ?? 0;
        _nodes[target].outputs.addAll(
              _nodes[_nodes[target].failure].outputs,
            );
        _nodes[target].outputs.sort();
        queue.add(target);
      }
    }
  }

  AhoCorasick _freeze() {
    final transitions = List<Map<int, int>>.unmodifiable([
      for (final node in _nodes) Map<int, int>.unmodifiable(node.edges),
    ]);
    final outputLength =
        _nodes.fold<int>(0, (sum, node) => sum + node.outputs.length);
    final failure = Int32List(_nodes.length);
    final outputStart = Int32List(_nodes.length);
    final outputCount = Int32List(_nodes.length);
    final patternId = Int32List(outputLength);
    var outputIndex = 0;

    for (var nodeIndex = 0; nodeIndex < _nodes.length; nodeIndex++) {
      final node = _nodes[nodeIndex];
      failure[nodeIndex] = node.failure;
      outputStart[nodeIndex] = outputIndex;
      outputCount[nodeIndex] = node.outputs.length;
      for (final id in node.outputs) {
        patternId[outputIndex++] = id;
      }
    }
    return AhoCorasick._(
      transitions,
      failure,
      outputStart,
      outputCount,
      patternId,
    );
  }
}

final class _BuildNode {
  final Map<int, int> edges = {};
  final List<int> outputs = [];
  int failure = 0;
}
