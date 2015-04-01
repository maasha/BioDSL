# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                              #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                #
#                                                                              #
# This program is free software; you can redistribute it and/or                #
# modify it under the terms of the GNU General Public License                  #
# as published by the Free Software Foundation; either version 2               #
# of the License, or (at your option) any later version.                       #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program; if not, write to the Free Software                  #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,    #
# USA.                                                                         #
#                                                                              #
# http://www.gnu.org/copyleft/gpl.html                                         #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                              #
# This software is part of the Biopieces framework (www.biopieces.org).        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  module Commands
    # == Assemble sequences the stream using IDBA_UD.
    # 
    # +assemble_seq_idba+ is a wrapper around the prokaryotic metagenome
    # assembler IDBA_UD:
    #
    # http://i.cs.hku.hk/~alse/hkubrg/projects/idba_ud/
    #
    # Any records containing sequence information will be included in the
    # assembly, but only the assembled contig sequences will be output to the
    # stream.
    #
    # The sequences records may contain quality scores, and if the sequence
    # names indicates that the sequence order is inter-leaved paired-end
    # assembly will be performed.
    #
    # == Usage
    # 
    #    assemble_seq_idba([kmer_min: <uint>[, kmer_max: <uint>[, cpus: <uint>]]])
    #
    # === Options
    #
    # * kmer_min: <uint> - Minimum k-mer value (default: 24).
    # * kmer_max: <uint> - Maximum k-mer value (default: 128).
    # * cpus: <uint>     - Number of CPUs to use (default: 1).
    # 
    # == Examples
    # 
    # If you have two pair-end sequence files with the Illumina data then you
    # can assemble these using assemble_seq_idba like this:
    #
    #    BP.new.
    #    read_fastq(input: "file1.fq", input2: "file2.fq).
    #    assemble_seq_idba.
    #    write_fasta(output: "contigs.fna").
    #    run
    def assemble_seq_idba(options = {})
      require_relative 'assemble_seq_idba/assemble_seq_idba'
      require 'parallel'

      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :kmer_min, :kmer_max, :cpus)
      options_assert(options, ":kmer_min >= 16")
      options_assert(options, ":kmer_min <= 256")
      options_assert(options, ":kmer_max >= 16")
      options_assert(options, ":kmer_max <= 512")
      options_assert(options, ":cpus >= 1")
      options_assert(options, ":cpus <= #{Parallel.processor_count}")
      aux_exist("idba_ud")

      options[:kmer_min] ||= 24
      options[:kmer_max] ||= 48
      options[:cpus]     ||= 1

      lmb = AssembleSeqIdba.run(options)

      @commands << BioPieces::Pipeline::Command.new(__method__, options,
                                                    options_orig, lmb)

      self
    end
  end
end
