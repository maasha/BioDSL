BioDSL (pronounced Biodiesel) is a Domain Specific Language for creating
bioinformatic analysis workflows. A workflow may consist of several pipelines
and each pipeline consists of a series of steps such as reading in data from a
file, processing the data in some way, and writing data to a new file.

BioDSL is build on the same principles as [Biopieces](www.biopieces.org), where
data records are passed through multiple commands each with a specific task. The
idea is that a command will process the data record if this contains the
relevant attributes that the command can process. E.g. if a data record contains
a sequence, then the command [reverse_seq](reverse_seq) will reverse that
sequence.

# Installation

The recommended way of installing BioDSL is via Ruby’s gem package manager:

`$ gem install BioDSL`

For those commands which are wrappers around third-party tools, such as Usearch,
Mothur and SPAdes, you will have to install these and make the executables
available in your `$PATH`.

# Getting started

BioDSL is implemented in Ruby making use of Ruby’s powerful metaprogramming
facilities. Thus, a workflow is basically a Ruby script containing one or more
pipelines.

Here is a test script with a single pipeline that reads all FASTA entries from
the file `input.fna`, selects all records with a sequence ending in `ATC`, and
writing those records as FASTA entries to the file `output.fna`:

```
#!/usr/bin/env ruby

require 'BioDSL'

BD.new.
read_fasta(input: "input.fna").
grab(select: "ATC$", keys: :SEQ).
write_fasta(output: "output.fna").
run
```

Save the test script to a file `test.biodsl` and execute on the command line:

```
$ ruby test.biodsl
```

# Combining multiple pipelines

This script demonstrates how multiple pipelines can be created and combined. In
the end two pipelines are run, one consisting of p1 + p2 and one consisting of
p1 + p3. The first pipeline run will produce a histogram plot of sequence length
from sequences containing the pattern `ATCG`, and the other pipeline run will
produce a plot with sequences length distribution of sequences not matching
`ATCG`.

```
#!/usr/bin/env ruby

require 'BioDSL'

p1 = BD.new.read_fasta(input: "test.fna")
p2 = BD.new.grab(keys: :SEQ, select: "ATCG").
     plot_histogram(key: :SEQ_LEN, terminal: :png, output: "select.png")
p3 = BD.new.grab(keys: :SEQ, reject: "ATCG").
     plot_histogram(key: :SEQ_LEN, terminal: :png, output: "reject.png")
p4 = p1 + p3

(p1 + p2).write_fasta(output: "select.fna").run
p4.write_fasta(output: "reject.fna").run
```

# Running pipelines in parallel

This script demonstrates how to run multiple pipelines in parallel using 20 CPU
cores. Here we filter pair-end FASTQ entries from a list of samples described in
the file `samples.txt` which contains three tab separated columns: sample name,
a forward read file path, and a reverse read file path.

```
#!/usr/bin/env ruby

require 'BioDSL'
require 'csv'

samples = CSV.read("samples.txt")

Parallel.each(samples, in_processes: 20) do |sample|
  BD.new.
  read_fastq(input: sample[1], input2: sample[2], encoding: :base_33).
  grab(keys: :SEQ, select: "ATCG").
  write_fastq(output: "#{sample[0]}_filted.fastq.bz2", bzip2: true).
  run
end
```

# Ruby one-liners

It is possible to execute BioDSL pipelines on the command line:

```
ruby -r BioDSL -e 'BD.new.read_fasta(input: "test.fna").plot_histogram(key: :SEQ_LEN).run'
```

And to save typing we may use the alias `bd` which is set like this on the
command line:

```
$ alias bd='ruby -r BioDSL'
```

It may be a good idea to save that alias in your `.bashrc` file.

Now it is possible to run a BioDSL pipeline on the command line like this:

```
$ bd -e 'BD.new.read_fasta(input: "test.fna").plot_histogram(key: :SEQ_LEN).run'
```

# Using the Interactive Ruby interpreter

Here we demonstrate the use of Ruby's `irb` shell:

```
$ irb -r BioDSL --noinspect
irb(main):001:0> p = BD.new
=> BD.new
irb(main):002:0> p.read_fasta(input: "input.fna")
=> BD.new.read_fasta(input: "input.fna")
irb(main):003:0> p.grab(select: "ATC$", keys: :SEQ)
=> BD.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ)
irb(main):004:0> p.write_fasta(output: "output.fna")
=> BD.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna")
irb(main):005:0> p.run
=> BD.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run
irb(main):006:0>
```

Again, it may be a good idea to save an alias `alias biodsl="irb -r BioDSL --noinspect"` to your `.bashrc` file. Thus, we can use the new `biodsl` alias to chain commands directly:

```
$ biodsl
irb(main):001:0> BD.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)
=> BD.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)
irb(main):002:0>
```

# History file

A history file is kept in `$USER/.BioDSL_history` and each time run is called a history entry is added to this file:

```
BD.new.read_fasta(input: "test_big.fna", first: 100).plot_histogram(key: :SEQ_LEN).run
BD.new.read_fasta(input: "test_big.fna", first: 100).plot_histogram(key: :SEQ_LEN).run
BD.new.read_fasta(input: "test_big.fna", first: 10).plot_histogram(key: :SEQ_LEN).run
BD.new.read_fasta(input: "test_big.fna").plot_histogram(key: :SEQ_LEN).run
BD.new.read_fasta(input: "test_big.fna", first: 1000).plot_histogram(key: :SEQ_LEN).run
```

Thus it is possible to redo the last pipeline by pasting the line in irb or a Ruby one-liner.

