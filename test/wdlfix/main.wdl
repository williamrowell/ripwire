version 1.0

import "tasks.wdl" as t
import "sub/util.wdl" as u
import "https://example.org/remote.wdl" as remote
import "nowhere/tasks.wdl" as ghost

task local_helper {
  input {
    String msg
  }
  command <<<
    echo ~{msg}
  >>>
  output {
    String out = read_string(stdout())
  }
}

workflow main {
  input {
    File reads
  }

  call t.align { input: reads = reads }
  call t.sort_bam as sorter { input: bam = align.bam }
  call local_helper { input: msg = "done" }

  output {
    File final_bam = sorter.sorted
  }
}
