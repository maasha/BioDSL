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
    class FilterRrna
      require 'English'
      require 'set'

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
          in_tmp_dir do |tmp_file, seq_file, out_file|
            status_init
            ref_files = process_ref_files
            process_input(tmp_file, seq_file)
            execute_sortmerna(ref_files, seq_file, out_file)
            filter = parse_sortme_output(out_file)
            process_output(tmp_file, filter)
            status_term
          end
        end
      end

      private

      def in_tmp_dir(&block)
        fail unless block

        Dir.mktmpdir do |tmp_dir|
          tmp_file = File.join(tmp_dir, 'tmp_file')
          seq_file = File.join(tmp_dir, 'seq_file')
          out_file = File.join(tmp_dir, 'out_file')

          block.call(tmp_file, seq_file, out_file)
        end
      end

      def status_init
        @status[:sequences_in]  = 0
        @status[:sequences_out] = 0
        @status[:residues_in]   = 0
        @status[:residues_out]  = 0
      end

      def status_term
        seq_in            = @status[:sequences_in]
        res_in            = @status[:residues_in]
        seq_delta         = @status[:sequences_out] - seq_in
        res_delta         = @status[:residues_out]  - res_in
        seq_delta_percent = (100 * seq_delta.to_f / seq_in).round(2)
        res_delta_percent = (100 * res_delta.to_f / res_in).round(2)
        @status[:sequences_delta]         = seq_delta
        @status[:sequences_delta_percent] = seq_delta_percent
        @status[:residues_delta]          = res_delta
        @status[:residues_delta_percent]  = res_delta_percent
      end

      # fasta1,id1:fasta2,id2:...
      def process_ref_files
        ref_index = @options[:ref_index]
        ref_fasta = @options[:ref_fasta]

        if ref_index.is_a? Array
          ref_index.map { |f| f.sub!(/\*$/, '') }
        else
          ref_index.sub!(/\*$/, '')
        end

        ref_fasta = [ref_fasta.split(',')] if ref_fasta.is_a? String
        ref_index = [ref_index.split(',')] if ref_index.is_a? String

        ref_fasta.zip(ref_index).map { |m| m.join(',') }.join(':')
      end

      def execute_sortmerna(ref_files, seq_file, out_file)
        cmd = ['sortmerna']
        cmd << "--ref #{ref_files}"
        cmd << "--reads #{seq_file}"
        cmd << "--aligned #{out_file}"
        cmd << '--fastx'
        cmd << '-v' if BioPieces.verbose

        cmd_line = cmd.join(' ')

        $stderr.puts "Running command: #{cmd_line}" if BioPieces.verbose

        system(cmd_line)

        fail "command failed: #{cmd_line}" unless $CHILD_STATUS.success?
      end

      def parse_sortme_output(out_file)
        filter = Set.new

        BioPieces::Fasta.open("#{out_file}.fasta", 'r') do |ios|
          ios.each do |entry|
            filter << entry.seq_name.to_i
          end
        end

        filter
      end

      def process_input(tmp_file, seq_file)
        BioPieces::Fasta.open(seq_file, 'w') do |seq_io|
          File.open(tmp_file, 'wb') do |tmp_ios|
            BioPieces::Serializer.new(tmp_ios) do |s|
              @input.each_with_index do |record, i|
                @status[:records_in] += 1

                s      << record
                # FIXME: need << method
                seq_io.puts record2entry(record, i).to_fasta if record.key? :SEQ
              end
            end
          end
        end
      end

      def record2entry(record, i)
        entry = BioPieces::Seq.new(seq_name: i, seq: record[:SEQ])
        @status[:sequences_in] += 1
        @status[:residues_in]  += entry.length
        entry
      end

      def process_output(tmp_file, filter)
        File.open(tmp_file, 'rb') do |ios|
          BioPieces::Serializer.new(ios) do |s|
            s.each_with_index do |record, i|
              if record.key? :SEQ
                unless filter.include? i
                  @output << record
                  @status[:records_out]   += 1
                  @status[:sequences_out] += 1
                  @status[:residues_out]  += record[:SEQ].length
                end
              else
                @output << record
                @status[:records_out] += 1
              end
            end
          end
        end
      end
    end
  end
end
