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
    #    analyze_residue_distribution(<type: <DNA|RNA|Protein>>
    #                                 [, percent: <bool>
    #                                 [, ambiguity: <bool>
    #                                 [, gaps: <bool>]]])
    # 
    # === Options
    #
    # * type: <DNA|RNA|Protein>  - Sequence type.
    # * percent: <bool>          - Output distributions in percent (default=false).
    # * ambiguity: <bool>        - Allow ambiguity codes for DNA|RNA (default=false).
    # * gaps: <bool>             - Allow gaps (default=false).
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
      options_orig = options.dup
      options_load_rc(options, __method__)

      options_allowed(options, :type, :percent, :ambiguity, :gaps)
      options_required(options, :type)
      options[:type] = options[:type].to_s.downcase.to_sym
      options_allowed_values(options, type: [:dna, :rna, :protein])
      options_allowed_values(options, ambiguity: [nil, true, false])
      options_allowed_values(options, gaps: [nil, true, false])
      options_files_exists_force(options, :output)

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:sequences_in]  = 0
          status[:sequences_out] = 0

          input.each do |record|
            status[:records_in] += 1

            if record[:SEQ]
              status[:sequences_in] += 1

              seq = record[:SEQ].upcase

              if output
                output << record

                status[:records_out]   += 1
                status[:sequences_out] += 1
              end
            else
              if output
                output << record

                status[:records_out] += 1
              end
            end
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end
