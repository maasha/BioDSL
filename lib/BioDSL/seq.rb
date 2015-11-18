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
# This software is part BioDSL (www.BioDSL.org).                               #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

# Namespace for BioDSL.
module BioDSL
  require 'English'
  require 'narray'
  require 'BioDSL/seq/ambiguity'
  require 'BioDSL/seq/assemble'
  require 'BioDSL/seq/digest'
  require 'BioDSL/seq/kmer'
  require 'BioDSL/seq/translate'
  require 'BioDSL/seq/trim'
  require 'BioDSL/seq/backtrack'
  require 'BioDSL/seq/dynamic'
  require 'BioDSL/seq/homopolymer'
  require 'BioDSL/seq/levenshtein'

  # Error class for all exceptions to do with Seq.
  class SeqError < StandardError; end

  # rubocop: disable ClassLength

  # Class for manipulating sequences.
  class Seq
    # Residue alphabets
    DNA     = %w(a t c g)
    RNA     = %w(a u c g)
    PROTEIN = %w(f l s y c w p h q r i m t n k v a d e g)
    INDELS  = %w(. - _ ~)

    # Quality scores bases
    SCORE_BASE = 33
    SCORE_MIN  = 0
    SCORE_MAX  = 40

    include BioDSL::Digest
    include BioDSL::Homopolymer
    include BioDSL::Translate
    include BioDSL::Trim
    include BioDSL::Kmer
    include BioDSL::BackTrack

    attr_accessor :seq_name, :seq, :type, :qual

    # Class method to instantiate a new Sequence object given
    # a Biopiece record.
    def self.new_bp(record)
      seq_name = record[:SEQ_NAME]
      seq      = record[:SEQ]
      type     = record[:SEQ_TYPE].to_sym if record[:SEQ_TYPE]
      qual     = record[:SCORES]

      new(seq_name: seq_name, seq: seq, type: type, qual: qual)
    end

    # Class method that generates all possible oligos of a specifed length and
    # type.
    def self.generate_oligos(length, type)
      fail SeqError, "Bad length: #{length}" if length <= 0

      case type.downcase
      when :dna     then alph = DNA
      when :rna     then alph = RNA
      when :protein then alph = PROTEIN
      else
        fail SeqError, "Unknown sequence type: #{type}"
      end

      oligos = ['']

      (1..length).each do
        list = []

        oligos.each do |oligo|
          alph.each { |char| list << oligo + char }
        end

        oligos = list
      end

      oligos
    end

    def self.check_name_pair(entry1, entry2)
      if entry1.seq_name =~ /^([^ ]+) \d:/
        name1 = Regexp.last_match[1]
      elsif entry1.seq_name =~ %r{^(.+)\/\d$}
        name1 = Regexp.last_match[1]
      else
        fail SeqError, "Could not match sequence name: #{entry1.seq_name}"
      end

      if entry2.seq_name =~ /^([^ ]+) \d:/
        name2 = Regexp.last_match[1]
      elsif entry2.seq_name =~ %r{^(.+)\/\d$}
        name2 = Regexp.last_match[1]
      else
        fail SeqError, "Could not match sequence name: #{entry2.seq_name}"
      end

      fail SeqError, "Name mismatch: #{name1} != #{name2}" if name1 != name2
    end

    # Initialize a sequence object with the following options:
    # - :seq_name   Name of the sequence.
    # - :seq        The sequence.
    # - :type       The sequence type - DNA, RNA, or protein
    # - :qual       An Illumina type quality scores string.
    def initialize(options = {})
      @seq_name = options[:seq_name]
      @seq      = options[:seq]
      @type     = options[:type]
      @qual     = options[:qual]

      return unless @seq && @qual
      return if @seq.length == @qual.length

      fail SeqError, 'Sequence length and score length mismatch: ' \
      "#{@seq.length} != #{@qual.length}"
    end

    # Method that guesses and returns the sequence type
    # by inspecting the first 100 residues.
    def type_guess
      fail SeqError, 'Guess failed: sequence is nil' if @seq.nil?

      case @seq[0...100].downcase
      when /[flpqie]/ then return :protein
      when /[u]/      then return :rna
      else                 return :dna
      end
    end

    # Method that guesses and sets the sequence type
    # by inspecting the first 100 residues.
    def type_guess!
      @type = type_guess
      self
    end

    # Returns the length of a sequence.
    def length
      @seq.nil? ? 0 : @seq.length
    end

    alias_method :len, :length

    # Return the number indels in a sequence.
    def indels
      regex = Regexp.new(/[#{Regexp.escape(INDELS.join(""))}]/)
      @seq.scan(regex).size
    end

    # Method to remove indels from seq and qual if qual.
    def indels_remove
      if @qual.nil?
        @seq.delete!(Regexp.escape(INDELS.join('')))
      else
        na_seq  = NArray.to_na(@seq, 'byte')
        na_qual = NArray.to_na(@qual, 'byte')
        mask    = NArray.byte(length)

        INDELS.each do |c|
          mask += na_seq.eq(c.ord)
        end

        mask = mask.eq(0)

        @seq  = na_seq[mask].to_s
        @qual = na_qual[mask].to_s
      end

      self
    end

    # Method that returns true is a given sequence type is DNA.
    def dna?
      @type == :dna
    end

    # Method that returns true is a given sequence type is RNA.
    def rna?
      @type == :rna
    end

    # Method that returns true is a given sequence type is protein.
    def protein?
      @type == :protein
    end

    # Method to transcribe DNA to RNA.
    def to_rna
      fail SeqError, 'Cannot transcribe 0 length sequence' if length == 0
      fail SeqError, 'Cannot transcribe sequence type: #{@type}' unless dna?
      @type = :rna
      @seq.tr!('Tt', 'Uu')
    end

    # Method to reverse-transcribe RNA to DNA.
    def to_dna
      fail SeqError, 'Cant reverse-transcribe 0 length sequence' if length == 0
      fail SeqError, "Cant reverse-transcribe seq type: #{@type}" unless rna?
      @type = :dna
      @seq.tr!('Uu', 'Tt')
    end

    # Method that given a Seq entry returns a BioDSL record (a hash).
    def to_bp
      record            = {}
      record[:SEQ_NAME] = @seq_name if @seq_name
      record[:SEQ]      = @seq      if @seq
      record[:SEQ_LEN]  = length    if @seq
      record[:SCORES]   = @qual     if @qual
      record
    end

    # Method that given a Seq entry returns a FASTA entry (a string).
    def to_fasta(wrap = nil)
      fail SeqError, 'Missing seq_name' if @seq_name.nil? || @seq_name == ''
      fail SeqError, 'Missing seq'      if @seq.nil? || @seq.empty?

      seq_name = @seq_name.to_s
      seq      = @seq.to_s

      unless wrap.nil?
        seq.gsub!(/(.{#{wrap}})/) do |match|
          match << $INPUT_RECORD_SEPARATOR
        end

        seq.chomp!
      end

      ">#{seq_name}#{$INPUT_RECORD_SEPARATOR}#{seq}#{$INPUT_RECORD_SEPARATOR}"
    end

    # Method that given a Seq entry returns a FASTQ entry (a string).
    def to_fastq
      fail SeqError, 'Missing seq_name' if @seq_name.nil?
      fail SeqError, 'Missing seq'      if @seq.nil?
      fail SeqError, 'Missing qual'     if @qual.nil?

      seq_name = @seq_name.to_s
      seq      = @seq.to_s
      qual     = @qual.to_s

      "@#{seq_name}#{$RS}#{seq}#{$RS}+#{$RS}#{qual}#{$RS}"
    end

    # Method that generates a unique key for a
    # DNA sequence and return this key as a Fixnum.
    def to_key
      key = 0

      @seq.upcase.each_char do |char|
        key <<= 2

        case char
        when 'A' then key |= 0
        when 'C' then key |= 1
        when 'G' then key |= 2
        when 'T' then key |= 3
        else fail SeqError, "Bad residue: #{char}"
        end
      end

      key
    end

    # Method to reverse the sequence.
    def reverse
      entry = Seq.new(
        seq_name: @seq_name,
        seq:      @seq.reverse,
        type:     @type,
        qual:     (@qual ? @qual.reverse : @qual)
      )

      entry
    end

    # Method to reverse the sequence.
    def reverse!
      @seq.reverse!
      @qual.reverse! if @qual
      self
    end

    # Method that complements sequence including ambiguity codes.
    def complement
      fail SeqError, 'Cannot complement 0 length sequence' if length == 0

      entry = Seq.new(seq_name: @seq_name, type: @type, qual: @qual)

      if dna?
        entry.seq = @seq.tr('AGCUTRYWSMKHDVBNagcutrywsmkhdvbn',
                            'TCGAAYRWSKMDHBVNtcgaayrwskmdhbvn')
      elsif rna?
        entry.seq = @seq.tr('AGCUTRYWSMKHDVBNagcutrywsmkhdvbn',
                            'UCGAAYRWSKMDHBVNucgaayrwskmdhbvn')
      else
        fail SeqError, "Cannot complement sequence type: #{@type}"
      end

      entry
    end

    # Method that complements sequence including ambiguity codes.
    def complement!
      fail SeqError, 'Cannot complement 0 length sequence' if length == 0

      if dna?
        @seq.tr!('AGCUTRYWSMKHDVBNagcutrywsmkhdvbn',
                 'TCGAAYRWSKMDHBVNtcgaayrwskmdhbvn')
      elsif rna?
        @seq.tr!('AGCUTRYWSMKHDVBNagcutrywsmkhdvbn',
                 'UCGAAYRWSKMDHBVNucgaayrwskmdhbvn')
      else
        fail SeqError, "Cannot complement sequence type: #{@type}"
      end

      self
    end

    # Method to determine the Hamming Distance between
    # two Sequence objects (case insensitive).
    def hamming_distance(entry, options = {})
      if options[:ambiguity]
        BioDSL::Hamming.distance(@seq, entry.seq, options)
      else
        BioDSL::Hamming.distance(@seq.upcase, entry.seq.upcase, options)
      end
    end

    # Method to determine the Edit Distance between
    # two Sequence objects (case insensitive).
    def edit_distance(entry)
      Levenshtein.distance(@seq, entry.seq)
    end

    # Method that generates a random sequence of a given length and type.
    def generate(length, type)
      fail SeqError, "Cannot generate seq length < 1: #{length}" if length <= 0

      case type
      when :dna     then alph = DNA
      when :rna     then alph = RNA
      when :protein then alph = PROTEIN
      else
        fail SeqError, "Unknown sequence type: #{type}"
      end

      seq_new = Array.new(length) { alph[rand(alph.size)] }.join('')
      @seq    = seq_new
      @type   = type

      seq_new
    end

    # Method to return a new Seq object with shuffled sequence.
    def shuffle
      Seq.new(
        seq_name: @seq_name,
        seq:      @seq.split('').shuffle!.join,
        type:     @type,
        qual:     @qual
      )
    end

    # Method to shuffle a sequence randomly inline.
    def shuffle!
      @seq = @seq.split('').shuffle!.join
      self
    end

    # Method to add two Seq objects.
    def +(other)
      new_entry = Seq.new
      new_entry.seq  = @seq + other.seq
      new_entry.type = @type              if @type == other.type
      new_entry.qual = @qual + other.qual if @qual && other.qual
      new_entry
    end

    # Method to concatenate sequence entries.
    def <<(entry)
      fail SeqError, 'sequences of different types' unless @type == entry.type
      fail SeqError, 'qual is missing in one entry' unless @qual.class ==
                                                           entry.qual.class

      @seq << entry.seq
      @qual << entry.qual unless entry.qual.nil?

      self
    end

    # Index method for Seq objects.
    def [](*args)
      entry = Seq.new
      entry.seq_name = @seq_name.dup unless @seq_name.nil?
      entry.seq      = @seq[*args] || ''
      entry.type     = @type
      entry.qual     = @qual[*args] || '' unless @qual.nil?

      entry
    end

    # Index assignment method for Seq objects.
    def []=(*args, entry)
      @seq[*args]  = entry.seq[*args]
      @qual[*args] = entry.qual[*args] unless @qual.nil?

      self
    end

    # Method that returns the residue compositions of a sequence in
    # a hash where the key is the residue and the value is the residue
    # count.
    def composition
      comp = Hash.new(0);

      @seq.upcase.each_char do |char|
        comp[char] += 1
      end

      comp
    end

    # Method that returns the percentage of hard masked residues
    # or N's in a sequence.
    def hard_mask
      ((@seq.upcase.scan('N').size.to_f / (length - indels).to_f) * 100).
        round(2)
    end

    # Method that returns the percentage of soft masked residues
    # or lower cased residues in a sequence.
    def soft_mask
      ((@seq.scan(/[a-z]/).size.to_f / (length - indels).to_f) * 100).round(2)
    end

    # Hard masks sequence residues where the corresponding quality scoreis below
    # a given cutoff.
    def mask_seq_hard!(cutoff)
      fail SeqError, 'seq is nil'  if @seq.nil?
      fail SeqError, 'qual is nil' if @qual.nil?
      fail SeqError, "cufoff value: #{cutoff} out of range: " \
                      "#{SCORE_MIN}..#{SCORE_MAX}" unless (SCORE_MIN..SCORE_MAX).
                                                          include? cutoff

      na_seq  = NArray.to_na(@seq.upcase, 'byte')
      na_qual = NArray.to_na(@qual, 'byte')
      mask    = (na_qual - SCORE_BASE) < cutoff
      mask *= na_seq.ne('-'.ord)

      na_seq[mask] = 'N'.ord

      @seq = na_seq.to_s

      self
    end

    # Soft masks sequence residues where the corresponding quality score
    # is below a given cutoff. Masked sequence will be lowercased and
    # remaining will be uppercased.
    def mask_seq_soft!(cutoff)
      fail SeqError, 'seq is nil'  if @seq.nil?
      fail SeqError, 'qual is nil' if @qual.nil?
      fail SeqError, "cufoff value: #{cutoff} out of range: " \
                     "#{SCORE_MIN} .. #{SCORE_MAX}" unless (SCORE_MIN..SCORE_MAX).
                                                           include? cutoff

      na_seq  = NArray.to_na(@seq.upcase, 'byte')
      na_qual = NArray.to_na(@qual, 'byte')
      mask    = (na_qual - SCORE_BASE) < cutoff
      mask *= na_seq.ne('-'.ord)

      na_seq[mask] ^= ' '.ord

      @seq = na_seq.to_s

      self
    end

    # Method that determines if a quality score string can be
    # absolutely identified as base 33.
    def qual_base33?
      @qual.match(/[!-:]/) ? true : false
    end

    # Method that determines if a quality score string may be base 64.
    def qual_base64?
      @qual.match(/[K-h]/) ? true : false
    end

    # Method to determine if a quality score is valid accepting only 0-40 range.
    def qual_valid?(encoding)
      fail SeqError, 'Missing qual' if @qual.nil?

      case encoding
      when :base_33 then return true if @qual.match(/^[!-I]*$/)
      when :base_64 then return true if @qual.match(/^[@-h]*$/)
      else fail SeqError, "unknown quality score encoding: #{encoding}"
      end

      false
    end

    # Method to coerce quality scores to be within the 0-40 range.
    def qual_coerce!(encoding)
      fail SeqError, 'Missing qual' if @qual.nil?

      case encoding
      when :base_33 then qual_coerce_C(@qual, @qual.length, 33, 73)  # !-J
      when :base_64 then qual_coerce_C(@qual, @qual.length, 64, 104) # @-h
      else
        fail SeqError, "unknown quality score encoding: #{encoding}"
      end

      self
    end

    # Method to convert quality scores.
    def qual_convert!(from, to)
      unless from == :base_33 || from == :base_64
        fail SeqError, "unknown quality score encoding: #{from}"
      end

      unless to == :base_33 || to == :base_64
        fail SeqError, "unknown quality score encoding: #{to}"
      end

      if from == :base_33 && to == :base_64
        qual_convert_C(@qual, @qual.length, 31) # += 64 - 33
      elsif from == :base_64 && to == :base_33
        # Handle negative Solexa values from -5 to -1 (set these to 0).
        qual_coerce_C(@qual, @qual.length, 64, 104)
        qual_convert_C(@qual, @qual.length, -31) # -= 64 - 33
      end

      self
    end

    # Method to calculate and return the mean quality score.
    def scores_mean
      fail SeqError, 'Missing qual in entry' if @qual.nil?

      na_qual = NArray.to_na(@qual, 'byte')
      na_qual -= SCORE_BASE

      na_qual.mean
    end

    # Method to calculate and return the min quality score.
    def scores_min
      fail SeqError, 'Missing qual in entry' if @qual.nil?

      na_qual = NArray.to_na(@qual, 'byte')
      na_qual -= SCORE_BASE

      na_qual.min
    end

    # Method to calculate and return the max quality score.
    def scores_max
      fail SeqError, 'Missing qual in entry' if @qual.nil?

      na_qual = NArray.to_na(@qual, 'byte')
      na_qual -= SCORE_BASE

      na_qual.max
    end

    # Method to run a sliding window of a specified size across a Phred type
    # scores string and calculate for each window the mean score and return
    # the minimum mean score.
    def scores_mean_local(window_size)
      fail SeqError, 'Missing qual in entry' if @qual.nil?

      scores_mean_local_C(@qual, @qual.length, SCORE_BASE, window_size)
    end

    # Method to find open reading frames (ORFs).
    def each_orf(options = {})
      size_min     = options[:size_min] || 0
      size_max     = options[:size_max] || length
      start_codons = options[:start_codons] || 'ATG,GTG,AUG,GUG'
      stop_codons  = options[:stop_codons] || 'TAA,TGA,TAG,UAA,UGA,UAG'
      pick_longest = options[:pick_longest]

      orfs    = []
      pos_beg = 0

      regex_start = Regexp.new(start_codons.split(',').join('|'), true)
      regex_stop  = Regexp.new(stop_codons.split(',').join('|'), true)

      while pos_beg && pos_beg < length - size_min
        pos_beg = @seq.index(regex_start, pos_beg)
        next unless pos_beg
        pos_end = @seq.index(regex_stop, pos_beg)
        next unless pos_end

        orf_length = (pos_end - pos_beg) + 3

        if (orf_length % 3) == 0
          if size_min <= orf_length && orf_length <= size_max
            subseq = self[pos_beg...pos_beg + orf_length]

            orfs << Orf.new(subseq, pos_beg, pos_end + 2)
          end
        end

        pos_beg += 1
      end

      if pick_longest
        orf_hash = {}

        orfs.each { |orf| orf_hash[orf.stop] = orf unless orf_hash[orf.stop] }

        orfs = orf_hash.values
      end

      if block_given?
        orfs.each { |orf| yield orf }
      else
        return orfs
      end
    end

    # Struct for holding an ORF.
    Orf = Struct.new(:entry, :start, :stop)

    inline do |builder|
      builder.c %{
        VALUE qual_coerce_C(
          VALUE _qual,
          VALUE _qual_len,
          VALUE _min_value,
          VALUE _max_value
        )
        {
          unsigned char *qual      = (unsigned char *) StringValuePtr(_qual);
          unsigned int   qual_len  = FIX2UINT(_qual_len);
          unsigned int   min_value = FIX2UINT(_min_value);
          unsigned int   max_value = FIX2UINT(_max_value);
          unsigned int   i         = 0;

          for (i = 0; i < qual_len; i++)
          {
            if (qual[i] > max_value) {
              qual[i] = max_value;
            } else if (qual[i] < min_value) {
              qual[i] = min_value;
            }
          }

          return Qnil;
        }
      }

      builder.c %{
        VALUE qual_convert_C(
          VALUE _qual,
          VALUE _qual_len,
          VALUE _value
        )
        {
          unsigned char *qual     = (unsigned char *) StringValuePtr(_qual);
          unsigned int   qual_len = FIX2UINT(_qual_len);
          unsigned int   value    = FIX2UINT(_value);
          unsigned int   i        = 0;

          for (i = 0; i < qual_len; i++)
          {
            qual[i] += value;
          }

          return Qnil;
        }
      }

      builder.c %{
        VALUE scores_mean_local_C(
          VALUE _qual,
          VALUE _qual_len,
          VALUE _score_base,
          VALUE _window_size
        )
        {
          unsigned char *qual        = (unsigned char *) StringValuePtr(_qual);
          unsigned int   qual_len    = FIX2UINT(_qual_len);
          unsigned int   score_base  = FIX2UINT(_score_base);
          unsigned int   window_size = FIX2UINT(_window_size);
          unsigned int   sum         = 0;
          unsigned int   i           = 0;
          float          mean        = 0.0;
          float          new_mean    = 0.0;

          // fill window
          for (i = 0; i < window_size; i++)
            sum += qual[i] - score_base;

          mean = sum / window_size;

          // run window across the rest of the scores
          while (i < qual_len)
          {
            sum += qual[i] - score_base;
            sum -= qual[i - window_size] - score_base;

            new_mean = sum / window_size;

            if (new_mean < mean)
              mean = new_mean;

            i++;
          }

          return rb_float_new(mean);
        }
      }
    end
  end
end

__END__
