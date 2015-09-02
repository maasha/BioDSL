# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
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
# This software is part of Biopieces (www.biopieces.org).                      #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
module BioPieces
  # Error class for Mummer errors.
  MummerError = Class.new(StandardError)

  # Class for executing MUMmer and parsing MUMmer results.
  class Mummer
    # @param seq1    [BioPieces::Seq] Sequence 1.
    # @param seq2    [BioPeices::Seq] Sequence 2.
    # @param options [Hash]           Options hash.
    #
    # @yield [Mummer::Match] A match object
    # @return [Enumerable] An Enumerable
    def self.each_mem(seq1, seq2, options = {})
      mummer = new(seq1, seq2, options)

      return to_enum :each unless block_given?

      mummer.each_mem { |mem| yield mem }
    end

    # Constructor for Mummer class.
    #
    # @param seq1    [BioPieces::Seq] Sequence 1.
    # @param seq2    [BioPeices::Seq] Sequence 2.
    # @param options [Hash]           Options hash.
    #
    # @return [Mummer] Class instance.
    def initialize(seq1, seq2, options = {})
      @seq1    = seq1
      @seq2    = seq2
      @options = options
      @command = []
      @q_id    = nil
      @dir     = nil


      default_options
    end

    # @yield [Mummer::Match] A match object
    # @return [Enumerable] An Enumerable
    def each_mem
      return to_enum :each unless block_given?

      TmpDir.create('in1', 'in2', 'out') do |file_in1, file_in2, file_out|
        BioPieces::Fasta.open(file_in1, 'w') { |io| io.puts @seq1.to_fasta }
        BioPieces::Fasta.open(file_in2, 'w') { |io| io.puts @seq2.to_fasta }

        execute(file_in1, file_in2, file_out)

        File.open(file_out) do |io|
          while (match = get_match(io))
            yield match
          end
        end
      end
    end

    private

    def get_match(io)
      io.each do |line|
        line.chomp!

        case line
        when /^> (\S+)\s+Reverse\s+Len = \d+$/
          @q_id  = Regexp.last_match(1)
          @dir   = 'reverse'
        when /^> (\S+)\s+Len = \d+$/
          @q_id  = Regexp.last_match(1)
          @dir   = 'forward'
        when /^\s*(.\S+)\s+(\d+)\s+(\d+)\s+(\d+)$/
          s_id    = Regexp.last_match(1)
          s_beg   = Regexp.last_match(2).to_i - 1
          q_beg   = Regexp.last_match(3).to_i - 1
          hit_len = Regexp.last_match(4).to_i

          return Match.new(@q_id, s_id, @dir, s_beg, q_beg, hit_len)
        end
      end

      nil
    end

    # Set some sensible default options.
    def default_options
      @options[:length_min] ||= 20
      @options[:direction]  ||= :both
    end

    # Execute MUMmer.
    #
    # @param file_in1 [String] Path to sequence filen.
    # @param file_in1 [String] Path to sequence filen.
    # @param file_out [String] Path to output file.
    def execute(file_in1, file_in2, file_out)
      cmd = compile_command(file_in1, file_in2, file_out)

      $stderr.puts "Running command: #{cmd}" if BioPieces.verbose

      system(cmd)

      fail "Error running command: #{cmd}" unless $CHILD_STATUS.success?
    end

    # Compile a command for execution of mummer.
    #
    # @param file_in1 [String] Path to sequence filen.
    # @param file_in1 [String] Path to sequence filen.
    # @param file_out [String] Path to output file.
    #
    # @return [String] Command string.
    def compile_command(file_in1, file_in2, file_out)
      @command << 'mummer'
      @command << '-c' # report position of revcomp match relative to query seq.
      @command << '-L' # show length of query seq in header.
      @command << '-F' # force 4-column output.
      @command << "-l #{@options[:length_min]}"
      @command << '-n' # nucleotides only [atcg].

      case @options[:direction]
      when :reverse then @command << '-r' # only compute reverse matches.
      when :both    then @command << '-b' # compute forward and reverse matches.
      end

      @command << file_in1
      @command << file_in2
      @command << "> #{file_out}"
      @command << '2>&1' unless BioPieces.verbose

      @command.join(' ')
    end

    Match = Struct.new(:q_id, :s_id, :dir, :q_beg, :s_beg, :hit_len) do
      def q_end
        q_beg + hit_len - 1
      end

      def s_end
        s_beg + hit_len - 1
      end
    end
  end
end
