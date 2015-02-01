BioPieces
=========

Installation
------------

`gem install biopieces`

Add the following alias to your `~/.bashrc` file:

`alias bp="ruby -r biopieces"`
`alias ibp="irb -r biopieces --noinspect"`


Getting started
---------------

A test script:

    #!/usr/bin/env ruby
    
    require 'biopieces'
    
    p = BP.new
    p.read_fasta(input: "input.fna")
    p.grab(select: "ATC$", keys: :SEQ)
    p.write_fasta(output: "output.fna")
    p.run(progress: true)

Or using an interactive shell using the alias ibp:

    $ ibp
    irb(main):001:0> p = BP.new
    => BP.new
    irb(main):002:0> p.read_fasta(input: "input.fna")
    => BP.new.read_fasta(input: "input.fna")
    irb(main):003:0> p.grab(select: "ATC$", keys: :SEQ)
    => BP.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ)
    irb(main):004:0> p.write_fasta(output: "output.fna")
    => BP.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna")
    irb(main):005:0> p.run(progress: true)
    => BP.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)
    irb(main):006:0>


Or chaining commands directly:

    $ ibp
    irb(main):001:0> BP.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)
    => BP.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)
    irb(main):002:0>

Or run on the command line with the alias bp:

    $ bp -e 'BP.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)'

Available Biopieces
-------------------
  * `add_key.rb`
  * `assemble_pairs.rb`
  * `assemble_seq_spades.rb`
  * `classify_seq.rb`
  * `classify_seq_mothur.rb`
  * `clip_primer.rb`
  * `cluster_otus.rb`
  * `collapse_otus.rb`
  * `collect_otus.rb`
  * `count.rb`
  * `dereplicate_seq.rb`
  * `dump.rb`
  * `grab.rb`
  * `index_taxonomy.rb`
  * `mean_scores.rb`
  * `merge_pair_seq.rb`
  * `merge_table.rb`
  * `merge_values.rb`
  * `plot_heatmap.rb`
  * `plot_histogram.rb`
  * `plot_matches.rb`
  * `plot_scores.rb`
  * `random.rb`
  * `read_fasta.rb`
  * `read_fastq.rb`
  * `read_table.rb`
  * `sort.rb`
  * `split_pair_seq.rb`
  * `split_values.rb`
  * `trim_primer.rb`
  * `trim_seq.rb`
  * `uchime_ref.rb`
  * `usearch_global.rb`
  * `write_fasta.rb`
  * `write_fastq.rb`
  * `write_table.rb`

Log and History
---------------

All BioPieces events are logged to `~/.biopieces_log`.

BioPieces history is saved to `~/.biopieces_history`.


Features
--------

Progress:

`BP.new.read_fasta(input: "input.fna").dump.run(progress: true)`

E-mail notification:

`BP.new.read_fasta(input: "input.fna").dump.run(email: mail@maasha.dk, subject: "Script done!")`


Configuration File
------------------

It is possible to pre-set options in a configuration file located in your $HOME
directory called `.biopiecesrc`. Thus if an option is not already set, its value
will fall back to the one set in the configuration file. The configuration file
contains three columns:

  * Command name
  * Option
  * Option value

Lines starting with '#' are ignored.

An example:

    maasha@mel:~$ cat ~/.biopiecesrc
    classify_seq	database	/Users/maasha/data/RDP/Mothur/trainset9_032012.pds.fasta
    classify_seq	taxonomy	/Users/maasha/data/RDP/Mothur/trainset9_032012.pds.tax

Contributing
------------

Fork it
Create your feature branch (git checkout -b my-new-feature)
Commit your changes (git commit -am 'Add some feature')
Push to the branch (git push origin my-new-feature)
Create new Pull Request
