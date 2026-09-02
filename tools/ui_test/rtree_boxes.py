import re, sys

path = sys.argv[1] if len(sys.argv) > 1 else 'tools/ui_test/tmp/rtree3.txt'
lines = open(path, encoding='utf-8').read().split('\n')

node_re = re.compile(r'^(.*?)([├└])─\s*child \d+:\s*(\S+)')
off_re  = re.compile(r'parentData:\s*offset=Offset\(([-\d.eE+]+), ([-\d.eE+]+)\)')

stack = []
out = []

i = 0
while i < len(lines):
    ln = lines[i]
    m = node_re.match(ln)
    if m:
        col = ln.index(m.group(2))
        name = m.group(3).strip()
        while stack and stack[-1][0] >= col:
            stack.pop()
        px, py = (stack[-1][1], stack[-1][2]) if stack else (0.0, 0.0)
        stack.append([col, px, py])
        o = None; w = None; h = None
        j = i + 1
        while j < len(lines):
            if node_re.match(lines[j]):
                break
            om = off_re.search(lines[j])
            if om and o is None:
                o = (float(om.group(1)), float(om.group(2)))
            sm = re.search(r'size:\s*Size\((-?[\d.eE+]+), (-?[\d.eE+]+)\)', lines[j])
            if sm and w is None:
                w, h = float(sm.group(1)), float(sm.group(2))
            if o is not None and w is not None:
                break
            j += 1
        if o:
            stack[-1][1] += o[0]
            stack[-1][2] += o[1]
        if 'ClipPath' in name or 'ConstrainedBox' in name or 'Semantics' in name:
            out.append((name, stack[-1][1], stack[-1][2], w or 0, h or 0))
        i = j
    else:
        i += 1

for name, ax, ay, w, h in out:
    print(f'{name} abs=({ax:.1f},{ay:.1f}) size=({w:.1f}x{h:.1f})')
