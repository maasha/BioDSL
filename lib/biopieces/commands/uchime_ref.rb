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
  # == Run uchime_ref on sequences in the stream.
  #
  # This is a wrapper for the +usearch+ tool to run the program uchime_ref.
  # Basically sequence type records are searched against a reference database or
  # non-chimeric sequences, and chimirec sequences are filtered out so only
  # non-chimeric sequences are output.
  #
  # Please refer to the manual:
  #
  # http://drive5.com/usearch/manual/uchime_ref.html
  #
  # Usearch 7.0 must be installed for +usearch+ to work. Read more here:
  #
  # http://www.drive5.com/usearch/
  #
  # == Usage
  #
  #    uchime_ref(<database: <file>[cpus: <uint>])
  #
  # === Options
  #
  # * database: <file> - Database to search (in FASTA format).
  # * cpus:     <uint> - Number of CPU cores to use (default=1).
  #
  # == Examples
  #
  class UchimeRef
    require 'parallel'
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/aux_helper'

    extend AuxHelper
    extend OptionsHelper
    include OptionsHelper

    # Check options and return command lambda for uchime_ref.
    #
    # @param options [Hash] Options hash.
    # @option options [String] :database
    # @option options [Integer] :cpus
    #
    # @return [Proc] Command lambda.
    def self.lmb(options)
      options_load_rc(options, __method__)
      options_allowed(options, :database, :cpus)
      options_required(options, :database)
      options_files_exist(options, :database)
      options_assert(options, ':cpus >= 1')
      options_assert(options, ':cpus <= #{Parallel.processor_count}')
      aux_exist('usearch')

      new(options).lmb
    end

    # Constructor for UchimeRef.
    #
    # @param options [Hash] Options hash.
    # @option options [String] :database
    # @option options [Integer] :cpus
    #
    # @return [UchimeRef] Class instance.
    def initialize(options)
      @options = options
      @options[:cpus]   ||= 1
      @options[:strand] ||= 'plus'  # This option cant be changed in usearch7.0
      @records_in    = 0
      @records_out   = 0
      @sequences_in  = 0
      @sequences_out = 0
      @residues_in   = 0
      @residues_out  = 0
    end

    # Return command lambda for uchime_ref.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        TmpDir.create('input', 'output') do |tmp_in, tmp_out|
          process_input(input, output, tmp_in)
          run_uchime_ref(tmp_in, tmp_out)

          process_output(output, tmp_out)
        end

        assign_status(status)
      end
    end

    private

    # Process input stream and save records with sequences to a temporary FASTA
    # file or emit non-sequence containing records to the output stream.
    #
    # @param input  [Enumerator] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    # @param tmp_in [String] Path to temporary FASTA file.
    def process_input(input, output, tmp_in)
      BioPieces::Fasta.open(tmp_in, 'w') do |ios|
        input.each_with_index do |record, i|
          @records_in += 1

          if record[:SEQ]
            @sequences_in += 1
            seq_name = record[:SEQ_NAME] || i.to_s

            entry = BioPieces::Seq.new(seq_name: seq_name, seq: record[:SEQ])

            ios.puts entry.to_fasta
          else
            output << record
            @records_out += 1
          end
        end
      end
    end

    # Run uchime_ref on input file and save result input file.
    #
    # @param tmp_in [String] Path to input file.
    # @param tmp_out [String] Path to output file.
    #
    # @raise [BioPieces::UsearchError] If command fails.
    def run_uchime_ref(tmp_in, tmp_out)
      uchime_opts = {
        input: tmp_in,
        output: tmp_out,
        database: @options[:database],
        strand: @options[:strand],
        cpus: @options[:cpus],
        verbose: @options[:verbose]
      }

      BioPieces::Usearch.uchime_ref(uchime_opts)
    rescue BioPieces::UsearchError => e
      raise unless e.message =~ /Empty input file/
    end

    # Process uchime_ref output data and emit to output stream.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param tmp_out [String] Path to file with uchime_ref data.
    def process_output(output, tmp_out)
      Fasta.open(tmp_out) do |ios|
        ios.each do |entry|
          record = entry.to_bp

          output << record
          @sequences_out += 1
          @records_out   += 1
        end
      end
    end

    # Assign values to status hash.
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
