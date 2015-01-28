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
    # == Split the values of a key into new key/value pairs.
    # 
    # +split_values+ splits the value of a given key into multiple values that
    # are added to the record. The keys used for the values are per default
    # based on the given key with an added index, but using the +keys+ option
    # allows specifying a list of keys to use instead.
    #
    # == Usage
    # 
    #    split_values(<key>: <string>>[, delimiter: <string>[, keys: <list>]])
    #
    # === Options
    #
    # # key:       <string> - Key who's value to split.
    # * keys:      <list>   - List of keys to use with split values.
    # * delimiter: <string> - Delimiter (default='_').
    #
    # == Examples
    # 
    # Consider the following records:
    #
    #    {ID: "FOO:count=10", SEQ: "gataag"}
    #    {ID: "FOO_10_20", SEQ: "gataag"}
    #
    # To split the value belinging to ID do:
    #
    #    split_values(key: :ID)
    #
    #    {:ID=>"FOO:count=10", :SEQ=>"gataag"}
    #    {:ID=>"FOO_10_20", :SEQ=>"gataag", :ID_0=>"FOO", :ID_1=>10, :ID_2=>20}
    #
    # Using a different delimiter:
    #
    #    split_values(key: "ID", delimiter: ':count=')
    #
    #    {:ID=>"FOO:count=10", :SEQ=>"gataag", :ID_0=>"FOO", :ID_1=>10}
    #    {:ID=>"FOO_10_20", :SEQ=>"gataag"}
    #
    # Using a different delimiter and a list of keys:
    #
    #    split_values(key: "ID", keys: ["ID", :COUNT], delimiter: ':count=')
    #
    #    {:ID=>"FOO", :SEQ=>"gataag", :COUNT=>10}
    #    {:ID=>"FOO_10_20", :SEQ=>"gataag"}
    def split_values(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :key, :keys, :delimiter)
      options_required(options, :key)

      options[:delimiter] ||= '_'

      lmb = lambda do |input, output, status|
        first   = true
        convert = []
        keys    = options[:keys]

        status_track(status) do
          input.each do |record|
            status[:records_in] += 1

            if value = record[options[:key].to_sym]
              values = value.split(options[:delimiter])

              if values.size > 1
                if first
                  values.each_with_index do |val, i|
                    val = val.to_num

                    if val.is_a? Fixnum
                      convert[i] = :to_i
                    elsif val.is_a? Float
                      convert[i] = :to_f
                    end
                  end

                  first = false
                end

                values.each_with_index do |val, i|
                  val = val.send(convert[i]) if convert[i]

                  if keys
                    record[keys[i].to_sym] = val
                  else
                    record["#{options[:key]}_#{i}".to_sym] = val
                  end
                end
              end
            end

            output << record

            status[:records_out] += 1
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

