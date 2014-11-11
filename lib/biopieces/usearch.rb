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
# This software is part of Biopieces (www.biopieces.org).                        #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  # Error class for all exceptions to do with Usearch.
  class UsearchError < StandardError; end

  class Usearch
    include Enumerable

    def self.cluster_otus(options)
      usearch = self.new(options)
      usearch.cluster_otus
    end

    def self.uchime_ref(options)
      usearch = self.new(options)
      usearch.uchime_ref
    end

    def self.usearch_global(options)
      usearch = self.new(options)
      usearch.usearch_global
    end

    def self.open(*args)
      ios = IO.open(*args)

      if block_given?
        yield ios
      else
        return ios
      end
    end

    def initialize(options)
      @options = options
      @stderr  = nil

      if File.size(@options[:input]) == 0
        raise UsearchError, %{Empty input file -> "#{@options[:input].path}"}
      end
    end

    def cluster_otus
      command = []
      command << "usearch"
      command << "-cluster_otus #{@options[:input].path}"
      command << "-otus #{@options[:output].path}"
      #command << "-otuid #{@options[:identity]}"
      command << "-threads #{@options[:cpus]}" if @options[:cpus]

      execute(command)

      self
    end

    def uchime_ref
      command = []
      command << "usearch"
      command << "-uchime_ref #{@options[:input].path}"
      command << "-db #{@options[:database]}"
      command << "-strand #{@options[:strand]}"
      command << "-threads #{@options[:cpus]}" if @options[:cpus]
      command << "-nonchimeras #{@options[:output].path}"

      execute(command)

      self
    end

    def usearch_global
      command = []
      command << "usearch"
      command << "-usearch_global #{@options[:input].path}"
      command << "-db #{@options[:database]}"
      command << "-strand #{@options[:strand]}" if @options[:strand]
      command << "-threads #{@options[:cpus]}"  if @options[:cpus]
      command << "-id #{@options[:identity]}"
      command << "-uc #{@options[:output].path}"

      execute(command)

      self
    end
    
    private

    def execute(command)
      command << "--quiet" unless @options[:verbose]
      command_str = command.join(" ")
   
      $stderr.puts "Running command: #{command_str}" if @options[:verbose]

      Open3.popen3(command_str) do |stdin, stdout, stderr, wait_thr|
        @stderr = stderr.read.split $/
        exit_status = wait_thr.value # Process::Status object returned.

        unless exit_status.success?
          # TODO write error message to log.
          raise UsearchError, "Command failed: #{command_str} + #{@stderr.join $/}"
        end
      end
    end

    class IO < Filesys
      def each(format = :uc)
        case format
        when :uc then self.each_uc { |e| yield e }
        when :cluster
        when :alignment
        end
      end

      def each_uc
        @io.each do |line|
          fields = line.chomp.split("\t")
          record = {}

          record[:TYPE]    = fields[0]
          record[:CLUSTER] = fields[1].to_i

          case fields[0]
          when 'C' then record[:CLUSTER_SIZE] = fields[2].to_i
          else          record[:SEQ_LEN]      = fields[2].to_i
          end

          record[:IDENT]  = fields[3].to_f if fields[0] == 'H'
          record[:STRAND] = fields[4]
          record[:CIGAR]  = fields[7]
          record[:Q_ID]   = fields[8]
          record[:S_ID]   = fields[9] if fields[0] == 'H'

          yield record
        end
      end

      # Method to parse a Uclust .uc file and for each line of data
      # yield a Biopiece record.
      def each_cluster
        record = {}

        File.open(@outfile, "r") do |ios|
          ios.each_line do |line|
            if line !~ /^#/
              fields = line.chomp.split("\t")

              next if fields[0] == 'C'

              record[:TYPE]     = fields[0]
              record[:CLUSTER]  = fields[1].to_i
              record[:IDENT]    = fields[3].to_f
              record[:Q_ID]     = fields[8]

              yield record
            end
          end
        end

        self
      end

      # Method to parse a Useach user defined tabular file and for each line of data
      # yield a Biopiece record.
      def each_hit
        record = {}

        File.open(@outfile, "r") do |ios|
          ios.each_line do |line|
            fields = line.chomp.split("\t")
            record[:REC_TYPE]   = "USEARCH"
            record[:Q_ID]       = fields[0]
            record[:S_ID]       = fields[1]
            record[:IDENT]      = fields[2].to_f
            record[:ALIGN_LEN]  = fields[3].to_i
            record[:MISMATCHES] = fields[4].to_i
            record[:GAPS]       = fields[5].to_i
            record[:Q_BEG]      = fields[6].to_i - 1
            record[:Q_END]      = fields[7].to_i - 1
            record[:S_BEG]      = fields[8].to_i - 1
            record[:S_END]      = fields[9].to_i - 1
            record[:E_VAL]      = fields[10] == '*' ? '*' : fields[10].to_f
            record[:SCORE]      = fields[11] == '*' ? '*' : fields[11].to_f
            record[:STRAND]     = record[:S_BEG].to_i < record[:S_END].to_i ? '+' : '-'

            record[:S_BEG], record[:S_END] = record[:S_END], record[:S_BEG] if record[:STRAND] == '-'

            yield record
          end
        end

        self
      end

      # Method to parse a FASTA file with Ustar alignments and for each alignment
      # yield an Align object.
      def each_alignment
        entries = []

        Fasta.open(@outfile, "r") do |ios|
          ios.each do |entry|
            entry.seq.tr! '+', '-'
            entries << entry

            if entry.seq_name == 'consensus'
              yield Align.new(entries[0 .. -2])
              entries = []
            end
          end
        end

        self
      end
    end

  end
end
