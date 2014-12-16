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
  module Commands
    # == Write OTU tabular data to a biom-format file.
    # 
    # +write_biom+ outputs to file OTU data in biom-format (currently JSON).
    # Records must contain +OTU+ and +TAXONOMY+ keys.
    #
    # biom must be installed for +write_biom+ to work. See more here:
    #
    # http://biom-format.org/
    # 
    # == Usage
    #    write_biom(<output: <file>>[, force: <bool>])
    #
    # === Options
    # * output <file> - Output file.
    # * force <bool>  - Force overwrite existing output file.
    # 
    # == Examples
    #
    # To convert an OTU table to BIOM json format do:
    #
    #    BP.new.read_table(input: "otu.tab").write_biom(output: "otu.json").run
    def write_biom(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :output, :force)
      options_required(options, :output)
      options_allowed_values(options, force: [nil, true, false])
      options_files_exists_force(options, :output)

      lmb = lambda do |input, output, status|
        header = false

        tmp_file = Tempfile.new("biom")

        begin
          status_track(status) do
            File.open(tmp_file, 'w') do |ios|
              input.each do |record|
                status[:records_in] += 1

                if record[:OTU] and record[:TAXONOMY]
                  otu_record = record.reject { |key, value| key == :RECORD_TYPE }

                  unless header
                    ios.puts "#" + otu_record.keys.join("\t").sub(/TAXONOMY/, "taxonomy")
                    header = true
                  end

                  ios.puts otu_record.values.join("\t")
                end

                if output
                  output << record
                  status[:records_out] += 1
                end
              end
            end

            if options[:force] and File.exist? options[:output]
              File.unlink options[:output]
            end

            if $VERBOSE
              system(%Q{biom convert -i #{tmp_file.path} -o #{options[:output]} --table-type="OTU table" --to-json})
            else
              system(%Q{biom convert -i #{tmp_file.path} -o #{options[:output]} --table-type="OTU table" --to-json > /dev/null 2>&1})
            end

            raise "biom convert failed" unless $?.success?
          end
        ensure
          tmp_file.unlink
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

