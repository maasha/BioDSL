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

  * [add_key]                          (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/AddKey)                          
  * [align_seq_mothur]                 (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/AlignSeqMothur)                          
  * [analyze_residue_distribution]     (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/AnalyzeResidueDistribution)
  * [assemble_pairs]                   (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/AssemblePairs)
  * [assemble_seq_idba]                (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/AssembleSeqIdba)
  * [assemble_seq_ray]                 (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/AssembleSeqRay)
  * [assemble_seq_spades]              (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/AssembleSeqSpades)
  * [classify_seq]                     (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/ClassifySeq)
  * [classify_seq_mothur]              (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/ClassifySeqMothur)
  * [clip_primer]                      (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/ClipPrimer)
  * [cluster_otus]                     (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/ClusterOtus)
  * [collapse_otus]                    (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/CollapseOtus)
  * [collect_otus]                     (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/CollectOtus)
  * [complement_seq]                   (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/ComplementSeq)
  * [count]                            (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/Count)
  * [degap_seq]                        (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/DegapSeq)
  * [dereplicate_seq]                  (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/DereplicateSeq)
  * [dump]                             (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/Dump)
  * [filter_rrna]                      (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/FilterRrna)
  * [grab]                             (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/Grab)
  * [index_taxonomy]                   (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/IndexTaxonomy)
  * [mean_scores]                      (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/MeanScores)
  * [merge_pair_seq]                   (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/MergePairSeq)
  * [merge_table]                      (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/MergeTable)
  * [merge_values]                     (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/MergeValues)
  * [plot_heatmap]                     (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/PlotHeatmap)
  * [plot_histogram]                   (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/PlotHistogram)
  * [plot_matches]                     (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/PlotMatches)
  * [plot_residue_distribution]        (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/PlotResidueDistribution)
  * [plot_scores]                      (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/PlotScores)
  * [random]                           (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/Random)
  * [read_fasta]                       (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/ReadFasta)
  * [read_fastq]                       (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/ReadFastq)
  * [read_table]                       (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/ReadTable)
  * [reverse_seq]                      (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/ReverseSeq)
  * [slice_align]                      (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/SliceAlign)
  * [slice_seq]                        (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/SliceSeq)
  * [sort]                             (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/Sort)
  * [split_pair_seq]                   (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/SplitPairSeq)
  * [split_values]                     (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/SplitValues)
  * [trim_primer]                      (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/TrimPrimer)
  * [trim_seq]                         (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/TrimSeq)
  * [uchime_ref]                       (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/UchimeRef)
  * [unique_values]                    (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/UniqueValues)
  * [usearch_global]                   (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/UsearchGlobal)
  * [write_fasta]                      (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/WriteFasta)
  * [write_fastq]                      (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/WriteFastq)
  * [write_table]                      (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/WriteTable)
  * [write_tree]                       (http://www.rubydoc.info/gems/biopieces/0.5.2/BioPieces/WriteTree)

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
this add the following line:

    pipeline   processor_count   1000

It is also possible to change the temporary directory from the systems default
by adding the following line:

    pipeline   tmp_dir   /home/projects/ku_microbio/scratch/tmp

Contributing
------------

Fork it

Create your feature branch (git checkout -b my-new-feature)

Commit your changes (git commit -am 'Add some feature')

Push to the branch (git push origin my-new-feature)

Create new Pull Request
