version 1.0

import "tasks.wdl" as t
import "sub/util.wdl"
import "https://example.org/remote.wdl" as remote
import "nowhere/tasks.wdl" as ghost

# `align` is defined in tasks.wdl AND decoy.wdl; `only_here` only in decoy.wdl; `util_task` only in sub/util.wdl.

workflow qualified {
  # bound through the alias to tasks.wdl — NOT decoy.wdl
  call t.align
  call t.align as again
  # the default namespace of `import "sub/util.wdl"` is the file stem, `util`
  call util.util_task
  # tasks.wdl has no `only_here`; decoy.wdl does. The alias names tasks.wdl, so this binds NOTHING
  call t.only_here
}

workflow unresolved_aliases {
  # an alias that resolves to no file must bind nothing, even though `align` exists elsewhere
  call remote.align
  call ghost.align
}
