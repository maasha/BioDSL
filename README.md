BioPieces
=========

Installation
------------

`gem install biopieces`

Getting started
---------------

A test script:

    #!/usr/bin/env ruby
    
    require 'biopieces'
    
    p = BP.new.
    read_fasta(input: "input.fna").
    grab(select: "ATC$", keys: :SEQ).
    write_fasta(output: "output.fna").
    run(progress: true)

Or using an interactive shell using the alias ibp which you can create by
adding the following to your `~/.bashrc` file:

    alias ibp="irb -r biopieces --noinspect"

And then start the interactive shell:

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

Or run on the command line with the alias bp which you can create by adding the
following to your `~/.bashrc` file:

    alias bp="ruby -r biopieces"

Then you can run the below from the command line:

    $ bp -e 'BP.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)'

Available Biopieces
-------------------

  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:add_key`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:analyze_residue_distribution`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:assemble_pairs`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:assemble_seq_spades`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:classify_seq`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:classify_seq_mothur`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:clip_primer`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:cluster_otus`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:collapse_otus`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:collect_otus`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:count`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:dereplicate_seq`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:dump`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:grab`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:index_taxonomy`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:mean_scores`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:merge_pair_seq`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:merge_table`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:merge_values`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:plot_heatmap`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:plot_histogram`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:plot_matches`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:plot_nucleotide_distribution`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:plot_scores`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:random`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:read_fasta`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:read_fastq`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:read_table`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:sort`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:split_pair_seq`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:split_values`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:trim_primer`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:trim_seq`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:uchime_ref`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:usearch_global`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:write_fasta`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:write_fastq`
  * `http://www.rubydoc.info/gems/biopieces/0.3.8/BioPieces/Commands:write_table`

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
contains three whitespace separated columns:

  * Command name
  * Option
  * Option value

Lines starting with '#' are considered comments and are ignored.

An example:

    maasha@mel:~$ cat ~/.biopiecesrc
    uchime_ref	database	/home/maasha/Install/QIIME1.8/data/rdp_gold.fa
    uchime_ref	cpus		20

Contributing
------------

Fork it
Create your feature branch (git checkout -b my-new-feature)
Commit your changes (git commit -am 'Add some feature')
Push to the branch (git push origin my-new-feature)
Create new Pull Request
