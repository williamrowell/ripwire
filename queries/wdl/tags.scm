; ripwire WDL tags — authored here, not vendored: broadinstitute/tree-sitter-wdl ships no tags.scm.
; Every pattern below was read off a real parse (ts_node_string) of test/wdlfix, not off node-types.json.
; The grammar is WDL 1.0/1.1 and lenient. Blind spots are DISCLOSED by the degraded-parse count (a file with
; an ERROR node is listed by --skipped); they are not repaired here. Known: a literal `\n` after a placeholder
; inside a quoted string in a command (`plt.title('~{x}\nY')`) errors the enclosing task, and tree-sitter's
; recovery is PARTIAL — measured over 699 real files, an erroring task can swallow what follows it, so a
; workflow after it may be lost. Gate: test/wdlcheck.sh.

; ---- definitions ----

; `task align { ... }` — a unit of work. A callable, so it rides @definition.function like a Make target or a
; shell function; WDL has no method or class, and nothing here is a member of anything.
(task
  name: (identifier) @name) @definition.function

; `workflow main { ... }` — the entry point of a document. Also a callable (another workflow may `call` it).
(workflow
  name: (identifier) @name) @definition.function

; `struct Sample { String id File bam }` — the one user-defined type.
(struct
  name: (identifier) @name) @definition.struct

; ---- calls ----

; `call local_helper { input: ... }`, `call local_helper as h2`. UNQUALIFIED only: the target is a
; qualified_identifier with exactly ONE identifier child, and the anchors on both sides make the pattern
; refuse a two-segment target. A WDL `call` that names a task in the SAME document is a real edge.
(call
  target: (qualified_identifier
    . (identifier) @name .)) @reference.call

; NOT captured, on purpose: `call t.align` — an import-qualified call. `t` is an alias bound by
; `import "tasks.wdl" as t`, so the target lives in another document and no WDL CALL resolver exists
; yet. Laddering the bare `align` over the corpus would mint edges that are not real (the PR #81 decision;
; test/wdlfix/decoy.wdl defines a second `align` to prove it). It is simply not an edge. `import` is not
; captured HERE either: a WDL import is an Include fact read in C++ (ingest_relations.h wdlImportTarget, resolved
; by resolve.h resolveWdlImport) — a file-to-file `--deps` edge — not a @reference.import tag.
