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
# This software is part of the BioDSL framework (www.BioDSL.org).        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioDSL
  # == Collect OTU data from records in the stream.
  #
  # +collect_otus+ count the number of times each OTU is found in a set of
  # samples. OTUs are given by the :S_ID key and samples by the :SAMPLE key.
  # If a :SEQ_COUNT key is present it will be used to increment the OTU count,
  # allowing for dereplicated sequences to be used.
  #
  # == Usage
  #
  #    collect_otus()
  #
  # === Options
  #
  # == Examples
  #
  class CollectOtus
    require 'set'

    STATS = %i(records_in records_out hits_in hits_out)

    # Constructor for CollectOtus.
    #
    # @param options [Hash] Options hash.
    def initialize(options)
      @options = options

      check_options
    end

    # Return lambda for CollectOtus command.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        count_hash = process_input(input, output)
        samples    = collect_samples(count_hash)
        process_output(count_hash, samples, output)
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, nil)
    end

    # Read input stream and for all hit records add these to the count hash.
    #
    # @param input [Enumerator] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    #
    # @return [Hash] Returns the count_hash.
    def process_input(input, output)
      count_hash = Hash.new { |h, k| h[k] = Hash.new(0) }

      input.each do |record|
        @status[:records_in] += 1

        if record[:TYPE] && record[:TYPE] == 'H'
          add_to_count_hash(count_hash, record)
        end

        output << record
        @status[:records_out] += 1
      end

      count_hash
    end

    # Add to the count_hash a given record.
    #
    # @param count_hash [Hash] Hash with sample counts
    # @param record [Hash] BioDSL record with sample and count.
    def add_to_count_hash(count_hash, record)
      id     = record[:S_ID].to_sym
      sample = record[:SAMPLE].upcase.to_sym
      count_hash[id][sample] += (record[:SEQ_COUNT] || 1)
      @status[:hits_in] += 1
    end

    # Collect all samples in the count_hash into a sorted set.
    #
    # @param count_hash [Hash] Hash with sample counts.
    #
    # @return [SortedSet] Sample names.
    def collect_samples(count_hash)
      samples = SortedSet.new

      count_hash.values.each do |value|
        value.keys.map { |key| samples << key }
      end

      samples
    end

    # Output all samples and counts from the count_hash and samples to the
    # output stream.
    #
    # @param count_hash [Hash] Hash with sample counts
    # @param samples [SortedSet] Set with sample names.
    # @param output [Enumerator::Yielder] Output stream.
    def process_output(count_hash, samples, output)
      count_hash.each do |key, value|
        record = {}
        record[:RECORD_TYPE] = 'OTU'
        record[:OTU]         = key.to_s

        samples.each do |sample|
          record["#{sample}_COUNT".to_sym] = value[sample]
        end

        output << record

        @status[:hits_out]    += 1
        @status[:records_out] += 1
      end
    end
  end
end
