import re, sys

path = sys.argv[1] if len(sys.argv) > 1 else 'tools/ui_test/tmp/rtree2.txt'
lines = open(path, encoding='utf-8').read().split('\n')

node_re = re.compile(r'^(.*?)([├└])─\s*child \d+:\s*(\S+)')
off_re  = re.compile(r'parentData:\s*offset=Offset\(([-\d.e+]+), ([-\d.e+]+)\)')
text_re = re.compile(r'"([^"]+)"')

stack = []   # [col, acc_x, acc_y]
paras = []

i = 0
while i < len(lines):
    ln = lines[i]
    m = node_re.match(ln)
    if m:
        col = ln.index(m.group(2))
        name = m.group(3).strip()
        node_re_last = None
        while stack and stack[-1][0] >= col:
            stack.pop()
        px, py = (stack[-1][1], stack[-1][2]) if stack else (0.0, 0.0)
        stack.append([col, px, py])
        o = None; w = None; h = None; txt = None
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
            tm = text_re.search(lines[j])
            if tm and txt is None:
                txt = tm.group(1)
            if o is not None and w is not None and txt is not None:
                break
            j += 1
        if o:
            stack[-1][1] += o[0]
            stack[-1][2] += o[1]
        if name.startswith('RenderParagraph') and txt:
            paras.append((name, stack[-1][1], stack[-1][2], w or 0, h or 0, txt))
        i = j
    else:
        i += 1

for name, ax, ay, w, h, txt in paras:
    print(f'{name} abs=({ax:.1f},{ay:.1f}) size=({w:.1f}x{h:.1f}) text={txt!r}')
