#!/usr/bin/env bash
# WDL (.wdl): definition kinds, the unqualified call edge, the decoy, the qualified call that must NOT
# mint an edge, and the DISCLOSED grammar blind spot. Written RED against a binary without the WDL
# change (which indexes no .wdl at all and so extracts zero symbols from this fixture) before the
# change landed.
#
# Grammar: broadinstitute/tree-sitter-wdl (WDL 1.0/1.1), measured 90.7% clean over 699 real files; in
# the files that DO fail, recovery is partial (an erroring task can swallow what follows it), so the
# blind-spot arm asserts DISCLOSURE (degraded-parse, err>=1) and survival of what precedes the error —
# NOT that everything after it survives.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${RIPWIRE_BIN:-$ROOT/build/ripwire}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir "$TMP/cache"
export XDG_CACHE_HOME="$TMP/cache"
cp -R "$ROOT/test/wdlfix" "$TMP/fix"
"$BIN" "$TMP/fix" --no-cache > "$TMP/map.xml"

python3 - "$TMP/map.xml" <<'PY'
import sys, collections, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
byfile = {f.get('p'): {s.get('n'): s for s in f.iter('s')} for f in root.iter('f')}
allsyms = collections.defaultdict(list)
for p, d in byfile.items():
    for n, s in d.items():
        allsyms[n].append((p, s))
def calls(p, n): return {c.get('n') for c in byfile[p][n].iter('c')}

tasks = byfile['tasks.wdl']
# --- kinds: task and workflow are callables, struct is a struct ---
for fn in ('align', 'sort_bam'):
    assert tasks[fn].get('t') == 'fn', (fn, tasks[fn].attrib)
assert tasks['Sample'].get('t') == 'struct', tasks['Sample'].attrib
main = byfile['main.wdl']
assert main['main'].get('t') == 'fn', main['main'].attrib            # workflow
assert main['local_helper'].get('t') == 'fn', main['local_helper'].attrib
# `command { }` (brace form, `${}` placeholders) and `command <<< >>>` (`~{}`) both reach their task.
assert 'sort_bam' in tasks and 'align' in tasks
print('  PASS WDL definition kinds (task/workflow -> fn, struct -> struct)')

# --- decoy: the same task name in two files stays two defs, one per file ---
assert sorted(p for p, _ in allsyms['align']) == ['decoy.wdl', 'tasks.wdl'], allsyms['align']
assert sorted(p for p, _ in allsyms['only_here']) == ['decoy.wdl']
print('  PASS decoy: a duplicated task name keeps one def per file')

# --- call edges ---
# `call local_helper` names a task in the SAME file: a real edge.
assert 'local_helper' in calls('main.wdl', 'main'), calls('main.wdl', 'main')
# `call t.align` / `call t.sort_bam` are QUALIFIED by an import alias. No WDL resolver exists yet, and a
# qualified call must never fall onto the global name ladder (decoy.wdl also defines `align`): it is
# counted as unresolved, not as an edge.
assert 'align' not in calls('main.wdl', 'main'), 'qualified call t.align minted an edge (decoy risk)'
assert 'sort_bam' not in calls('main.wdl', 'main'), 'qualified call t.sort_bam minted an edge'
print('  PASS unqualified call edge, and no edge for an import-qualified call')

# --- DISCLOSED blind spot: a literal \n after a placeholder inside a quoted string in a command ---
b = byfile['blindspots.wdl']
assert b['before_blind'].get('t') == 'fn', b.keys()
print('  PASS definitions before the blind spot survive')
PY

# --- determinism + cache round trip (a contract, not a nicety) ---
for n in a b c; do "$BIN" "$TMP/fix" > "$TMP/$n.xml"; done
cmp "$TMP/map.xml" "$TMP/a.xml"
cmp "$TMP/a.xml" "$TMP/b.xml"
cmp "$TMP/b.xml" "$TMP/c.xml"
echo '  PASS cold/warm determinism and XML'

# --- a relative and an absolute crawl root resolve identically ---
( cd "$TMP" && "$BIN" ./fix --no-cache > "$TMP/rel.xml" )
"$BIN" "$TMP/fix" --no-cache > "$TMP/abs.xml"
python3 - "$TMP/rel.xml" "$TMP/abs.xml" <<'PY'
import sys, xml.etree.ElementTree as ET
def shape(p):
    # Compare by BASENAME: a relative crawl root keeps its own root segment in p= (./fix -> "fix/x.wdl")
    # while an absolute one does not. Pre-existing behaviour shared by every language.
    r = ET.parse(p).getroot()
    return sorted((f.get('p').rsplit('/', 1)[-1], s.get('n'), s.get('t'))
                  for f in r.iter('f') for s in f.iter('s'))
assert shape(sys.argv[1]) == shape(sys.argv[2]), 'relative and absolute crawl roots disagree'
print('  PASS relative and absolute crawl roots agree')
PY

# --- the degraded parse is DISCLOSED, not merely survived ---
# PRESENCE GUARD: without it the survival arm passes vacuously the moment the fixture stops hitting an
# ERROR node (an upstream grammar fix, a fixture edit).
"$BIN" "$TMP/fix" --skipped --no-cache > "$TMP/skip.xml"
python3 - "$TMP/skip.xml" <<'PYSKIP'
import sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
rows = {h.get('p'): h for h in root.iter('h')}
b = rows.get('blindspots.wdl')
assert b is not None, ('blindspots.wdl is not disclosed as degraded at all — the survival arm is vacuous; '
                       'rows=%s' % sorted(rows))
assert b.get('why') == 'degraded-parse', b.attrib
assert int(b.get('err', '0')) >= 1, b.attrib
assert 'tasks.wdl' not in rows and 'main.wdl' not in rows and 'decoy.wdl' not in rows, sorted(rows)
print('  PASS the blind-spot fixture is DISCLOSED degraded (why=degraded-parse); clean files are not')
PYSKIP

echo 'ALL PASS'
