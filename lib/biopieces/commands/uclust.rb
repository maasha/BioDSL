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
  # == Run uclust on sequences in the stream.
  #
  # This is a wrapper for the +usearch+ tool to run the program uclust.
  # Basically sequence type records are clustered de-novo and records containing
  # sequence and cluster information is output. If the +align+ option is given
  # the sequnces will be aligned.
  #
  # Please refer to the manual:
  #
  # http://www.drive5.com/usearch/manual/cmd_cluster_smallmem.html
  #
  # Usearch 7.0 must be installed for +usearch+ to work. Read more here:
  #
  # http://www.drive5.com/usearch/
  #
  # == Usage
  #
  #    uclust(<identity: float>, <strand: "plus|both">[, align: <bool>
  #           [, cpus: <uint>]])
  #
  # === Options
  #
  # * identity: <float>  - Similarity for matching in percent between 0.0 and
  #                        1.0.
  # * strand:   <string> - For nucleotide search report hits from plus or both
  #                        strands.
  # * align:    <bool>   - Align sequences.
  # * cpus:     <uint>   - Number of CPU cores to use (default=1).
  #
  # == Examples
  #
  # rubocop: disable ClassLength
  class Uclust
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/aux_helper'
    require 'biopieces/helpers/status_helper'

    extend AuxHelper
    extend OptionsHelper
    include OptionsHelper
    include StatusHelper

    # Check options and return command lambda for uclust.
    #
    # @param options [Hash] Options hash.
    # @option options [Float] :identity
    # @option options [String,Symbol] :strand
    # @option options [Boolean] :align
    # @option options [Integer] :cpus
    #
    # @return [Proc] Command lambda.
    def self.lmb(options)
      options_allowed(options, :identity, :strand, :align, :cpus)
      options_required(options, :identity, :strand)
      options_allowed_values(options, strand: ['plus', 'both', :plus, :both])
      options_allowed_values(options, align:  [nil, false, true])
      options_assert(options, ':identity >  0.0')
      options_assert(options, ':identity <= 1.0')
      options_assert(options, ':cpus >= 1')
      options_assert(options, ":cpus <= #{BioPieces::Config::CORES_MAX}")
      aux_exist('usearch')

      new(options).lmb
    end

    # Constructor for Uclust.
    #
    # @param options [Hash] Options hash.
    # @option options [Float] :identity
    # @option options [String,Symbol] :strand
    # @option options [Boolean] :align
    # @option options [Integer] :cpus
    #
    # @return [Uclust] Class instance.
    def initialize(options)
      @options = options
      @options[:cpus] ||= 1

      status_init(:records_in, :records_out, :sequences_in, :sequences_out,
                  :residues_in, :residues_out, :clusters_out)
    end

    # Return command lambda for uclust.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        TmpDir.create('rec', 'in', 'out') do |tmp_rec, tmp_in, tmp_out|
          process_input(input, output, tmp_rec, tmp_in)

          run_uclust(tmp_in, tmp_out)

          if @options[:align]
            process_output_align(output, tmp_out)
          else
            process_output(output, tmp_rec, tmp_out)
          end
        end

        status_assign(status, :records_in, :records_out, :sequences_in,
                              :sequences_out, :residues_in, :residues_out,
                              :clusters_out)
      end
    end

    private

    # Process input data and serialize all records into a temporary file and all
    # records containing sequence to a temporary FASTA file.
    #
    # @param input [Enumerator] Input stream
    # @param output [Enumerator::Yeilder] Output stream.
    # @param tmp_rec [String] Path to serialized records file.
    # @param tmp_in  [String] Path to input file.
    def process_input(input, output, tmp_rec, tmp_in)
      File.open(tmp_rec, 'wb') do |ios_rec|
        BioPieces::Serializer.new(ios_rec) do |s|
          BioPieces::Fasta.open(tmp_in, 'w') do |ios|
            process_input_records(input, output, ios, s)
          end
        end
      end
    end

    # Iterate over records in the input stream and serialize all records. Also,
    # records with sequence are saved in a FASTA file or emitted to the output
    # stream if the record contains no sequence.
    #
    # @param input [Enumerator] Input stream
    # @param output [Enumerator::Yeilder] Output stream.
    # @param ios [Fasta::IO] Output stream to a FASTA file
    # @param serializer [BioPieces::Serializer] Serializer IO.
    def process_input_records(input, output, ios, serializer)
      input.each_with_index do |record, i|
        @records_in += 1

        if record[:SEQ]
          output_entry(ios, record, i)
        else
          @records_out += 1
          output << record
        end

        serializer << record
      end
    end

    # Save a BioPieces record to a FASTA file.
    #
    # @param ios [Fasta::IO] Output stream to a FASTA file
    # @param record [Hash] BioPieces record.
    # @param i [Integer] Record index.
    def output_entry(ios, record, i)
      @sequences_in += 1

      record[:SEQ_NAME] ||= i.to_s

      entry = BioPieces::Seq.new(seq_name: record[:SEQ_NAME], seq: record[:SEQ])

      ios.puts entry.to_fasta
    end

    # Run the uclust command.
    #
    # @param tmp_in  [String] Path to input file.
    # @param tmp_out [String] Path to output file.
    #
    # @raise [BioPieces::UsearchError] if command fails.
    def run_uclust(tmp_in, tmp_out)
      uclust_opts = {
        input:    tmp_in,
        output:   tmp_out,
        strand:   @options[:strand],
        identity: @options[:identity],
        align:    @options[:align],
        cpus:     @options[:cpus],
        verbose:  @options[:verbose]
      }

      BioPieces::Usearch.cluster_smallmem(uclust_opts)
    rescue BioPieces::UsearchError => e
      raise unless e.message =~ /Empty input file/
    end

    # Parse uclust output file and return a hash with Q_ID as key and the uclust
    # record as value.
    #
    # @param tmp_out [String] Path to output file.
    #
    # @return [Hash] Q_ID as keys and Uclust records.
    def parse_output(tmp_out)
      results = {}

      BioPieces::Usearch.open(tmp_out) do |ios|
        ios.each(:uc) do |record|
          record[:RECORD_TYPE] = 'uclust'

          results[record[:Q_ID]] = record
        end
      end

      results
    end

    # Parse MSA alignment data from uclust output file and emit to the output
    # stream.
    #
    # @param output [Enumerator::Yeilder] Output stream.
    # @param tmp_out [String] Path to uclust output file.
    def process_output_align(output, tmp_out)
      BioPieces::Fasta.open(tmp_out) do |ios|
        ios.each do |entry|
          if entry.seq_name == 'consensus'
            @clusters_out += 1
          else
            record = {RECORD_TYPE: 'uclust', CLUSTER: @clusters_out}
            record.merge!(entry.to_bp)

            output << record
            @records_out   += 1
            @sequences_out += 1
            @residues_out  += entry.length
          end
        end
      end
    end

    # Parse results form uclust and merge with serialized data and output to the
    # output stream.
    #
    # @param output [Enumerator::Yeilder] Output stream.
    # @param tmp_rec [String] Path to serialized records file.
    # @param tmp_out [String] Path to uclust output file.
    def process_output(output, tmp_rec, tmp_out)
      results = parse_output(tmp_out)

      File.open(tmp_rec, 'rb') do |ios_rec|
        BioPieces::Serializer.new(ios_rec) do |s|
          process_output_serial(s, results, output)
        end
      end
    end

    # Deserialize records from temporary file, merge these with cluster data and
    # emit to the output stream.
    #
    # @param serializer [BioPieces::Serializer]
    #   Serializer IO.
    #
    # @param results [Hash]
    #   Results from uclust with Q_ID as key and uclust record as value
    #
    # @param output [Enumerator::Yeilder]
    #   Output stream.
    def process_output_serial(serializer, results, output)
      serializer.each do |record|
        next unless record[:SEQ_NAME]

        if (r = results[record[:SEQ_NAME]])
          output << record.merge(r)
          @records_out   += 1
          @sequences_out += 1
          @residues_out  += record[:SEQ].length
        else
          fail BioPieces::UsearchError, 'Sequence name: ' \
            "#{record[:SEQ_NAME]} not found in uclust results"
        end
      end
    end
  end
end
