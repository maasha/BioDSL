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
  module Commands
    # Class returning the lambda for the filter_rrna command.
    class AssembleSeqIdba
      include StatusHelper

      def self.run(options = {})
        lambda do |input, output, status|
          new(input, output, status, options).run
        end
      end

      def initialize(input, output, status, options)
        @input   = input
        @output  = output
        @status  = status
        @options = options
      end

      def run
        status_track(@status) do
          in_tmp_dir do |fasta_in, fasta_out, tmp_dir|
            status_init
            process_input(fasta_in)
            execute_idba(fasta_in, tmp_dir)
            lengths = process_output(fasta_out)
            status_term(lengths)
          end
        end
      end

      private

      def in_tmp_dir(&block)
        fail "No block given" unless block

        Dir.mktmpdir do |tmp_dir|
          fasta_in  = File.join(tmp_dir, 'reads.fna')
          fasta_out = File.join(tmp_dir, 'contig.fa')

          block.call(fasta_in, fasta_out, tmp_dir)
        end
      end

      def process_input(fasta_in)
        BioPieces::Fasta.open(fasta_in, 'w') do |fasta_io|
          @input.each do |record|
            @status[:records_in] += 1

            if record and record.key? :SEQ
              entry = BioPieces::Seq.new_bp(record)

              @status[:sequences_in] += 1
              @status[:residues_in]  += entry.length

              fasta_io.puts entry.to_fasta
            else
              status[:records_out]   += 1
              output.puts record
            end
          end
        end
      end

      def process_output(fasta_out)
        lengths = []

        BioPieces::Fasta.open(fasta_out, 'r') do |ios|
          ios.each do |entry|
            @output << entry.to_bp
            @status[:records_out]   += 1
            @status[:sequences_out] += 1
            @status[:residues_out]  += entry.length

            lengths << entry.length
          end
        end

        lengths.sort!
        lengths.reverse!

        lengths
      end

      def status_init
        @status[:sequences_in]  = 0
        @status[:sequences_out] = 0
        @status[:residues_in]   = 0
        @status[:residues_out]  = 0
      end

      def status_term(lengths)
        status[:contig_max] = lengths.first
        status[:contig_min] = lengths.last

        count = 0

        lengths.each do |length|
          count += length

          if count >= status[:residues_out] * 0.50
            status[:contig_n50] = length
            break
          end
        end
      end

      def execute_idba(fasta_in, tmp_dir)
        cmd = []
        cmd << 'idba_ud'
        cmd << "--read #{fasta_in}"
        cmd << "--out #{tmp_dir}"
        cmd << "--mink #{@options[:kmer_min]}"
        cmd << "--maxk #{@options[:kmer_max]}"
        cmd << "--num_threads #{@options[:cpus]}"
        cmd << "> /dev/null 2>&1" unless BioPieces.verbose

        cmd_line = cmd.join(' ')

        $stderr.puts "Running: #{cmd_line}" if BioPieces.verbose
        system(cmd_line)

        fail cmd_line unless $?.success?
      end
    end
  end
end