# Log and History

All BioDSL events are logged to `~/.BioDSL_log`.

BioDSL history is saved to `~/.BioDSL_history`.

# Features

## Progress

Show nifty progress table with commands, records read and emittet and time.

`BD.new.read_fasta(input: "input.fna").dump.run(progress: true)`

## Verbose

Output verbose messages from commands and the run status.

```
BD.new.read_fasta(input: "input.fna").dump.run(verbose: true)
```

## Debug

Output debug messages from commands using these.

```
BD.new.read_fasta(input: "input.fna").dump.run(debug: true)
```

## E-mail notification

Send an email when run is complete.

```
BD.new.read_fasta(input: "input.fna").dump.run(email: bill@hotmail.com, subject: "Script done!")
```

## Reports

Create an HTML report of the run stats for a pipeline:

```
BD.new.read_fasta(input: "input.fna").dump.run(report: "status.html")
```

## Output directory

All output files from commands are put in a specified directory:

```
BD.new.read_fasta(input: "input.fna").dump.run(output_dir: "Results")
```

## Configuration File

It is possible to pre-set options in a configuration file located in your `$HOME`
directory called `.BioDSLrc`. Thus if an option is not already set, its value
will fall back to the one set in the configuration file. The configuration file
contains three whitespace separated columns:

  * Command name
  * Option
  * Option value

Lines starting with `#` are considered comments and are ignored.

An example:

```
maasha@mel:~$ cat ~/.BioDSLrc
uchime_ref   database   /home/maasha/Install/QIIME1.8/data/rdp_gold.fa
uchime_ref   cpus       20
```

On compute clusters it is necessary to specify the max processor count, which
is otherwise determined as the number of cores on the current node. To override
this add the following line:

```
pipeline   processor_count   1000
```

It is also possible to change the temporary directory from the systems default
by adding the following line:

```
pipeline   tmp_dir   /home/projects/ku_microbio/scratch/tmp
```

# Available BioDSL commands

  * [add_key]                          (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/AddKey)
  * [align_seq_mothur]                 (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/AlignSeqMothur)
  * [analyze_residue_distribution]     (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/AnalyzeResidueDistribution)
  * [assemble_pairs]                   (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/AssemblePairs)
  * [assemble_seq_idba]                (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/AssembleSeqIdba)
  * [assemble_seq_ray]                 (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/AssembleSeqRay)
  * [assemble_seq_spades]              (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/AssembleSeqSpades)
  * [classify_seq]                     (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/ClassifySeq)
  * [classify_seq_mothur]              (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/ClassifySeqMothur)
  * [clip_primer]                      (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/ClipPrimer)
  * [cluster_otus]                     (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/ClusterOtus)
  * [collapse_otus]                    (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/CollapseOtus)
  * [collect_otus]                     (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/CollectOtus)
  * [complement_seq]                   (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/ComplementSeq)
  * [count]                            (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/Count)
  * [degap_seq]                        (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/DegapSeq)
  * [dereplicate_seq]                  (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/DereplicateSeq)
  * [dump]                             (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/Dump)
  * [filter_rrna]                      (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/FilterRrna)
  * [genecall]                         (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/Genecall)
  * [grab]                             (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/Grab)
  * [index_taxonomy]                   (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/IndexTaxonomy)
  * [mean_scores]                      (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/MeanScores)
  * [merge_pair_seq]                   (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/MergePairSeq)
  * [merge_table]                      (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/MergeTable)
  * [merge_values]                     (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/MergeValues)
  * [plot_heatmap]                     (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/PlotHeatmap)
  * [plot_histogram]                   (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/PlotHistogram)
  * [plot_matches]                     (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/PlotMatches)
  * [plot_residue_distribution]        (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/PlotResidueDistribution)
  * [plot_scores]                      (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/PlotScores)
  * [random]                           (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/Random)
  * [read_fasta]                       (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/ReadFasta)
  * [read_fastq]                       (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/ReadFastq)
  * [read_table]                       (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/ReadTable)
  * [reverse_seq]                      (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/ReverseSeq)
  * [slice_align]                      (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/SliceAlign)
  * [slice_seq]                        (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/SliceSeq)
  * [sort]                             (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/Sort)
  * [split_pair_seq]                   (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/SplitPairSeq)
  * [split_values]                     (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/SplitValues)
  * [trim_primer]                      (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/TrimPrimer)
  * [trim_seq]                         (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/TrimSeq)
  * [uchime_ref]                       (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/UchimeRef)
  * [unique_values]                    (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/UniqueValues)
  * [usearch_global]                   (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/UsearchGlobal)
  * [write_fasta]                      (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/WriteFasta)
  * [write_fastq]                      (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/WriteFastq)
  * [write_table]                      (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/WriteTable)
  * [write_tree]                       (http://www.rubydoc.info/gems/BioDSL/1.0.2/BioDSL/WriteTree)

# Running the test suite

BioDSL have an extended set of unit tests that can be run after installing
development dependencies. First you need to install the bundler gem:

```
$ gem install bundler
```

Next you need to change to the source directory of BioDSL and run bundler to
download depending gems:

```
$ bundle install
```

And then you run the test suite by running `rake`:

```
$ rake
```

And the unit tests should all run, except those omitted because a third-party
executable was missing.

# Contributing

1. Fork it
1. Create your feature branch (git checkout -b my-new-feature)
1. Commit your changes (git commit -am 'Add some feature')
1. Push to the branch (git push origin my-new-feature)
1. Create new Pull Request
