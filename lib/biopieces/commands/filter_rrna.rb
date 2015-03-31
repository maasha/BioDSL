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
    # == Filter rRNA sequences from the stream.
    # 
    # Description
    # 
    # +filter_rrna+ utilizes +sortmerna+ to identify and filter ribosomal RNA
    # sequences from the stream. The +sortmerna+ and +indexdb_rna+ executables
    # must be installed for +filter_rrna+ to work.
    #
    # Indexed reference files are produced using +indexdb_rna+.
    # 
    # For more about the sortmerna look here:
    # 
    # http://bioinfo.lifl.fr/RNA/sortmerna/
    # 
    # == Usage
    #    filter_rrna(ref_fasta: <file(s)>, ref_index: <file(s)>)
    #
    # === Options
    # * ref_fasta <file(s)> - One or more reference FASTA files.
    # * ref_index <file(s)> - One or more index reference files.
    # 
    # == Examples
    # 
    # To filter all reads matching the SILVA archaea 23S rRNA do:
    # 
    #    BP.new.
    #    read_fastq(input: "reads.fq").
    #    filter_rrna(ref_fasta: ["silva-arc-23s-id98.fasta"],
    #                ref_index: ["silva-arc-23s-id98.fasta.idx*"]).
    #    write_fastq(output: "clean.fq").
    #    run
    #
    def filter_rrna(options = {})
      require 'set'

      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :ref_fasta, :ref_index)
      options_files_exist(options, :ref_fasta, :ref_index)

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:sequences_in] = 0
          status[:residues_in]  = 0

          Dir.mktmpdir do |tmp_dir|
            names_hash = {}

            tmp_file = File.join(tmp_dir, 'tmp_file')
            seq_file = File.join(tmp_dir, 'seq_file')
            out_file = File.join(tmp_dir, 'out_file')

            BioPieces::Fasta.open(seq_file, 'w') do |seq_io|
              File.open(tmp_file, 'wb') do |tmp_ios|
                BioPieces::Serializer.new(tmp_ios) do |s|
                  input.each_with_index do |record, i|
                    status[:records_in] += 1

                    s << record

                    if record.key? :SEQ
                      entry = BioPieces::Seq.new_bp(record)
                      entry.seq_name = i
                      names_hash[i]  = record[:SEQ_NAME] || i
                      seq_io << entry.to_fasta 
                      status[:sequences_in] += 1
                      status[:residues_in]  += entry.length
                    end
                  end
                end
              end
            end

            # fasta1,id1:fasta2,id2:...
            ref_files = options[:ref_fasta].zip(options[:ref_index]).map { |m| m.join(',') }.join(':')

            cmd = []
            cmd << 'sortmerna'
            cmd << "--ref #{ref_files}"
            cmd << "--reads #{seq_file}"
            cmd << "--aligned #{out_file}"
            cmd << '--fastx'
            cmd << '-v 1' if BioPieces::verbose

            system(cmd.join(' '))

            raise "command failed: #{cmd.join( ' ')}" unless $?.success?

            BioPieces::Fasta.open(out_file, 'r') do |ios|
              ios.each do |entry|
                filter << entry.seq_name.to_i
              end
            end

            File.open(file, 'rb') do |ios|
              BioPieces::Serializer.new(ios) do |s|
                s.each_with_index do |record, i|
                  if record.key? :SEQ
                    unless filter.include? names_hash[i]
                      output << record
                      status[:records_out] += 1
                      status[:sequences_out] += 1
                      status[:residues_out]  += entry.length
                    end
                  else
                    output << record
                    status[:records_out] += 1
                  end
                end
              end
            end
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

