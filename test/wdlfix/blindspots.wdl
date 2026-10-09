version 1.0

task before_blind {
  command <<<
    true
  >>>
}

task plot_it {
  input {
    String sample_id
  }
  command <<<
    python3 -c "import matplotlib.pyplot as plt; plt.title('~{sample_id}\nDepth distribution', fontsize='large')"
  >>>
}

task after_blind {
  command <<<
    true
  >>>
}

workflow wf_after_blind {
  call before_blind
  call after_blind
}
