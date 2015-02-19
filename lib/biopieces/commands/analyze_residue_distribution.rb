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
    # of residues from sequences and output records per observed residue with
    # counts at the different positions. Using the +percent+ option outputs the
    # count as percentages of observed residues per position.
    #
    # The records output looks like this:
    #
    #     {:RECORD_TYPE=>"residue distribution",
    #      :V0=>"A",
    #      :V1=>5,
    #      :V2=>0,
    #      :V3=>0,
    #      :V4=>0}
    #
    #  Which are ready for +write_table+. See examples.
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
    # Consider the following entries in the file `test.fna`:
    #
    #    >DNA
    #    AGCT
    #    >RNA
    #    AGCU
    #    >Protein
    #    FLS*
    #    >Gaps
    #    -.~
    #
    # Now we run the data through the following pipeline and get the resulting
    # table:
    # 
    #    BP.new.
    #    read_fasta(input: "test.fna").
    #    analyze_residue_distribution.
    #    grab(select: "residue").
    #    write_table(skip: [:RECORD_TYPE]).
    #    run
    #    
    #    A 2 0 0 0
    #    G 0 2 0 0
    #    C 0 0 2 0
    #    T 0 0 0 1
    #    U 0 0 0 1
    #    F 1 0 0 0
    #    L 0 1 0 0
    #    S 0 0 1 0
    #    * 0 0 0 1
    #    - 1 0 0 0
    #    . 0 1 0 0
    #    ~ 0 0 1 0
    #    
    # Here we do the same as above, but output percentages instead of absolute
    # counts:
    #    
    #    BP.new.
    #    read_fasta(input: "test.fna").
    #    analyze_residue_distribution(percent: true).
    #    grab(select: "residue").
    #    write_table(skip: [:RECORD_TYPE]).
    #    run
    #
    #    A 50  0 0 0
    #    G 0 50  0 0
    #    C 0 0 50  0
    #    T 0 0 0 33
    #    U 0 0 0 33
    #    F 25  0 0 0
    #    L 0 25  0 0
    #    S 0 0 25  0
    #    * 0 0 0 33
    #    - 25  0 0 0
    #    . 0 25  0 0
    #    ~ 0 0 25  0
    def analyze_residue_distribution(options = {})
      require 'set'

      options_orig = options.dup
      options_load_rc(options, __method__)

      options_allowed(options, :percent)
      options_allowed_values(options, percent: [nil, true, false])

      lmb = lambda do |input, output, status|
        status_track(status) do
          counts   = Hash.new { |h, k| h[k] = Hash.new(0) } 
          total    = Hash.new(0)
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
                total[i]     += 1
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
            record[:RECORD_TYPE] = "residue distribution"
            record[:V0] = res.to_s

            if options[:percent]
              counts.each do |pos, dist|
                if total[pos] == 0
                  record["V#{pos + 1}".to_sym] = 0
                else
                  record["V#{pos + 1}".to_sym] = 100 * dist[res] / total[pos]
                end
              end
            else
              counts.each do |pos, dist|
                record["V#{pos + 1}".to_sym] = dist[res]
              end
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
