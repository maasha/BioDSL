#!/usr/bin/env ruby

require 'BioDSL'

# Read in sequences in FASTQ format from the file `test.fq` and save them in
# FASTA format in the file `test.fna`.

BD.new.read_fastq(input: "test.fq").write_fasta(output: "test.fna").run
