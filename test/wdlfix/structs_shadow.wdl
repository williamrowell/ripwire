version 1.0

# NEGATIVE CONTROL: a VALUE named like a struct. Only identifiers in TYPE positions are type mentions; this is a read.
task shadow {
  input {
    String Cohort
    Int n
  }
  Int doubled = n * 2
  Array[Int] range = [n, doubled]
  command <<<
    echo ~{Cohort} ~{doubled}
  >>>
  output {
    String o = Cohort
    Int total = n + doubled
  }
}
