# korean_profanity Website Design System

## 0. Research Log

- Product contract: the supplied “검출 증거지” direction is the visual contract, with a neutral white canvas, black redaction bars, ruled evidence rows, and signal red below 10% of the surface.
- Embedded reference: `minimalist-skill.md` supplies macro-whitespace and flat, high-contrast discipline; generic bento cards, serif/mono costume, shadows, and ambient decoration were rejected because this is an inspection document rather than a SaaS template.
- Spatial reference: StyleGallery `sidebar` pattern, https://github.com/changeroa/StyleGallery/blob/main/patterns/split-sidebar/sidebar.md, supplies the 7:5 hero split and wrap behavior. The document owns scrolling; there are no internal scroll containers.
- Interaction reference: beui.dev `action-swap` supplies immediate copy-state feedback. This implementation uses a short opacity change instead of spring motion, with instant state changes under reduced motion.
- Skipped lanes: Lazyweb and Imagen were not used because the user supplied a precise visual contract and prohibited external imagery; no image-generation tool is available in this task.

## 1. Atmosphere & Identity

A precise, restrained inspection document that feels issued, checked, and filed. The signature is the redaction motif: dense black bars and numbered evidence marks interrupt a wide white field, while signal red appears only where detection needs attention.

## 2. Color

| Role | Token | Value | Usage |
| --- | --- | --- | --- |
| Canvas | `--color-canvas` | `oklch(1 0 0)` | Page background |
| Ink | `--color-ink` | `oklch(0.16 0 0)` | Primary text and black controls |
| Muted ink | `--color-muted` | `oklch(0.43 0 0)` | Secondary copy |
| Faint ink | `--color-faint` | `oklch(0.61 0 0)` | Metadata |
| Rule | `--color-rule` | `oklch(0.87 0 0)` | 1px structure |
| Wash | `--color-wash` | `oklch(0.97 0 0)` | Code and evidence bands |
| Signal | `--color-signal` | `oklch(0.53 0.2 27)` | Detection, focus, caution |
| Signal dark | `--color-signal-dark` | `oklch(0.42 0.17 27)` | Accessible signal text |
| Inverse | `--color-inverse` | `oklch(1 0 0)` | Text on ink |

Signal red remains below 10% of painted area. It indicates detection, focus, or caution only.

## 3. Typography

System Korean fonts only. Primary: `-apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Noto Sans KR", "Malgun Gothic", sans-serif`. Code: `ui-monospace, "SFMono-Regular", Consolas, monospace`.

| Token | Size / line-height | Weight | Use |
| --- | --- | --- | --- |
| `--type-display` | `clamp(2.75rem, 6vw, 5.5rem)` / `1.04` | 760 | Hero |
| `--type-h2` | `clamp(2rem, 4vw, 3.5rem)` / `1.1` | 720 | Section headings |
| `--type-h3` | `1.25rem` / `1.35` | 700 | Subheads |
| `--type-lead` | `1.25rem` / `1.65` | 450 | Hero description |
| `--type-body` | `1rem` / `1.7` | 400 | Body and controls |
| `--type-small` | `0.875rem` / `1.55` | 500 | Metadata |
| `--type-label` | `0.75rem` / `1.4` | 700 | Short labels |

Headings use `text-wrap: balance`; prose uses `text-wrap: pretty` and stays under 70ch.

## 4. Spacing & Layout

Base unit: 4px. Tokens: `--space-1: 0.25rem`, `--space-2: 0.5rem`, `--space-3: 0.75rem`, `--space-4: 1rem`, `--space-5: 1.25rem`, `--space-6: 1.5rem`, `--space-8: 2rem`, `--space-10: 2.5rem`, `--space-12: 3rem`, `--space-16: 4rem`, `--space-20: 5rem`, `--space-24: 6rem`, `--space-32: 8rem`.

The container is 1160px with fluid gutters. Desktop uses a 12-column grid; the hero is 7:5. At 900px and below, all split regions become one column. At 375px primary content never scrolls horizontally. Document scroll is the sole scroll owner.

## 5. Components

### Action control
- Structure: semantic `a` or `button`, text label, optional inline SVG.
- Variants: ink primary, ruled secondary, signal submit.
- States: hover tint, active translate, strong red focus outline, disabled opacity, copy success/failure label.
- Accessibility: minimum 44px target, visible text label, native keyboard semantics.
- Motion: 140ms color/opacity and a 1px active transform; instant under reduced motion.

### Evidence field
- Structure: visible `label`, textarea, helper text, action row.
- States: default, focus, populated, submitted clean, submitted detected.
- Accessibility: no placeholder-only label; submit is the only action that updates the polite live region.
- Layout: vertical stack; no internal scroll owner.

### Evidence row
- Structure: term, value, optional explanation separated by 1px rules.
- Variants: API row, match detail, boundary row.
- States: static; detected values use signal text without relying on color alone.
- Layout: two or three columns on wide screens, one-column reflow on narrow screens.

### Code specimen
- Structure: caption, `pre > code`, adjacent copy action.
- States: default, copy success, copy failure, focus.
- Accessibility: wraps long commands/code on narrow screens; copy state remains visible and honest.

## 6. Motion & Interaction

- Micro state change: 140ms `cubic-bezier(0.22, 1, 0.36, 1)` for color, opacity, and transform.
- No entrance or decorative motion. Motion only confirms hover, press, focus, and copy state.
- `prefers-reduced-motion: reduce` removes transforms and durations.
- Cmd/Ctrl+K focuses the checker input and prevents the browser shortcut.

## 7. Depth & Surface

Borders-only. Structural separation uses `1px solid var(--color-rule)` or solid ink fields. There are no gradients, glass, shadows, floating cards, or decorative rounding. Corners are square except compact controls at 4px.

## 8. Source Architecture

Stylesheets are linked explicitly in cascade order from `index.html`:

1. `style.css` owns design tokens, reset/base rules, document layout, navigation, hero, install strip, and shared section/action foundations.
2. `components.css` owns the checker and result sheet, API evidence rows, responsive table base, proof band, code specimen, responsibility block, and footer.
3. `responsive.css` owns all viewport and reduced-motion media queries.

This split is an ownership boundary only. Selectors, declarations, and cascade order preserve the approved rendered behavior.

## 9. Accessibility Constraints & Accepted Debt

### Constraints

WCAG 2.2 AA: body contrast at least 4.5:1, large text at least 3:1, 44px targets, keyboard-complete operation, visible focus, semantic landmarks/headings/table labels, zoom enabled, reduced motion respected, and status announced only after form submission. Text and controls remain usable at 375px without horizontal page overflow.

### Accepted Debt

| Item | Location | Why accepted | Owner / Exit |
| --- | --- | --- | --- |
| No automated screen-reader speech transcript | Demo live region | Preliminary QA can verify DOM semantics and keyboard behavior, but not a specific assistive technology voice | Validate with VoiceOver before release |
