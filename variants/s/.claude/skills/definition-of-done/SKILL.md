---
name: definition-of-done
description: Definition of done for this repository. Use before you finish any coding task, before you commit, and before you report a task as done or complete.
---

# Definition of done

Before you finish, go through this checklist. A task is done only when every point holds.

1. **Spec met.** Re-read `SPEC.md` and compare it point by point with the implementation, including edge cases and error handling, not only what the tests cover.
2. **Tests green.** Run the full suite with `python -m pytest` and read the output. Zero failures, zero errors.
3. **Tests untouched.** Never edit, skip, delete or loosen a test to make it pass, and never special-case test inputs in the code. If a test contradicts the spec, stop and report the conflict instead of working around it.
4. **Committed.** `git status` is clean and the work is committed with a meaningful message. Uncommitted work does not count.
5. **Honest report.** Say "done" only if points 1 to 4 hold. Otherwise list exactly what is open or failing, and do not call the task done.
