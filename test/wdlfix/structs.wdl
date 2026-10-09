version 1.0

struct Sample {
  String id
  File bam
}

struct Cohort {
  Array[Sample] members
  Sample proband
}

task use_sample {
  input {
    Sample s
    Array[Sample] all
    Map[String, Cohort] by_name
  }
  Sample copy = s
  command <<<
    true
  >>>
  output {
    Sample out = s
  }
}

workflow flow {
  input {
    Sample x
  }
  Cohort c = Cohort { members: [x], proband: x }
}
