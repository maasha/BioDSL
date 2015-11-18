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
# This software is part of the BioDSL (www.BioDSL.org).                        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioDSL
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
    require 'BioDSL/helpers/aux_helper'

    include AuxHelper

    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Constructor for UchimeRef.
    #
    # @param options [Hash] Options hash.
    # @option options [String] :database
    # @option options [Integer] :cpus
    #
    # @return [UchimeRef] Class instance.
    def initialize(options)
      @options = options
      aux_exist('usearch')
      check_options
      @options[:cpus]   ||= 1
      @options[:strand] ||= 'plus'  # This option cant be changed in usearch7.0
    end

    # Return command lambda for uchime_ref.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        TmpDir.create('input', 'output') do |tmp_in, tmp_out|
          process_input(input, output, tmp_in)
          run_uchime_ref(tmp_in, tmp_out)

          process_output(output, tmp_out)
        end
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :database, :cpus)
      options_required(@options, :database)
      options_files_exist(@options, :database)
      options_assert(@options, ':cpus >= 1')
      options_assert(@options, ":cpus <= #{BioDSL::Config::CORES_MAX}")
    end

    # Process input stream and save records with sequences to a temporary FASTA
    # file or emit non-sequence containing records to the output stream.
    #
    # @param input  [Enumerator] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    # @param tmp_in [String] Path to temporary FASTA file.
    def process_input(input, output, tmp_in)
      BioDSL::Fasta.open(tmp_in, 'w') do |ios|
        input.each_with_index do |record, i|
          @status[:records_in] += 1

          if record[:SEQ]
            @status[:sequences_in] += 1
            @status[:residues_in]  += record[:SEQ].length
            seq_name = record[:SEQ_NAME] || i.to_s

            entry = BioDSL::Seq.new(seq_name: seq_name, seq: record[:SEQ])

            ios.puts entry.to_fasta
          else
            output << record
            @status[:records_out] += 1
          end
        end
      end
    end

    # Run uchime_ref on input file and save result input file.
    #
    # @param tmp_in [String] Path to input file.
    # @param tmp_out [String] Path to output file.
    #
    # @raise [BioDSL::UsearchError] If command fails.
    def run_uchime_ref(tmp_in, tmp_out)
      uchime_opts = {
        input: tmp_in,
        output: tmp_out,
        database: @options[:database],
        strand: @options[:strand],
        cpus: @options[:cpus],
        verbose: @options[:verbose]
      }

      BioDSL::Usearch.uchime_ref(uchime_opts)
    rescue BioDSL::UsearchError => e
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
          @status[:sequences_out] += 1
          @status[:residues_out]  += entry.length
          @status[:records_out]   += 1
        end
      end
    end
  end
end
