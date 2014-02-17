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
# This software is part of the Biopieces framework (www.biopieces.org).          #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  module WriteFasta
    # Method to write FASTA entries to stdout or file.
    def write_fasta
      options_allowed :output, :wrap, :gzip, :bzip2
      options_unique :gzip, :bzip2
      options_tie gzip: :output, bzip2: :output
      options_default output: $stdout

      if @options[:output] === $stdout
        @input.each do |record|
          if record[:SEQ_NAME] and record[:SEQ]
            entry = BioPieces::Seq.new_bp(record)

            $stdout.puts entry.to_fasta(@options[:wrap])
          end

          @output.write record if @output
        end
      else
        if @options[:gzip]
          compress = :gzip
        elsif @options[:bzip2]
          compress = :bzip2
        else
          compress = nil
        end

        Fasta.open(@options[:output], 'w', compress: compress) do |ios|
          @input.each do |record|
            if record[:SEQ_NAME] and record[:SEQ]
              entry = BioPieces::Seq.new_bp(record)

              ios.puts entry.to_fasta(@options[:wrap])
            end

            @output.write record if @output
          end
        end
      end
    end
  end
end

