# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                  #
#                                                                                #
# This program is free software; you can redistribute it and/or                  #
# modify it under the terms of the GNU General Public License                    #
# as published by the Free Software Foundation; either version 2                 #
# of the License, or (at your option) any later version.                         #
#                                                                                #
# This program is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                 #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                  #
# GNU General Public License for more details.                                   #
#                                                                                #
# You should have received a copy of the GNU General Public License              #
# along with this program; if not, write to the Free Software                    #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. #
#                                                                                #
# http://www.gnu.org/copyleft/gpl.html                                           #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# This software is part of the Biopieces framework (www.biopieces.org).          #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  module Commands
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
    def collect_otus(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, nil)

      lmb = lambda do |input, output, status|
        status[:hits_in] = 0
        count_hash       = Hash.new { |h, k| h[k] = Hash.new(0) }

        status_track(status) do
          input.each do |record|
            status[:records_in] += 1

            if record[:TYPE] and record[:TYPE] == 'H'
              status[:hits_in] += 1
              count_hash[record[:S_ID].to_sym][record[:SAMPLE].upcase.to_sym] += (record[:SEQ_COUNT] || 1)
            end

            output << record
            status[:records_out] += 1
          end
        end

        sample_hash = {}
        
        count_hash.values.each do |value|
          value.keys.map { |key| sample_hash[key] = true }
        end
         
        sample_list = sample_hash.keys.sort

        count_hash.each do |key, value|
          record = {}
          record[:RECORD_TYPE] = "OTU"
          record[:OTU]         = key.to_s

          sample_list.each { |sample| record["#{sample}_COUNT".to_sym] = value[sample] }

          output << record
          status[:records_out] += 1
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

