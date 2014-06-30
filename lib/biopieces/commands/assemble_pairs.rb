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
    # == Grab records in stream.
    # 
    # +assemble_pairs+ select records from the stream by matching patterns to keys or
    # values. +assemble_pairs+ is  Biopieces' equivalent of Unix' +grep+, however, +assemble_pairs+
    # is much more versatile.
    # 
    # NB! If chaining multiple +assemble_pairs+ commands then use the most restrictive +assemble_pairs+
    # first in order to get the best performance.
    # 
    # == Usage
    # 
    #    assemble_pairs(<select: <pattern>|select_file: <file>|reject: <pattern>|
    #                reject_file: <file>|evaluate: <expression>|exact: <bool>>
    #               [, keys: <list>|keys_only: <bool>|values_only: <bool>|
    #               ignore_case: <bool>])
    # 
    # === Options
    #
    # * select: <pattern>      - Select records matching <pattern> which is
    #   a regex or an exact match if the exact option is set.
    # * select_file: <file>    - File with one <pattern> per line to select.
    # * reject: <pattern>      - Reject records matching <pattern> which is
    #   a regex or an exact match if the exact option is set.
    # * reject_file: <file>    - File with one <pattern> per line to reject.
    # * evaluate: <expression> - Select records where <expression> is true.
    # * exact: <bool>          - Turn on exact matching for improved speed.
    # * keys: <list>           - Comma separated list or array of keys to assemble_pairs
    #   the value for.
    # * keys_only: <bool>      - Only assemble_pairs for keys.
    # * values_only: <bool>    - Only assemble_pairs for values.
    # * ignore_case: <bool>    - Ignore case when assemble_pairsbing with regex (does not
    #   work with +evaluate+ and +exact+).
    # 
    # == Examples
    # 
    # To easily assemble_pairs all records in the stream that has any mentioning of the
    # pattern 'human' just pipe the data stream through assemble_pairs like this:
    # 
    #    assemble_pairs(select: "human")
    # 
    # This will search for the pattern 'human' in all keys and all values. The
    # +select+ option alternatively uses an array of patterns, so in order to
    # match one of multiple patterns do:
    # 
    #    assemble_pairs(select: ["human", "mouse"])
    # 
    # It is also possible to invoke flexible matching using regex (regular
    # expressions) instead of simple pattern matching. If you want to +assemble_pairs+ 
    # records with the sequence +ATCG+ or +GCTA+ you can do this:
    # 
    #    assemble_pairs(select: "ATCG|GCTA")
    # 
    # Or if you want to +assemble_pairs+ sequences beginning with +ATCG+:
    # 
    #    assemble_pairs(select: "^ATCG")
    # 
    # It is also possible to use the +select_file+ option to load patterns from
    # a file with one pattern per line.
    # 
    #    assemble_pairs(select_file: "patterns.txt")
    # 
    # If you want the opposite result - to find all records that does not match
    # the a pattern, use the +reject+ option:
    # 
    #    assemble_pairs(reject: "human")
    # 
    # Similar to +select_file+ there is a +reject_file+ option to load patterns
    # from a file, and use any of these patterns to reject records:
    #
    #    assemble_pairs(reject_file: "patterns.txt")
    #
    # If you want to search the record keys only, e.g. to +assemble_pairs+ all records
    # containing the key +SEQ+ you can use the +keys_only+ option. This will
    # prevent matching of +SEQ+ in any record value, and in fact +SEQ+ is a not
    # uncommon peptide sequence you could get an unwanted record. Also, this
    # will give an increase in speed since only the keys are searched:
    # 
    #    assemble_pairs(select: "SEQ", keys_only: true)
    # 
    # However, if you are interested in +assemble_pairsbing+ the peptide sequence +SEQ+ and
    # not the +SEQ+ key, just use the +vals_only+ option:
    # 
    #    assemble_pairs(select: "SEQ", vals_only: true)
    # 
    # Also, if you want to +assemble_pairs+ for certain key/value pairs you can supply a
    # comma separated list or an array of keys whos values will then be assemble_pairsbed
    # using the +keys+ option. This is handy if your records contain large
    # genomic sequences and you don't want to search the entire sequence for
    # e.g. the organism name - it is much faster to tell +assemble_pairs+ which keys to
    # search the value for:
    # 
    #    assemble_pairs(select: "human", keys: :SEQ_NAME)
    # 
    # You can also use the +evaluate+ option to +assemble_pairs+ records that fulfill an
    # expression. So to +assemble_pairs+ all records with a sequence length greater than 30:
    # 
    #    assemble_pairs(evaluate: 'SEQ_LEN > 30')
    # 
    # If you want to +assemble_pairs+ all records containing the pattern 'human' and where the
    # sequence length is greater that 30, you do this by running the stream through
    # +assemble_pairs+ twice:
    # 
    #    assemble_pairs(select: 'human').assemble_pairs(evaluate: 'SEQ_LEN > 30')
    # 
    # Finally, it is possible to +assemble_pairs+ for exact pattern using the +exact+
    # option. This is much faster than the default regex pattern assemble_pairsbing
    # because with +exact+ the patterns are used to create a lookup hash for
    # instant matching of keys or values. This is useful if you e.g. have a
    # file with ID numbers and you want to +assemble_pairs+ matching records from the 
    # stream:
    # 
    #    assemble_pairs(select_file: "ids.txt", keys: :ID, exact: true)
    def assemble_pairs(options = {})
      options_orig = options.dup
      @options = options
      options_allowed :mismatch_percent, :overlap_min, :overlap_max, :reverse_complement
      options_allowed_values reverse_complement: [true, false, nil]
      options_assert ":mismatch_percent >= 0"
      options_assert ":mismatch_percent <= 100"
      options_assert ":overlap_min > 0"

      @options[:mismatch_percent] ||= 20
      @options[:overlap_min]      ||= 1

      lmb = lambda do |input, output, run_options|
        status_track(input, output, run_options) do
          input.each_slice(2) do |record1, record2|
            if record1[:SEQ] and record2[:SEQ]
              entry1 = BioPieces::Seq.new_bp(record1)
              entry2 = BioPieces::Seq.new_bp(record2)

              if entry1.length >= options[:overlap_min] and
                entry2.length >= options[:overlap_min]

                if options[:reverse_complement]
                  entry2.type = :dna
                  entry2.reverse!.complement!
                end

                merged = BioPieces::Assemble.pair(
                  entry1,
                  entry2,
                  mismatches_max: options[:mismatch_percent],
                  overlap_min: options[:overlap_min],
                  overlap_max: options[:overlap_max]
                )

                if merged
                  new_record = merged.to_bp

                  if merged.seq_name =~ /overlap=(\d+):hamming=(\d+)$/
                    new_record[:OVERLAP_LEN]  = $1
                    new_record[:HAMMING_DIST] = $2
                  end

                  output.write new_record
                end
              end
            else
              output.puts record1
              output.puts record2
            end
          end
        end
      end

      add(__method__, options, options_orig, lmb)

      self
    end
  end
end

