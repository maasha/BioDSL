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
  # == Write sequences from stream in FASTA format.
  #
  # Description
  #
  # +write_fasta+ writes sequence from the data stream in FASTA format.
  # However, a FASTA entry will only be written if a SEQ key and a SEQ_NAME key
  # is present. An example FASTA entry:
  #
  #     >test1
  #     TATGACGCGCATCGACAGCAGCACGAGCATGCATCGACTG
  #     TGCACTGACTACGAGCATCACTATATCATCATCATAATCT
  #     TACGACATCTAGGGACTAC
  #
  # For more about the FASTA format:
  #
  # http://en.wikipedia.org/wiki/FASTA_format
  #
  # == Usage
  #    write_fasta([wrap: <uin>[, output: <file>[, force: <bool>
  #                [, gzip: <bool> | bzip2: <bool>]]]])
  #
  # === Options
  # * output <file> - Output file.
  # * force <bool>  - Force overwrite existing output file.
  # * wrap <uint>   - Wrap sequence into lines of wrap length.
  # * gzip <bool>   - Write gzipped output file.
  # * bzip2 <bool>  - Write bzipped output file.
  #
  # == Examples
  #
  # To write FASTA entries to STDOUT.
  #
  #    write_fasta
  #
  # To write FASTA entries wrapped in lines of length of 80 to STDOUT.
  #
  #    write_fasta(wrap: 80)
  #
  # To write FASTA entries to a file 'test.fna'.
  #
  #    write_fasta(output: "test.fna")
  #
  # To overwrite output file if this exists use the force option:
  #
  #    write_fasta(output: "test.fna", force: true)
  #
  # To write gzipped FASTA entries to file 'test.fna.gz'.
  #
  #    write_fasta(output: "test.fna.gz", gzip: true)
  #
  # To write bzipped FASTA entries to file 'test.fna.bz2'.
  #
  #    write_fasta(output: "test.fna.bz2", bzip2: true)
  class WriteFasta
    require 'biopieces/helpers/options_helper'
    extend OptionsHelper
    include OptionsHelper

    # Check the options and return a lambda for the command.
    #
    # @param [Hash] options Options hash.
    # @option options [Bool] :force Flag allowing overwriting files.
    # @option options [String] :output Output file path.
    # @option options [Integer] :wrap Wrap sequences at this length (default no
    #   wrap)
    # @option options [Bool] :gzip Output will be gzip'ed.
    # @option options [Bool] :bzip2 Output will be bzip2'ed.
    #
    # @return [Proc] Returns the command lambda.
    def self.lmb(options)
      options_allowed(options, :force, :output, :wrap, :gzip, :bzip2)
      options_unique(options, :gzip, :bzip2)
      options_tie(options, gzip: :output, bzip2: :output)
      options_files_exist_force(options, :output)

      new(options).lmb
    end

    # Constructor for the WriteFasta class.
    #
    # @param [Hash] options Options hash.
    # @option options [Bool] :force Flag allowing overwriting files.
    # @option options [String] :output Output file path.
    # @option options [Integer] :wrap Wrap sequences at this length (default no
    #   wrap)
    # @option options [Bool] :gzip Output will be gzip'ed.
    # @option options [Bool] :bzip2 Output will be bzip2'ed.
    #
    # @return [WriteFasta] Returns an instance of the class.
    def initialize(options)
      @options       = options
      @records_in    = 0
      @records_out   = 0
      @sequences_in  = 0
      @sequences_out = 0
      @residues_in   = 0
      @residues_out  = 0

      @options[:output] ||= $stdout
    end

    # Return a lambda for the write_fasta command.
    #
    # @return [Proc] Returns the write_fasta command lambda.
    def lmb
      lambda do |input, output, status|
        if @options[:output] == $stdout
          write_stdout(input, output)
        else
          write_file(input, output)
        end

        assign_status(status)
      end
    end

    private

    # Write all sequence entries to stdout.
    #
    # @param input  [Enumerator]          The input stream.
    # @param output [Enumerator::Yielder] The output stream.
    def write_stdout(input, output)
      wrap = @options[:wrap]

      input.each do |record|
        @records_in += 1

        if (entry = record2entry(record))
          $stdout.puts entry.to_fasta(wrap)
          @sequences_out += 1
          @residues_out  += entry.length
        end

        write_output(output, record)
      end
    end

    # Write all sequence entries to a specified file.
    #
    # @param input  [Enumerator]          The input stream.
    # @param output [Enumerator::Yielder] The output stream.
    def write_file(input, output)
      Fasta.open(@options[:output], 'w', compress: compress) do |ios|
        input.each do |record|
          @records_in += 1

          if (entry = record2entry(record))
            ios.puts entry.to_fasta(@options[:wrap])
            @sequences_out += 1
            @residues_out  += entry.length
          end

          write_output(output, record)
        end
      end
    end

    # Write a given record to the output stream if this exist.
    #
    # @param output [Enumerator::Yielder, nil] Output stream.
    # @param record [Hash] Biopices record to write.
    def write_output(output, record)
      return unless output

      output << record
      @records_out += 1
    end

    # Creates a Seq object from a given record if SEQ_NAME and SEQ is present.
    #
    # @param record [Hash] Biopices record to convert.
    #
    # @return [BioPieces::Seq] Sequence entry.
    def record2entry(record)
      return unless record.key? :SEQ_NAME
      return unless record.key? :SEQ

      BioPieces::Seq.new_bp(record)
    end

    # Determine what compression should be used for output.
    #
    # @return [Symbol, nil] Compression flag or nil if no compression.
    def compress
      return :gzip  if @options[:gzip]
      return :bzip2 if @options[:bzip2]
    end

    # Assign all stats to the status hash.
    #
    # @param status [Hash] Status hash.
    def assign_status(status)
      status[:records_in]    = @records_in
      status[:records_out]   = @records_out
      status[:sequences_in]  = @sequences_in
      status[:sequences_out] = @sequences_out
      status[:residues_in]   = @residues_in
      status[:residues_out]  = @residues_out
    end
  end
end
