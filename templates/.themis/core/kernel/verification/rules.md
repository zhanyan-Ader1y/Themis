# Themis Verification

## Responsibility

Produce command-backed facts after Implementation about work governed by the approved Specification, Plan, and pre-implementation Review. Verification owns observed results, not code changes, design approval, or human acceptance.

## Inputs

- explicitly configured commands and Gates from `workspace/manifest.yaml` and effective policy;
- current approved Plan/Review and implementation revision;
- Task evidence and required AC coverage.

## Outputs

Write attempts beneath `workspace/runs/` and evidence beneath `workspace/evidence/`. Return:

```text
pass | fail | inconclusive
```

Each attempt records executable/args, cwd, relevant environment, exit, stdout/stderr refs, covered ACs, revision, classification, rerun history, and limitations.

## Boundaries

- Do not claim success without observed output and durable evidence for every blocking Gate.
- Do not invent a command when manifest configuration is `null`.
- Missing commands, output, or required evidence produce `inconclusive`/`unavailable`, never `pass`.
- Do not modify project code, reconsider the approved design, issue Review approval, claim Human Acceptance, or generate Summary.
- Any relevant implementation change invalidates affected evidence and Acceptance.
