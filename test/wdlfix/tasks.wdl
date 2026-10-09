version 1.0

struct Sample {
  String sample_id
  File bam
}

task align {
  input {
    File reads
    Array[String] extra = []
    Boolean fast = false
  }

  command <<<
    set -euo pipefail
    aligner ~{true="--fast" false="" fast} ~{sep=" " extra} ~{reads}
  >>>

  output {
    File bam = "out.bam"
  }

  runtime {
    docker: "example/aligner:1"
  }
}

task sort_bam {
  input {
    File bam
  }

  command {
    samtools sort ${bam} -o sorted.bam
  }

  output {
    File sorted = "sorted.bam"
  }
}
