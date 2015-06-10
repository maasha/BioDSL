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
  # == Create OTUs from sequences in the stream.
  #
  # Use the +usearch+ program cluster_otus to cluster sequences in the stream
  # and output a representative sequence from each cluster. Sequences must
  # be dereplicated and sorted according to +SEQ_COUNT+ in decreasing order.
  #
  # Please refer to the manual:
  #
  # http://drive5.com/usearch/manual/cluster_otus.html
  #
  # Usearch 7.0 must be installed for +usearch+ to work. Read more here:
  #
  # http://www.drive5.com/usearch/
  #
  # == Usage
  #
  #    cluster_otus([identity: <float>])
  #
  # === Options
  #
  #  * identity: <float> - OTU cluster identity between 0.0 and 1.0
  #                        (Default 0.97).
  #
  # == Examples
  #
  # To create OTU clusters do:
  #
  #     BP.new.
  #     read_fasta(input: "in.fna").
  #     dereplicate_seq.
  #     sort(key: :SEQ_COUNT, reverse: true).
  #     cluster_otus.
  #     run
  class ClusterOtus
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/aux_helper'
    require 'biopieces/helpers/status_helper'

    extend OptionsHelper
    extend AuxHelper
    include OptionsHelper
    include StatusHelper

    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Return command lambda for cluster_otus after
    # checking options.
    #
    # @param options [Hash] Options hash.
    # @option options [Float] :identity Cluster identity.
    #
    # @return [Proc] Command lambda.
    def self.lmb(options)
      options_allowed(options, :identity)
      options_assert(options, ':identity >= 0.0')
      options_assert(options, ':identity <= 1.0')
      aux_exist('usearch')

      options[:identity] ||= 0.97

      new(options).lmb
    end

    # Constructor for ClusterOtu.
    #
    # @param options [Hash] Options hash.
    # @option options [Float] :identity Cluster identity.
    #
    # @return [ClusterOtu] Instance of ClusterOtu.
    def initialize(options)
      @options = options

      status_init(STATS)
    end

    def lmb
      lambda do |input, output, status|
        TmpDir.create('tmp.fa', 'tmp.uc') do |tmp_in, tmp_out|
          process_input(input, output, tmp_in)

          BioPieces::Usearch.cluster_otus(input: tmp_in, output: tmp_out,
                                          identity: @options[:identity],
                                          verbose: @options[:verbose])

          process_output(output, tmp_out)
        end

        status_assign(status, STATS)
      end
    end

    private

    # Process input records and save sequence data to a temporary FASTA file for
    # use with +usearch cluster_otus+.
    #
    # @param input [Enumerator] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    # @param tmp_in [String] Path to temporary FASTA file.
    def process_input(input, output, tmp_in)
      BioPieces::Fasta.open(tmp_in, 'w') do |ios|
        input.each_with_index do |record, i|
          @records_in += 1

          if record.key? :SEQ
            @sequences_in += 1
            @residues_in += record[:SEQ].length
            ios.puts record2entry(record, i).to_fasta
          else
            output << record
            @records_out += 1
          end
        end
      end
    end

    # Create a Sequence entry from a record using the record index as sequence
    # name if no such is found.
    #
    # @param record [Hash] Biopieces record.
    # @param i [Integer] Record index
    def record2entry(record, i)
      seq_name = record[:SEQ_NAME] || i.to_s

      if record.key? :SEQ_COUNT
        seq_name << ";size=#{record[:SEQ_COUNT]}"
      else
        fail BioPieces::SeqError, 'Missing SEQ_COUNT'
      end

      BioPieces::Seq.new(seq_name: seq_name, seq: record[:SEQ])
    end

    # Process the cluster output and emit otus to the output stream.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param tmp_out [String] Path to temporary OTU file.
    #
    # @raise [UsearchError] if size info is missing from SEQ_NAME.
    def process_output(output, tmp_out)
      BioPieces::Fasta.open(tmp_out) do |ios|
        ios.each do |entry|
          record = entry.to_bp

          if record[:SEQ_NAME] =~ /;size=(\d+)$/
            record[:SEQ_COUNT] = Regexp.last_match(1).to_i
            record[:SEQ_NAME].sub!(/;size=\d+$/, '')
          else
            fail BioPieces::UsearchError, 'Missing size in SEQ_NAME: ' \
              "#{record[:SEQ_NAME]}"
          end

          output << record
          @sequences_out += 1
          @residues_out  += record[:SEQ].length
          @records_out   += 1
        end
      end
    end
  end
end
