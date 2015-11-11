BioDSL
=========

Installation
------------

`gem install BioDSL`

Getting started
---------------

A test script:

    #!/usr/bin/env ruby
    
    require 'BioDSL'
    
    p = BD.new.
    read_fasta(input: "input.fna").
    grab(select: "ATC$", keys: :SEQ).
    write_fasta(output: "output.fna").
    run(progress: true)

Or using an interactive shell using the alias ibp which you can create by
adding the following to your `~/.bashrc` file:

    alias ibp="irb -r BioDSL --noinspect"

And then start the interactive shell:

    $ ibp
    irb(main):001:0> p = BD.new
    => BD.new
    irb(main):002:0> p.read_fasta(input: "input.fna")
    => BD.new.read_fasta(input: "input.fna")
    irb(main):003:0> p.grab(select: "ATC$", keys: :SEQ)
    => BD.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ)
    irb(main):004:0> p.write_fasta(output: "output.fna")
    => BD.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna")
    irb(main):005:0> p.run(progress: true)
    => BD.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)
    irb(main):006:0>


Or chaining commands directly:

    $ ibp
    irb(main):001:0> BD.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)
    => BD.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)
    irb(main):002:0>

Or run on the command line with the alias bp which you can create by adding the
following to your ~/.bashrc file:

    alias bp="ruby -r BioDSL"

Then you can run the below from the command line:

    $ bp -e 'BD.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)'

Available BioDSL
-------------------

  * [add_key]                          (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/AddKey)                          
  * [align_seq_mothur]                 (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/AlignSeqMothur)                          
  * [analyze_residue_distribution]     (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/AnalyzeResidueDistribution)
  * [assemble_pairs]                   (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/AssemblePairs)
  * [assemble_seq_idba]                (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/AssembleSeqIdba)
  * [assemble_seq_ray]                 (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/AssembleSeqRay)
  * [assemble_seq_spades]              (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/AssembleSeqSpades)
  * [classify_seq]                     (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/ClassifySeq)
  * [classify_seq_mothur]              (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/ClassifySeqMothur)
  * [clip_primer]                      (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/ClipPrimer)
  * [cluster_otus]                     (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/ClusterOtus)
  * [collapse_otus]                    (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/CollapseOtus)
  * [collect_otus]                     (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/CollectOtus)
  * [complement_seq]                   (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/ComplementSeq)
  * [count]                            (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/Count)
  * [degap_seq]                        (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/DegapSeq)
  * [dereplicate_seq]                  (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/DereplicateSeq)
  * [dump]                             (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/Dump)
  * [filter_rrna]                      (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/FilterRrna)
  * [genecall]                         (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/Genecall)
  * [grab]                             (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/Grab)
  * [index_taxonomy]                   (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/IndexTaxonomy)
  * [mean_scores]                      (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/MeanScores)
  * [merge_pair_seq]                   (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/MergePairSeq)
  * [merge_table]                      (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/MergeTable)
  * [merge_values]                     (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/MergeValues)
  * [plot_heatmap]                     (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/PlotHeatmap)
  * [plot_histogram]                   (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/PlotHistogram)
  * [plot_matches]                     (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/PlotMatches)
  * [plot_residue_distribution]        (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/PlotResidueDistribution)
  * [plot_scores]                      (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/PlotScores)
  * [random]                           (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/Random)
  * [read_fasta]                       (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/ReadFasta)
  * [read_fastq]                       (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/ReadFastq)
  * [read_table]                       (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/ReadTable)
  * [reverse_seq]                      (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/ReverseSeq)
  * [slice_align]                      (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/SliceAlign)
  * [slice_seq]                        (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/SliceSeq)
  * [sort]                             (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/Sort)
  * [split_pair_seq]                   (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/SplitPairSeq)
  * [split_values]                     (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/SplitValues)
  * [trim_primer]                      (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/TrimPrimer)
  * [trim_seq]                         (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/TrimSeq)
  * [uchime_ref]                       (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/UchimeRef)
  * [unique_values]                    (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/UniqueValues)
  * [usearch_global]                   (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/UsearchGlobal)
  * [write_fasta]                      (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/WriteFasta)
  * [write_fastq]                      (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/WriteFastq)
  * [write_table]                      (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/WriteTable)
  * [write_tree]                       (http://www.rubydoc.info/gems/BioDSL/1.0.1/BioDSL/WriteTree)

Log and History
---------------

All BioDSL events are logged to `~/.BioDSL_log`.

BioDSL history is saved to `~/.BioDSL_history`.


Features
--------

Progress:

Show nifty progress table with commands, records read and emittet and time.

`BD.new.read_fasta(input: "input.fna").dump.run(progress: true)`

Verbose:

Output verbose messages from commands and the run status.

`BD.new.read_fasta(input: "input.fna").dump.run(verbose: true)`

Debug:

Output debug messages from commands using these.

`BD.new.read_fasta(input: "input.fna").dump.run(debug: true)`

E-mail notification:

Send an email when run is complete.

`BD.new.read_fasta(input: "input.fna").dump.run(email: mail@maasha.dk, subject: "Script done!")`

Report:

Create an HTML report of the run stats:

`BD.new.read_fasta(input: "input.fna").dump.run(report: "status.html")`

Output dir:

All output files from commands are put in a specified dir:

`BD.new.read_fasta(input: "input.fna").dump.run(output_dir: "Results")`


Configuration File
------------------

It is possible to pre-set options in a configuration file located in your $HOME
directory called `.BioDSLrc`. Thus if an option is not already set, its value
will fall back to the one set in the configuration file. The configuration file
contains three whitespace separated columns:

  * Command name
  * Option
  * Option value

Lines starting with '#' are considered comments and are ignored.

An example:

    maasha@mel:~$ cat ~/.BioDSLrc
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
