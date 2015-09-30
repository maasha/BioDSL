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
  # == Mask sequences in the stream based on quality scores.
  #
  # +mask_seq+ masks sequences in the stream using either hard masking or
  # soft masking (default). Hard masking is replacing residues with
  # corresponding quality score below a specified +quality_min+ with an N,
  # while soft is replacing such residues with lower case. The sequences are
  # values to SEQ keys and the quality scores are values to SCORES keys. The
  # SCORES are encoded as ranges of ASCII characters from '!' to 'I'
  # indicating scores from 0 to 40.
  #
  # == Usage
  #
  #    mask_seq([quality_min: <uint>[, mask: <:soft|:hard>]])
  #
  # === Options
  #
  # * quality_min: <uint> - Minimum quality (default=20).
  # * mask: <string>      - Soft or Hard mask (default=soft).
  #
  # == Examples
  #
  # Consider the following FASTQ entry in the file test.fq:
  #
  #    @HWI-EAS157_20FFGAAXX:2:1:888:434
  #    TTGGTCGCTCGCTCCGCGACCTCAGATCAGACGTGGGCGAT
  #    +HWI-EAS157_20FFGAAXX:2:1:888:434
  #    !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI
  #
  # We can read in these sequence using +read_fastq+ and then soft mask the
  # sequence with mask_seq like this:
  #
  #    BP.new.read_fastq(input: "test.fq").mask_seq.dump.run
  #
  #    {:SEQ_NAME=>"HWI-EAS157_20FFGAAXX:2:1:888:434",
  #     :SEQ=>"ttggtcgctcgctccgcgacCTCAGATCAGACGTGGGCGAT",
  #     :SEQ_LEN=>41,
  #     :SCORES=>"!\"\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI"}
  #
  # Using the +quality_min+ option we can change the cutoff:
  #
  #    BP.new.read_fastq(input: "test.fq").mask_seq(quality_min: 25).dump.run
  #
  #    {:SEQ_NAME=>"HWI-EAS157_20FFGAAXX:2:1:888:434",
  #     :SEQ=>"ttggtcgctcgctccgcgacctcagATCAGACGTGGGCGAT",
  #     :SEQ_LEN=>41,
  #     :SCORES=>"!\"\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI"}
  #
  # Using the +mask+ option for hard masking:
  #
  #    BP.new.read_fastq(input: "test.fq").mask_seq(mask: :hard).dump.run
  #
  #    {:SEQ_NAME=>"HWI-EAS157_20FFGAAXX:2:1:888:434",
  #     :SEQ=>"NNNNNNNNNNNNNNNNNNNNCTCAGATCAGACGTGGGCGAT",
  #     :SEQ_LEN=>41,
  #     :SCORES=>"!\"\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI"}
  class MaskSeq
    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out masked)

    # Constructor for MaskSeq.
    #
    # @param options [Hash] Options hash.
    # @option options [Integer] Minimum quality score.
    # @option options [Symbol,String] Mask scheme.
    #
    # @return [MaskSeq] Instance of MaskSeq.
    def initialize(options)
      @options = options

      check_options
      defaults

      @mask = options[:mask].to_sym
    end

    # Return command lambda for mask_seq.
    #
    # @return [Proc] command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        input.each do |record|
          @status[:records_in] += 1

          mask_seq(record) if record[:SEQ] && record[:SCORES]

          output << record

          @status[:records_out] += 1
        end

        @status[:masked_percent] =
          (100 * @status[:masked].to_f / @status[:residues_in]).round(2)
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :quality_min, :mask)
      options_allowed_values(@options, mask: [:soft, :hard, 'soft', 'hard'])
      options_assert(@options, ':quality_min >= 0')
      options_assert(@options, ':quality_min <= 40')
    end

    # Set default options.
    def defaults
      @options[:quality_min] ||= 20
      @options[:mask]        ||= :soft
    end

    # Mask sequence in given record.
    #
    # @param record [Hash] BioDSL record.
    def mask_seq(record)
      entry = BioDSL::Seq.new_bp(record)

      @status[:sequences_in] += 1
      @status[:residues_in]  += entry.length

      @mask == :soft ? mask_seq_soft(entry) : mask_seq_hard(entry)

      @status[:sequences_out] += 1
      @status[:residues_out]  += entry.length

      record.merge! entry.to_bp
    end

    # Soft mask sequences in given entry.
    #
    # @param entry [BioDSL::seq] sequences entry.
    def mask_seq_soft(entry)
      entry.mask_seq_soft!(@options[:quality_min])
      @status[:masked] += entry.seq.count('a-z')
    end

    # Hard mask sequences in given entry.
    #
    # @param entry [BioDSL::seq] sequences entry.
    def mask_seq_hard(entry)
      entry.mask_seq_hard!(@options[:quality_min])
      @status[:masked] += entry.seq.count('N')
    end
  end
end
