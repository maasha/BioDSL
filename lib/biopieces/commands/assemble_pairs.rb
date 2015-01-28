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
    # == Assemble ordered overlapping pair-end sequences in the stream.
    # 
    # +assemble_pairs+ assembles overlapping pair-end sequences into single
    # sequences that are output to the stream - the orginal sequences are no
    # output. Assembly works by progressively considering all overlaps between
    # the maximum considered overlap using the +overlap_max+ option (default is
    # the length of the shortest sequence) until the minimum required overlap
    # supplied with the +overlap_min+ option (default 1). For each overlap a 
    # percentage of mismatches can be allowed using the +mismatch_percent+
    # option (default 20%).
    #
    # Mismatches in the overlapping regions are resolved so that the residues with
    # the highest quality score is used in the assembled sequence. The quality scores
    # are averaged in the overlapping region. The sequence of the overlapping region
    # is output in upper case and the remaining in lower case.
    #
    # Futhermore, sequences must be in interleaved order in the stream - use
    # +read_fastq+ with +input+ and +input2+ options for that.
    #
    # The additional keys are added to records with assembled sequences:
    #
    # * OVERLAP_LEN   - the length of the located overlap.
    # * HAMMING_DIST  - the number of mismatches in the assembly.
    #
    # Using the +merge_unassembled+ option will merge any unassembled sequences
    # taking into account reverse complementation of read2 if the
    # +reverse_complement+ option is true. Note that you probably want to set
    # +overlap_min+ to 1 before using +merge_unassembled+ to improve chances
    # of making an assembly before falling back to a simple merge.
    #
    # == Usage
    # 
    #    assemble_pairs([mismatch_percent: <uint>[, overlap_min: <uint>
    #                   [, overlap_max: <uint>[, reverse_complement: <bool>
    #                   [, merge_unassembled: <bool>]]]]])
    #
    # === Options
    #
    # * mismatch_percent: <uint>   - Maximum allowed overlap mismatches in percent (default=20).
    # * overlap_min: <uint>        - Minimum overlap required (default=1).
    # * overlap_max: <uint>        - Maximum overlap considered (default=<length of shortest sequences>).
    # * reverse_complement: <bool> - Reverse-complement read2 before assembly (default=false).
    # * merge_unassembled: <bool>  - Merge unassembled pairs (default=false).
    # 
    # == Examples
    # 
    # If you have two pair-end sequence files with the Illumina data then you
    # can assemble these using assemble_pairs like this:
    #
    #    BP.new.
    #    read_fastq(input: "file1.fq", input2: "file2.fq).
    #    assemble_pairs(reverse_complement: true).
    #    run
    def assemble_pairs(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :mismatch_percent, :overlap_min, :overlap_max, :reverse_complement, :merge_unassembled)
      options_allowed_values(options, reverse_complement: [true, false, nil])
      options_allowed_values(options, merge_unassembled: [true, false, nil])
      options_assert(options, ":mismatch_percent >= 0")
      options_assert(options, ":mismatch_percent <= 100")
      options_assert(options, ":overlap_min > 0")

      options[:mismatch_percent] ||= 20
      options[:overlap_min]      ||= 1

      lmb = lambda do |input, output, status|
        status_track(status) do
          overlap_sum = 0
          hamming_sum = 0

          status[:sequences_in]  = 0
          status[:sequences_out] = 0
          status[:residues_in]   = 0
          status[:residues_out]  = 0
          status[:assembled]     = 0
          status[:unassembled]   = 0

          input.each_slice(2) do |record1, record2|
            status[:records_in] += 2

            if record1 and record2 and record1[:SEQ] and record2[:SEQ]
              entry1 = BioPieces::Seq.new_bp(record1)
              entry2 = BioPieces::Seq.new_bp(record2)

              status[:sequences_in] += 2
              status[:residues_in]  += entry1.length + entry2.length

              if entry1.length >= options[:overlap_min] and
                 entry2.length >= options[:overlap_min]

                if options[:reverse_complement]
                  entry1.type = :dna
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
                  status[:assembled] += 1

                  new_record = merged.to_bp

                  if merged.seq_name =~ /overlap=(\d+):hamming=(\d+)$/
                    overlap = $1.to_i
                    hamming = $2.to_i
                    overlap_sum += overlap
                    hamming_sum += hamming
                    new_record[:OVERLAP_LEN]  = overlap
                    new_record[:HAMMING_DIST] = hamming
                  end

                  output << new_record

                  status[:records_out]   += 1
                  status[:sequences_out] += 1
                  status[:residues_out]  += merged.length
                elsif options[:merge_unassembled]
                  entry1 << entry2

                  new_record = entry1.to_bp
                  new_record[:OVERLAP_LEN] = 0
                  new_record[:HAMMING_DIST] = entry1.length

                  output << new_record

                  status[:unassembled]   += 1
                  status[:sequences_out] += 1
                  status[:residues_out]  += entry1.length
                  status[:records_out]   += 1
                else
                  status[:unassembled] += 1
                end
              elsif options[:merge_unassembled]
                if options[:reverse_complement]
                  entry1.type = :dna
                  entry2.type = :dna
                  entry2.reverse!.complement!
                end

                entry1 << entry2

                new_record = entry1.to_bp
                new_record[:OVERLAP_LEN] = 0
                new_record[:HAMMING_DIST] = entry1.length

                output << new_record

                status[:unassembled]   += 1
                status[:sequences_out] += 1
                status[:residues_out]  += entry1.length
                status[:records_out]   += 1
              else
                status[:unassembled]   += 1
              end
            else
              if record1
                output << record1

                status[:records_out] += 1
              end

              if record2
                output << record2

                status[:records_out] += 1
              end
            end
          end

          status[:assembled_percent] = (100 * status[:assembled].to_f / status[:sequences_in]).round(2)
          status[:overlap_mean]      = (overlap_sum.to_f / status[:records_out]).round(2)
          status[:hamming_dist_mean] = (hamming_sum.to_f / status[:records_out]).round(2)
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

