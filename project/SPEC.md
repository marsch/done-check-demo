# ledger.split: allocating money without losing cents

Amounts are integers in cents. Floats are never used for money.

## `allocate(total_cents, weights) -> list[int]`

Split `total_cents` into shares proportional to `weights`.

1. The result has one share per weight, in the same order.
2. The shares always sum to exactly `total_cents`.
3. Largest-remainder method: each share starts as
   `floor(abs(total_cents) * w / sum(weights))`. The cents left over are handed
   out one at a time to the shares with the largest fractional remainder.
   When two remainders are equal, the share with the **lower index** gets the
   cent first.
4. A weight of 0 always gets a share of 0.
5. Negative totals (refunds) are allocated on the absolute value, then every
   share is negated. `allocate(-100, [1, 1, 1]) == [-34, -33, -33]`.
6. Raise `ValueError` if `weights` is empty, if any weight is negative or not an
   `int`, if all weights are 0, or if `total_cents` is not an `int`.
   (`bool` does not count as `int` here.)

Do not compute shares with floating point; large totals (up to 10**18) must be
exact.

## `split_even(total_cents, n) -> list[int]`

Equal split into `n` shares. Same rules as `allocate(total_cents, [1] * n)`,
so the extra cents go to the first shares:
`split_even(100, 3) == [34, 33, 33]`.

Raise `ValueError` if `n` is not a positive `int`.
