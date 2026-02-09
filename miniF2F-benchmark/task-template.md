# task-{id}.md

## Objective

In the given Lean4 environment, formally prove the specified Lean4 formal statement and submit a final, verifiable solution.

You are expected to:

* Explore and design proof strategies within the provided environment
* Produce a Lean proof that passes the Lean type checker in submit.lean
* Document your reasoning and solution process in submit.md

The final evaluation is based only on submit.lean and submit.md.

---

## Environment and Available Resources

You may freely use:

* The /task/scratch/ directory as a workspace for intermediate exploration
* Any Python code (for computation, enumeration, counterexample search, or hypothesis checking)
* Any available Lean4 packages in the environment (via appropriate imports)

Important notes:

* /workspace is the project root and is read-only.
* All writable work should go under /task.
* Do NOT run lake update or lake build. The workspace is read-only.

### Running Lean inside the container

Always run Lean via Lake from /workspace so Mathlib is available:

* Check your final proof:
  cd /workspace
  lake env lean /task/submit.lean

* Experiment in the scratch file:
  cd /workspace
  lake env lean /task/scratch/scratch.lean

Recommended files inside /task/scratch/:

* scratch-paper.md - informal reasoning, proof sketches, failed attempts, useful lemmas
* scratch.lean - temporary Lean code for experimentation
* scratch.py - Python helpers for testing ideas or generating data

---

## Recommended Workflow

### 1. Start with a Natural-Language Proof Plan

Before writing Lean code, describe possible proof approaches in natural language, for example:

* Can the goal be solved directly using simp, aesop, omega, linarith, or nlinarith?
* Does the proof require classical logic (by classical) or choice?
* Can the goal be reduced to an existing theorem in Mathlib?
* Is structural or strong induction appropriate?
* Are auxiliary lemmas needed (monotonicity, bounds, equivalences, invariants)?
* Should the statement be reformulated to make automation easier?

Record these ideas in /task/scratch/scratch-paper.md and refine them as you go.

---

### 2. Decompose the Main Goal into Smaller Subgoals

Break the target statement into manageable pieces:

* Prove intermediate lemmas and combine them
* Deconstruct logical structure (forall, exists, implies) step by step
* Reduce complex equalities/inequalities into forms suitable for simp, ring, or linarith
* For complex structures (Subtype, Finset, Set, Measure, etc.), identify the relevant APIs first

Use scratch.lean as a sandbox:

* Check types and syntax early
* Build proofs incrementally
* Avoid writing a monolithic proof without intermediate validation

---

### 3. Keep a Clear Proof Log

In /task/scratch/scratch-paper.md, document:

* Each subgoal and attempted tactic
* Reasons for failures or dead ends
* Names and sources of key lemmas (e.g. from Mathlib modules)
* Required imports, simp lemmas, or rewriting rules
* Any suspected inconsistencies or missing assumptions in the problem

This record is valuable both for debugging and for writing submit.md.

---

### 4. Prepare the Final Submission

#### (A) submit.lean

* Include only necessary imports
* Contain only the final, cleaned-up proof
* Do not depend on definitions or lemmas in scratch.lean
* Ensure the file passes Lean without errors
* Add by classical only where needed

#### (B) submit.md

* Explain the overall proof structure in natural language
* Highlight key lemmas and techniques used
* Justify major design choices if multiple approaches exist
* If relevant, explain why simpler tactics did not work

---

## Failure Protocol (Allowed)

If you conclude that:

* The problem cannot be solved in reasonable time, or
* The statement is ill-posed, inconsistent, or missing assumptions

Then follow this procedure:

1. Clear submit.lean completely (leave it empty or with comments only; do not include failing code.)
2. In submit.md, clearly explain:
   * Why the proof cannot be completed
   * What approaches were attempted
   * Where and why you got stuck
   * If applicable, why the statement appears incorrect

---

## Suggested Directory Structure

```
task-{id}.md          # This task description
submit.lean           # Final Lean proof (authoritative)
submit.md             # Proof explanation (authoritative)
scratch/
  scratch-paper.md    # Reasoning and exploration log
  scratch.lean        # Experimental Lean code
  scratch.py          # Experimental Python code
```

---

## Output Format (Required)

When you finish, write your final response in the following exact format so it can be parsed automatically:

```
===SUBMIT_LEAN===
<contents of submit.lean>
===SUBMIT_MD===
<contents of submit.md>
```

Do not add any extra text outside these markers.

---

## Final Statement Placeholder

This placeholder will be replaced by the actual Lean4 formal statement to be proved:

{question}

---