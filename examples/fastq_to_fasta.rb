#!/usr/bin/env ruby

require 'biopieces'

# Read in sequences in FASTQ format from the file `test.fq` and save them in
# FASTA format in the file `test.fna`.

BP.new.read_fastq(input: "test.fq").write_fasta(output: "test.fna").run
