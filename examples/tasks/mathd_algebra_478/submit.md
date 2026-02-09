# Proof of theorem mathd_algebra_478

## Statement
Given real numbers `b, h, v` with positivity conditions `0 < b ∧ 0 < h ∧ 0 < v`, the equation `v = 1/3 * (b * h)`, and the concrete values `b = 30`, `h = 13/2`, we must show `v = 65`.

## Proof outline
The proof proceeds by direct substitution and arithmetic simplification.

1. From hypotheses `h₂ : b = 30` and `h₃ : h = 13/2` we substitute these values into `h₁ : v = 1/3 * (b * h)`.
2. After substitution we obtain `v = 1/3 * (30 * (13/2))`.
3. Evaluating the right-hand side yields `65`; therefore `v = 65`.

## Lean implementation
The Lean proof uses three basic tactics:

- `rcases` splits the conjunction `h₀` into its three components (the positivity assumptions are not needed for the equality, but we keep them for completeness).
- `rw [h₂, h₃] at h₁` replaces `b` by `30` and `h` by `13/2` inside the equation `h₁`.
- `norm_num at h₁` simplifies the arithmetic expression `1/3 * (30 * (13/2))` to `65`, turning `h₁` into `v = 65`.
- `exact h₁` closes the goal.

The entire proof is four lines long and relies only on `norm_num` for numerical computation; no extra lemmas from the library are required.

## Why other tactics are not used
- `linarith` fails because it cannot handle the division by `3` (even though it is a constant rational factor) without explicit substitution.
- A `calc` block would be possible but is unnecessary for such a straightforward substitution.
- The positivity assumptions `h₀` are irrelevant for the equality; they are included in the statement only to reflect the original problem context.

## Verification
The proof passes Lean's type checker with the import `Mathlib.Tactic`, which provides the `norm_num` tactic.