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
following to your ~/.bashrc file:

    alias bp="ruby -r biopieces"

Then you can run the below from the command line:

    $ bp -e 'BP.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)'

Available Biopieces
-------------------

  * [add_key]                          (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:add_key)                          
  * [align_seq_mothur]                 (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:align_seq_mothur)                          
  * [analyze_residue_distribution]     (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:analyze_residue_distribution)
  * [assemble_pairs]                   (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:assemble_pairs)
  * [assemble_seq_idba]                (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:assemble_seq_idba)
  * [assemble_seq_spades]              (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:assemble_seq_spades)
  * [classify_seq]                     (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:classify_seq)
  * [classify_seq_mothur]              (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:classify_seq_mothur)
  * [clip_primer]                      (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:clip_primer)
  * [cluster_otus]                     (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:cluster_otus)
  * [collapse_otus]                    (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:collapse_otus)
  * [collect_otus]                     (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:collect_otus)
  * [complement_seq]                   (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:complement_seq)
  * [count]                            (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:count)
  * [degap_seq]                        (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:degap_seq)
  * [dereplicate_seq]                  (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:dereplicate_seq)
  * [dump]                             (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:dump)
  * [filter_rrna]                      (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:filter_rrna)
  * [grab]                             (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:grab)
  * [index_taxonomy]                   (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:index_taxonomy)
  * [mean_scores]                      (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:mean_scores)
  * [merge_pair_seq]                   (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:merge_pair_seq)
  * [merge_table]                      (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:merge_table)
  * [merge_values]                     (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:merge_values)
  * [plot_heatmap]                     (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:plot_heatmap)
  * [plot_histogram]                   (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:plot_histogram)
  * [plot_matches]                     (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:plot_matches)
  * [plot_residue_distribution]        (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:plot_residue_distribution)
  * [plot_scores]                      (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:plot_scores)
  * [random]                           (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:random)
  * [read_fasta]                       (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:read_fasta)
  * [read_fastq]                       (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:read_fastq)
  * [read_table]                       (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:read_table)
  * [reverse_seq]                      (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:reverse_seq)
  * [slice_align]                      (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:slice_align)
  * [slice_seq]                        (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:slice_seq)
  * [sort]                             (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:sort)
  * [split_pair_seq]                   (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:split_pair_seq)
  * [split_values]                     (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:split_values)
  * [trim_primer]                      (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:trim_primer)
  * [trim_seq]                         (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:trim_seq)
  * [uchime_ref]                       (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:uchime_ref)
  * [unique_values]                    (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:unique_values)
  * [usearch_global]                   (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:usearch_global)
  * [write_fasta]                      (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:write_fasta)
  * [write_fastq]                      (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:write_fastq)
  * [write_table]                      (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:write_table)
  * [write_tree]                       (http://www.rubydoc.info/gems/biopieces/0.5.0/BioPieces/Commands:write_tree)

Log and History
---------------

All BioPieces events are logged to `~/.biopieces_log`.

BioPieces history is saved to `~/.biopieces_history`.


Features
--------

Progress:

Show nifty progress table with commands, records read and emittet and time.

`BP.new.read_fasta(input: "input.fna").dump.run(progress: true)`

Verbose:

Output verbose messages from commands and the run status.

`BP.new.read_fasta(input: "input.fna").dump.run(verbose: true)`

Debug:

Output debug messages from commands using these.

`BP.new.read_fasta(input: "input.fna").dump.run(debug: true)`

E-mail notification:

Send an email when run is complete.

`BP.new.read_fasta(input: "input.fna").dump.run(email: mail@maasha.dk, subject: "Script done!")`

Report:

Create an HTML report of the run stats:

`BP.new.read_fasta(input: "input.fna").dump.run(report: "status.html")`

Output dir:

All output files from commands are put in a specified dir:

`BP.new.read_fasta(input: "input.fna").dump.run(output_dir: "Results")`


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
    uchime_ref   database   /home/maasha/Install/QIIME1.8/data/rdp_gold.fa
    uchime_ref   cpus       20

On compute clusters it is necessary to specify the max processor count, which
is otherwise determined as the number of cores on the current node. To override
this add the following line to the `.biopiecesrc` file:

    pipeline   processor_count   1000

Contributing
------------

Fork it

Create your feature branch (git checkout -b my-new-feature)

Commit your changes (git commit -am 'Add some feature')

Push to the branch (git push origin my-new-feature)

Create new Pull Request
