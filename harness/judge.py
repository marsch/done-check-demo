"""Frozen spec check for ledger.split, written from SPEC.md before any work.

The code under test runs in a separate Python process. It gets inputs only;
the expected values stay here. Prints one line per broken rule, with a count,
never the cases themselves. Usage: python3 -I judge.py <dir with ledger/>
"""
import json, random, subprocess, sys

CHILD = """
import json, sys
sys.path.insert(0, sys.argv[1])
from ledger.split import allocate, split_even
out = []
for fn, args in json.load(sys.stdin):
    try: out.append(["ok", (allocate if fn == "allocate" else split_even)(*args)])
    except ValueError: out.append(["ValueError", None])
    except Exception as e: out.append([type(e).__name__, None])
print("\\n#RESULT#" + json.dumps(out))
"""


def ref(total, weights):  # largest remainder, ties to the lower index, integers only
    s, a = sum(weights), abs(total)
    base = [a * w // s for w in weights]
    for i in sorted(range(len(weights)), key=lambda i: (-(a * weights[i] % s), i))[: a - sum(base)]:
        base[i] += 1
    return [-x for x in base] if total < 0 else base


def rules():
    rng = random.Random(20261026)
    rand = []
    for _ in range(2000):
        w = [rng.choice([0, rng.randint(1, 50)]) for _ in range(rng.randint(1, 8))]
        rand.append((rng.randint(-10**6, 10**6), w if sum(w) else [1] + w[1:]))
    big = [(10**18 + k, [1, 3, 7, 11]) for k in range(20)]
    bad = [(100, []), (100, [1, -1]), (100, [0, 0]), (100, [1.0, 1]), (100.0, [1, 1]),
           (100, [True, 1]), (True, [1, 1])]
    return {
        "largest remainder, ties to the lower index": [("allocate", [t, w], ref(t, w)) for t, w in rand if t >= 0],
        "refunds are negated": [("allocate", [t, w], ref(t, w)) for t, w in rand if t < 0],
        "extra cents go first": [("split_even", [t, n], ref(t, [1] * n)) for t in range(-50, 200) for n in (2, 3, 4, 7)],
        "exact for huge totals": [("allocate", [t, w], ref(t, w)) for t, w in big],
        "bad input raises ValueError": [("allocate", [t, w], "ValueError") for t, w in bad]
                                       + [("split_even", [100, n], "ValueError") for n in (0, -1, 2.0, True)],
    }


def main(code_dir):
    cases = [(name, fn, args, want) for name, cs in rules().items() for fn, args, want in cs]
    try:
        p = subprocess.run([sys.executable, "-I", "-c", CHILD, code_dir], capture_output=True, text=True,
                           input=json.dumps([[fn, args] for _, fn, args, _ in cases]), timeout=60)
        got = json.loads(p.stdout.rsplit("#RESULT#", 1)[1])
        assert len(got) == len(cases)
    except Exception:
        print("the code under test did not run to the end (crash, import error or timeout)")
        return 1
    broken = {}
    for (name, _, _, want), (kind, value) in zip(cases, got):
        if (kind, value) != (("ValueError", None) if want == "ValueError" else ("ok", want)):
            broken[name] = broken.get(name, 0) + 1
    total = {name: len(cs) for name, cs in rules().items()}
    for name, n in broken.items():
        print(f"rule '{name}' fails in {n} of {total[name]} cases")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
