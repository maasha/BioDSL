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
    # == Analyze the residue distribution from sequences in the stream.
    #
    # +analyze_residue_distribution+ determines the distribution per position
    # of residues from sequences.
    # 
    # == Usage
    # 
    #    analyze_residue_distribution([percent: <bool>])
    # 
    # === Options
    #
    # * percent: <bool>  - Output distributions in percent (default=false).
    #
    # == Examples
    # 
    # Here we output a table with residue distribution from a FASTA file:
    # 
    #    BP.new.
    #    read_fasta(input: "test.fna").
    #    analyze_residue_distribution.
    #    write_table.
    #    run
    #
    #
    def analyze_residue_distribution(options = {})
      require 'set'

      options_orig = options.dup
      options_load_rc(options, __method__)

      options_allowed(options, :percent)
      options_allowed_values(options, percent: [nil, true, false])

      lmb = lambda do |input, output, status|
        status_track(status) do
          counts   = Hash.new { |h, k| h[k] = Hash.new(0) } 
          residues = Set.new

          status[:sequences_in]  = 0
          status[:sequences_out] = 0

          input.each do |record|
            status[:records_in] += 1

            if record[:SEQ]
              status[:sequences_in] += 1
              status[:sequences_out] += 1

              record[:SEQ].upcase.chars.each_with_index do |char, i|
                c = char.to_sym
                counts[i][c] += 1
                residues.add(c)
              end
            end

            if output
              output << record

              status[:records_out] += 1
            end
          end

          residues.each do |res|
            record = {}
            record[:RECORD_TYPE] = "nucleotide distribution"
            record[:V0] = res.to_s

            counts.each do |pos, dist|
              record["V#{pos + 1}".to_sym] = dist[res]
            end
            
            if output
              output << record

              status[:records_out] += 1
            end
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end
