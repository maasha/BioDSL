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
  # == Filter rRNA sequences from the stream.
  #
  # Description
  #
  # +filter_rrna+ utilizes +sortmerna+ to identify and filter ribosomal RNA
  # sequences from the stream. The +sortmerna+ and +indexdb_rna+ executables
  # must be installed for +filter_rrna+ to work.
  #
  # Indexed reference files are produced using +indexdb_rna+.
  #
  # For more about the sortmerna look here:
  #
  # http://bioinfo.lifl.fr/RNA/sortmerna/
  #
  # == Usage
  #    filter_rrna(ref_fasta: <file(s)>, ref_index: <file(s)>)
  #
  # === Options
  # * ref_fasta <file(s)> - One or more reference FASTA files.
  # * ref_index <file(s)> - One or more index reference files.
  #
  # == Examples
  #
  # To filter all reads matching the SILVA archaea 23S rRNA do:
  #
  #    BP.new.
  #    read_fastq(input: "reads.fq").
  #    filter_rrna(ref_fasta: ["silva-arc-23s-id98.fasta"],
  #                ref_index: ["silva-arc-23s-id98.fasta.idx*"]).
  #    write_fastq(output: "clean.fq").
  #    run
  #
  # rubocop:disable ClassLength
  class FilterRrna
    require 'English'
    require 'set'
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/status_helper'
    require 'biopieces/helpers/aux_helper'

    extend AuxHelper
    extend OptionsHelper
    include OptionsHelper
    include StatusHelper

    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Check options and return command lambda for the filter_rrna command.
    #
    # @param options [Hash] Options hash.
    # @option options [String,Array] Path(s) to reference FASTA files.
    # @option options [String,Array] Path(s) to reference index files.
    #
    # @return [Proc] Command lambda.
    def self.lmb(options)
      options_allowed(options, :ref_fasta, :ref_index)
      options_files_exist(options, :ref_fasta, :ref_index)
      aux_exist('sortmerna')

      new(options).lmb
    end

    # Constructor the FilterRrna class.
    #
    # @param options [Hash] Options hash.
    # @option options [String,Array] Path(s) to reference FASTA files.
    # @option options [String,Array] Path(s) to reference index files.
    #
    # @return [FilterRrnas] Class instance of FilterRrnas.
    def initialize(options)
      @options = options
      @filter  = Set.new

      status_init(STATS)
    end

    # Return the command lambda for filter_rrnas.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        TmpDir.create('tmp', 'seq', 'out') do |tmp_file, seq_file, out_file|
          ref_files = process_ref_files
          process_input(input, tmp_file, seq_file)
          execute_sortmerna(ref_files, seq_file, out_file)
          parse_sortme_output(out_file)
          process_output(output, tmp_file)
        end

        status_assign(status, STATS)
      end
    end

    private

    # Given reference index and fasta files in the options hash, process these
    # into a string of the format read by 'sortmerna': fasta1,id1:fasta2,id2:...
    #
    # @return [String] Reference file string for sortmerna.
    def process_ref_files
      ref_index = @options[:ref_index]
      ref_fasta = @options[:ref_fasta]

      if ref_index.is_a? Array
        ref_index.map { |f| f.sub!(/\*$/, '') }
      else
        ref_index.sub!(/\*$/, '')
      end

      ref_fasta = [ref_fasta.split(',')] if ref_fasta.is_a? String
      ref_index = [ref_index.split(',')] if ref_index.is_a? String

      ref_fasta.zip(ref_index).map { |m| m.join(',') }.join(':')
    end

    # Execute 'sortmerna'.
    #
    # @param ref_files [String] Reference file string for sortmerna.
    # @param seq_file  [String] Path to intput file with reads.
    # @param out_file  [String] Path to output file.
    #
    # @raise if execution of 'sortmerna' fails.
    def execute_sortmerna(ref_files, seq_file, out_file)
      cmd = ['sortmerna']
      cmd << "--ref #{ref_files}"
      cmd << "--reads #{seq_file}"
      cmd << "--aligned #{out_file}"
      cmd << '--fastx'
      cmd << '-v' if BioPieces.verbose

      cmd_line = cmd.join(' ')

      $stderr.puts "Running command: #{cmd_line}" if BioPieces.verbose

      system(cmd_line)

      fail "command failed: #{cmd_line}" unless $CHILD_STATUS.success?
    end

    # Parse the 'sortmerna' output file and add all sequence name indices to the
    # filter set.
    #
    # @param out_file [String] Path to output file.
    def parse_sortme_output(out_file)
      BioPieces::Fasta.open("#{out_file}.fasta", 'r') do |ios|
        ios.each do |entry|
          @filter << entry.seq_name.to_i
        end
      end
    end

    # Process input stream and serialize all records and write a temporary FASTA
    # file.
    #
    # @param input [Enumerator] Input stream.
    # @param tmp_file [String] Path to tmp file for serialized records.
    # @param seq_file [String] Path to tmp FASTA sequence file.
    def process_input(input, tmp_file, seq_file)
      BioPieces::Fasta.open(seq_file, 'w') do |seq_io|
        File.open(tmp_file, 'wb') do |tmp_ios|
          BioPieces::Serializer.new(tmp_ios) do |s|
            input.each_with_index do |record, i|
              @records_in += 1

              s << record
              # FIXME: need << method
              seq_io.puts record2entry(record, i).to_fasta if record.key? :SEQ
            end
          end
        end
      end
    end

    # Given a BioPieces record and an index create a new sequence entry object
    # that is returned using the index as sequence name.
    #
    # @param record [Hash] Biopieces record
    # @param i [Integer] Index.
    #
    # @return [BioPieces::Seq] Sequence entry.
    def record2entry(record, i)
      entry = BioPieces::Seq.new(seq_name: i, seq: record[:SEQ])
      @sequences_in += 1
      @residues_in  += entry.length
      entry
    end

    # Process the serialized data and output all records, that does not match
    # the filter, to the output stream.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param tmp_file [String] Path to tmp file with serialized records.
    def process_output(output, tmp_file)
      File.open(tmp_file, 'rb') do |ios|
        BioPieces::Serializer.new(ios) do |s|
          s.each_with_index do |record, i|
            output_record(output, record, i)
          end
        end
      end
    end

    # Output a record to the output stream unless it contains sequence
    # information that should be filtered.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param record [Hash] Biopieces record.
    # @param i [Integer] Index.
    def output_record(output, record, i)
      if record.key? :SEQ
        unless @filter.include? i
          output << record
          @records_out   += 1
          @sequences_out += 1
          @residues_out  += record[:SEQ].length
        end
      else
        output << record
        @records_out += 1
      end
    end
  end
end
