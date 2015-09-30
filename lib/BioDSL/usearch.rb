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
# This software is part of BioDSL (www.github.com/maasha/BioDSL).              #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

# Namespace for BioDSL.
module BioDSL
  # Error class for all exceptions to do with Usearch.
  class UsearchError < StandardError; end

  # rubocop: disable ClassLength

  # Class with methods to execute Usearch and parse the results.
  class Usearch
    include Enumerable

    # Execute cluster_smallmem.
    #
    # @param options [Hash] Options Hash
    # @option options [String] :input
    # @option options [String] :output
    # @option options [String] :database
    # @option options [Float] :identity
    # @option options [Fixnum] :cpus
    # @option options [String] :strand
    def self.cluster_smallmem(options)
      usearch = new(options)
      usearch.cluster_smallmem
    end

    # Execute cluster_otus.
    #
    # @param options [Hash] Options Hash
    # @option options [String] :input
    # @option options [String] :output
    # @option options [String] :database
    # @option options [Float] :identity
    # @option options [Fixnum] :cpus
    # @option options [String] :strand
    def self.cluster_otus(options)
      usearch = new(options)
      usearch.cluster_otus
    end

    # Execute uchime_ref.
    #
    # @param options [Hash] Options Hash
    # @option options [String] :input
    # @option options [String] :output
    # @option options [String] :database
    # @option options [Float] :identity
    # @option options [Fixnum] :cpus
    # @option options [String] :strand
    def self.uchime_ref(options)
      usearch = new(options)
      usearch.uchime_ref
    end

    # Execute usearch_local.
    #
    # @param options [Hash] Options Hash
    # @option options [String] :input
    # @option options [String] :output
    # @option options [String] :database
    # @option options [Float] :identity
    # @option options [Fixnum] :cpus
    # @option options [String] :strand
    def self.usearch_global(options)
      usearch = new(options)
      usearch.usearch_global
    end

    # Execute usearch_local.
    #
    # @param options [Hash] Options Hash
    # @option options [String] :input
    # @option options [String] :output
    # @option options [String] :database
    # @option options [Float] :identity
    # @option options [Fixnum] :cpus
    # @option options [String] :strand
    def self.usearch_local(options)
      usearch = new(options)
      usearch.usearch_local
    end

    # Open a Usearch file.
    #
    # @param [Array] List of open arguments.
    #
    # @yield [IO] stream.
    # @return [IO] stream.
    def self.open(*args)
      ios = IO.open(*args)

      if block_given?
        yield ios
      else
        return ios
      end
    end

    # Constructor for Usearch class.
    #
    # @param options [Hash] Options Hash
    # @option options [String] :input
    # @option options [String] :output
    # @option options [String] :database
    # @option options [Float] :identity
    # @option options [Fixnum] :cpus
    # @option options [String] :strand
    #
    # @return [Usearch] Class instance.
    def initialize(options)
      @options = options
      @stderr  = nil

      return self unless File.size(@options[:input]) == 0

      fail UsearchError, %(Empty input file -> "#{@options[:input]}")
    end

    # Combose a command list and execute cluster_smallmem with this.
    #
    # @return [self]
    def cluster_smallmem
      command = []
      command << 'usearch'
      command << "-cluster_smallmem #{@options[:input]}"
      command << "-id #{@options[:identity]}"
      command << "-threads #{@options[:cpus]}" if @options[:cpus]
      command << "-strand #{@options[:strand]}"

      if @options[:align]
        command << "-msaout #{@options[:output]}"
      else
        command << "-uc #{@options[:output]}"
      end

      execute(command)

      self
    end

    # Combose a command list and execute cluster_otus with this.
    #
    # @return [self]
    def cluster_otus
      command = []
      command << 'usearch'
      command << "-cluster_otus #{@options[:input]}"
      command << "-otus #{@options[:output]}"
      command << "-id #{@options[:identity]}"
      command << "-threads #{@options[:cpus]}" if @options[:cpus]

      execute(command)

      self
    end

    # Combose a command list and execute uchime_ref with this.
    #
    # @return [self]
    def uchime_ref
      command = []
      command << 'usearch'
      command << "-uchime_ref #{@options[:input]}"
      command << "-db #{@options[:database]}"
      command << "-strand #{@options[:strand]}"
      command << "-threads #{@options[:cpus]}" if @options[:cpus]
      command << "-nonchimeras #{@options[:output]}"

      execute(command)

      self
    end

    # Combose a command list and execute usearch_global with this.
    #
    # @return [self]
    def usearch_global
      command = []
      command << 'usearch'
      command << '-notrunclabels'
      command << "-usearch_global #{@options[:input]}"
      command << "-db #{@options[:database]}"
      command << "-strand #{@options[:strand]}" if @options[:strand]
      command << "-threads #{@options[:cpus]}"  if @options[:cpus]
      command << "-id #{@options[:identity]}"
      command << "-uc #{@options[:output]}"

      execute(command)

      self
    end

    # Combose a command list and execute usearch_local with this.
    #
    # @return [self]
    def usearch_local
      command = []
      command << 'usearch'
      command << '-notrunclabels'
      command << "-usearch_local #{@options[:input]}"
      command << "-db #{@options[:database]}"
      command << "-strand #{@options[:strand]}" if @options[:strand]
      command << "-threads #{@options[:cpus]}"  if @options[:cpus]
      command << "-id #{@options[:identity]}"
      command << "-uc #{@options[:output]}"

      execute(command)

      self
    end

    private

    # Execute Usearch on a given command.
    #
    # @param command [Array] Usearch command list.
    def execute(command)
      command << '--quiet' unless @options[:verbose]
      command_str = command.join(' ')

      $stderr.puts "Running command: #{command_str}" if @options[:verbose]

      Open3.popen3(command_str) do |_stdin, _stdout, stderr, wait_thr|
        @stderr = stderr.read.split $INPUT_RECORD_SEPARATOR
        exit_status = wait_thr.value # Process::Status object returned.

        unless exit_status.success?
          # TODO: write error message to log.
          fail UsearchError, "Command failed: #{command_str} + \
            #{@stderr.join $INPUT_RECORD_SEPARATOR}"
        end
      end
    end

    # Class for Usearch IO.
    class IO < Filesys
      # Parse a given type of Uclust format and yield the result.
      #
      # @param format [Symbol] Format type to parse.
      def each(format = :uc)
        case format
        when :uc then each_uc { |e| yield e }
        else
          fail UsearchError, "Unknown iterator format: #{format}"
        end
      end

      # rubocop: disable Metrics/AbcSize

      # Parse each UC type record and yield the result.
      #
      # @yield [Hash] BioDSL record with UC result.
      def each_uc
        @io.each do |line|
          fields = line.chomp.split("\t")
          record = {TYPE:    fields[0],
                    CLUSTER: fields[1].to_i}

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
    end
  end
end
