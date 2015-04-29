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
# This software is part of Biopieces (www.biopieces.org).                        #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  # Error class for all exceptions to do with Usearch.
  class UsearchError < StandardError; end

  class Usearch
    include Enumerable

    def self.cluster_smallmem(options)
      usearch = self.new(options)
      usearch.cluster_smallmem
    end

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

    def self.usearch_local(options)
      usearch = self.new(options)
      usearch.usearch_local
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
        raise UsearchError, %{Empty input file -> "#{@options[:input]}"}
      end
    end

    def cluster_smallmem
      command = []
      command << "usearch"
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

    def cluster_otus
      command = []
      command << "usearch"
      command << "-cluster_otus #{@options[:input]}"
      command << "-otus #{@options[:output]}"
      command << "-id #{@options[:identity]}"
      command << "-threads #{@options[:cpus]}" if @options[:cpus]

      execute(command)

      self
    end

    def uchime_ref
      command = []
      command << "usearch"
      command << "-uchime_ref #{@options[:input]}"
      command << "-db #{@options[:database]}"
      command << "-strand #{@options[:strand]}"
      command << "-threads #{@options[:cpus]}" if @options[:cpus]
      command << "-nonchimeras #{@options[:output]}"

      execute(command)

      self
    end

    def usearch_global
      command = []
      command << "usearch"
      command << "-notrunclabels"
      command << "-usearch_global #{@options[:input]}"
      command << "-db #{@options[:database]}"
      command << "-strand #{@options[:strand]}" if @options[:strand]
      command << "-threads #{@options[:cpus]}"  if @options[:cpus]
      command << "-id #{@options[:identity]}"
      command << "-uc #{@options[:output]}"

      execute(command)

      self
    end

    def usearch_local
      command = []
      command << "usearch"
      command << "-notrunclabels"
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
        when :uc then self.each_uc  { |e| yield e }
        else
          raise UsearchError, "Unknown iterator format: #{format}"
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
    end
  end
end
