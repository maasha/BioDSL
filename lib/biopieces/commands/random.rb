# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2014 Martin Asser Hansen (mail@maasha.dk).                  #
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
    # == Pick number of random records from the stream.
    # 
    # +random+ can be used to pick a random number of records from the stream.
    # Note that the order of records is preserved.
    #
    # == Usage
    # 
    #    random(<number: <uint>)
    # 
    # === Options
    #
    # * number: <uint>  - Number of records to pick.
    # 
    # == Examples
    # 
    # To pick some random records from the stream do:
    #
    #    BP.new.
    #    read_fasta(input: "in.fna").
    #    random(number: 10_000).
    #    write_fasta(output: "out.fna").
    #    run
    def random(options = {})
      require 'tempfile'

      options_orig = options
      options_load_rc(options, __method__)
      options_allowed(options, :number)
      options_required(options, :number)
      options_assert(options, ":number > 0")

      lmb = lambda do |input, output, status|
        status_track(status) do
          file = Tempfile.new("random")

          begin
            File.open(file, 'w') do |ios|
              input.each do |record|
                status[:records_in] += 1

                ios.puts Marshal.dump(record)
              end
            end
            
            wanted = (0 ... status[:records_in]).to_a.shuffle[0 ... options[:number]].to_set

            File.open(file) do |ios|
              ios.each_with_index do |bin, i|
                if wanted.include? i
                  output << Marshal.load(bin)
                  status[:records_out] += 1
                end
              end
            end
          ensure
            file.close
            file.unlink
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

