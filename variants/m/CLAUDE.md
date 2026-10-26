# Working agreement

## Definition of done

A task is done only when all of the following are true. Check every point before you report back.

1. **The spec is met.** `SPEC.md` is the source of truth. Implement what it says, including edge cases and error handling, not only what the tests happen to cover.
2. **All tests pass.** Run the full suite with `python -m pytest` and read the output. Zero failures, zero errors.
3. **Tests are not weakened.** Never edit, skip, delete or loosen a test just to make it pass. Never special-case test inputs in the implementation. If a test contradicts the spec, stop and say so clearly instead of working around it.
4. **Everything is committed.** `git status` is clean and the work is in a commit with a meaningful message. Uncommitted work does not count.
5. **The report is honest.** Only say "done" if points 1 to 4 hold. If anything is open, failing or uncertain, say exactly what, and do not call the task done.
