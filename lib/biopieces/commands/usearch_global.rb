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
  # == Run usearch_global on sequences in the stream.
  #
  # This is a wrapper for the +usearch+ tool to run the program usearch_global.
  # Basically sequence type records are searched against a reference database
  # and records with hit information are output.
  #
  # Please refer to the manual:
  #
  # http://drive5.com/usearch/manual/usearch_global.html
  #
  # Usearch 7.0 must be installed for +usearch+ to work. Read more here:
  #
  # http://www.drive5.com/usearch/
  #
  # == Usage
  #
  #    usearch_global(<database: <file>, <identity: float>,
  #                   <strand: "plus|both">[, cpus: <uint>])
  #
  # === Options
  #
  # * database: <file>   - Database to search (in FASTA format).
  # * identity: <float>  - Similarity for matching in percent between 0.0 and
  #                        1.0.
  # * strand:   <string> - For nucleotide search report hits from plus or both
  #                        strands.
  # * cpus:     <uint>   - Number of CPU cores to use (default=1).
  #
  # == Examples
  #
  class UsearchGlobal
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/aux_helper'

    extend AuxHelper
    extend OptionsHelper
    include OptionsHelper

    # Check options and return command lambda for usearch_global.
    #
    # @param  options [Hash] Options hash.
    # @option options [String]        :database
    # @option options [Float]         :identity
    # @option options [String,Symbol] :strand
    # @option options [Integer]       :cpus
    #
    # @return [Proc] Command lambda.
    def self.lmb(options)
      options_allowed(options, :database, :identity, :strand, :cpus)
      options_required(options, :database, :identity)
      options_allowed_values(options, strand: ['plus', 'both', :plus, :both])
      options_files_exist(options, :database)
      options_assert(options, ':identity >  0.0')
      options_assert(options, ':identity <= 1.0')
      options_assert(options, ':cpus >= 1')
      options_assert(options, ":cpus <= #{BioPieces::Config::CORES_MAX}")
      aux_exist('usearch')

      new(options).lmb
    end

    # Constructor for UsearchGlobal.
    #
    # @param  options [Hash] Options hash.
    # @option options [String]        :database
    # @option options [Float]         :identity
    # @option options [String,Symbol] :strand
    # @option options [Integer]       :cpus
    #
    # @return [UsearchGlobal] Class instance.
    def initialize(options)
      @options        = options
      @options[:cpus] ||= 1
      @records_in     = 0
      @records_out    = 0
      @sequences_in   = 0
      @hits_out       = 0
    end

    # Return command lambda for usearch_global.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        TmpDir.create('in', 'out') do |tmp_in, tmp_out|
          process_input(input, output, tmp_in)
          run_usearch_global(tmp_in, tmp_out)
          process_output(output, tmp_out)
        end

        assign_status(status)
      end
    end

    private

    # Process input and emit to the output stream while saving all records
    # containing sequences to a temporary FASTA file.
    #
    # @param input [Enumerator] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    # @param tmp_in [String] Path to temporary file.
    def process_input(input, output, tmp_in)
      BioPieces::Fasta.open(tmp_in, 'w') do |ios|
        input.each_with_index do |record, i|
          @records_in += 1

          output << record

          @records_out += 1

          next unless record[:SEQ]

          @sequences_in += 1
          seq_name = record[:SEQ_NAME] || i.to_s

          entry = BioPieces::Seq.new(seq_name: seq_name, seq: record[:SEQ])

          ios.puts entry.to_fasta
        end
      end
    end

    # Run usearch global on the input file and save results in the output file.
    def run_usearch_global(tmp_in, tmp_out)
      run_opts = {
        input: tmp_in,
        output: tmp_out,
        database: @options[:database],
        strand: @options[:strand],
        identity: @options[:identity],
        cpus: @options[:cpus],
        verbose: @options[:verbose]
      }

      BioPieces::Usearch.usearch_global(run_opts)
    rescue BioPieces::UsearchError => e
      raise unless e.message =~ /Empty input file/
    end

    # Parse usearch output file and emit records to the output stream.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param tmp_out [String] Path to output file.
    def process_output(output, tmp_out)
      BioPieces::Usearch.open(tmp_out) do |ios|
        ios.each(:uc) do |record|
          record[:RECORD_TYPE] = 'usearch'
          output << record
          @hits_out    += 1
          @records_out += 1
        end
      end
    end

    # Assign values to status hash.
    #
    # @param status [Hash] Status hash.
    def assign_status(status)
      status[:records_in]   = @records_in
      status[:records_out]  = @records_out
      status[:sequences_in] = @sequences_in
      status[:hits_out]     = @hits_out
    end
  end
end
