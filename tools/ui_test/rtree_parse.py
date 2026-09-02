import re, sys, json

path = sys.argv[1] if len(sys.argv) > 1 else 'tools/ui_test/tmp/rtree2.txt'
lines = open(path, encoding='utf-8').read().split('\n')

node_re = re.compile(r'^(.*?)([├└])─\s*child \d+:\s*(\S+).*$')
off_re  = re.compile(r'parentData:\s*offset=Offset\(([\d.e+-]+), ([\d.e+-]+)\)')

# stack of (column, node_name, acc_x, acc_y)
stack = [(0, 'ROOT', 0.0, 0.0)]
results = []

def col_of(line):
    # column where the child marker sits
    m = node_re.match(line)
    if m:
        return m.group(1).count('│') + m.group(1).count(' ') + m.group(1).count('└')  # approx
        # better: index of marker char
    return None

for idx, ln in enumerate(lines):
    m = node_re.match(ln)
    if m:
        prefix, marker, name = m.group(1), m.group(2), m.group(3)
        col = len(prefix)
        # pop until top col < col
        while stack and stack[-1][0] >= col:
            stack.pop()
        px, py = stack[-1][2], stack[-1][3]
        stack.append([col, name, px, py])
        # look for offset line within next ~8 lines, same indentation level context
        for j in range(idx+1, min(len(lines), idx+8)):
            om = off_re.search(lines[j])
            if om:
                ox, oy = float(om.group(1)), float(om.group(2))
                node = stack[-1]
                node[2] = px + ox
                node[3] = py + oy
                break
        results.append([name, stack[-1][2], stack[-1][3]])
    # else: property line, ignore

# find any node whose name mentions GestureDetector-ish or the target text
for r in results:
    if 'GestureDetector' in r[0] or 'Paragraph' in r[0] or 'ConstrainedBox' in r[0]:
        pass
