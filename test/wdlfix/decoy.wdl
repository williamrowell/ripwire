version 1.0

# Same task name as tasks.wdl::align — must stay a separate definition in its own file.
task align {
  input {
    File x
  }
  command <<<
    decoy ~{x}
  >>>
}

task only_here {
  command <<<
    true
  >>>
}
