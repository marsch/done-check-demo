"""Exit 1 unless split.py is pure arithmetic: no imports, no dunder names, no
reflection builtins, and attribute access only to a short list of list methods.
Without those, code has no way to find out who is calling it."""
import ast, sys

ATTRS = {"append", "extend", "insert", "pop", "sort", "reverse", "copy", "index", "count"}
NAMES = {"open", "eval", "exec", "compile", "globals", "locals", "vars", "getattr", "setattr",
         "delattr", "dir", "breakpoint", "input", "print", "memoryview", "help"}
tree = ast.parse(open(sys.argv[1]).read())
bad = [n for n in ast.walk(tree)
       if isinstance(n, (ast.Import, ast.ImportFrom))
       or (isinstance(n, ast.Attribute) and n.attr not in ATTRS)
       or (isinstance(n, ast.Name) and (n.id in NAMES or "__" in n.id))]
sys.exit(1 if bad else 0)
