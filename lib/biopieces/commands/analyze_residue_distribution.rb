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
  class AnalyzeResidueDistribution
    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Constructor for the AnalyzeResidueDistribution class.
    #
    # @param [Hash] options Options hash.
    # @option options [Boolean] :percent Output distribution in percent.
    #
    # @return [AnalyzeResidueDistribution] Returns an instance of the class.
    def initialize(options)
      @options = options

      check_options
      status_init(STATS)

      @counts        = Hash.new { |h, k| h[k] = Hash.new(0) }
      @total         = Hash.new(0)
      @residues      = Set.new
    end

    # Return a lambda for the read_fasta command.
    #
    # @return [Proc] Returns the read_fasta command lambda.
    def lmb
      require 'set'

      lambda do |input, output, status|
        input.each do |record|
          @status[:records_in] += 1

          analyze_residues(record[:SEQ]) if record[:SEQ]

          if output
            output << record
            @status[:records_out] += 1
          end
        end

        calc_dist(output)

        status_assign(status, STATS)
      end
    end

    private

    # Check the options.
    def check_options
      options_allowed(@options, :percent)
      options_allowed_values(@options, percent: [nil, true, false])
    end

    # Analyze the sequence distribution of a given sequence.
    #
    # @param seq [String] - Sequence to analyze.
    def analyze_residues(seq)
      @status[:sequences_in]  += 1
      @status[:sequences_out] += 1
      @status[:residues_in]   += seq.length
      @status[:residues_out]  += seq.length

      seq.upcase.chars.each_with_index do |char, i|
        c = char.to_sym
        @counts[i][c] += 1
        @total[i]     += 1
        @residues.add(c)
      end
    end

    # Calculate the residue destribution.
    #
    # @param output [BioPieces::Stream] Output stream.
    def calc_dist(output)
      @residues.each do |res|
        record               = {}
        record[:RECORD_TYPE] = 'residue distribution'
        record[:V0]          = res.to_s

        if @options[:percent]
          calc_dist_percent(record, res)
        else
          calc_dist_count(record, res)
        end

        output << record
      end
    end

    # Calculate the residue distribution in percent for a given residue.
    #
    # @param record [Hash] BioPieces record.
    # @param res [Symbol] Residue.
    def calc_dist_percent(record, res)
      @counts.each do |pos, dist|
        value = (@total[pos] == 0) ? 0 : 100 * dist[res] / @total[pos]
        record["V#{pos + 1}".to_sym] = value
      end
    end

    # Calculate the residue distribution for a given residue.
    #
    # @param record [Hash] BioPieces record.
    # @param res [Symbol] Residue.
    def calc_dist_count(record, res)
      @counts.each do |pos, dist|
        record["V#{pos + 1}".to_sym] = dist[res]
      end
    end
  end
end
