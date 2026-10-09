version 1.0

# A second, separate `struct Sample` (the warp corpus copies RuntimeAttr into 15 files). --uses is name-matched by
# design, so its one mention joins structs.wdl's rows and defs= says there are two definitions.
struct Sample {
  String id
}

task copy_user {
  input {
    Sample s
  }
  command <<<
    true
  >>>
}
