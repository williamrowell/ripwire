version 1.0

# NEGATIVE CONTROL: a VALUE named like a struct. Only identifiers in TYPE positions are type mentions; this is a read.
task shadow {
  input {
    String Cohort
  }
  command <<<
    echo ~{Cohort}
  >>>
  output {
    String o = Cohort
  }
}
