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
    # == Create taxonomy index from sequences in the stream.
    # 
    # Use the +usearch+ program index_taxonomy to cluster sequences in the stream
    # 
    # == Usage
    # 
    #    index_taxonomy(<output_dir: <dir>>[, prefix: <string>[, force: <bool>]])
    # 
    # === Options
    #
    #  * output_dir: <dir> - Output directory to contain index files.
    #  * prefix: <string>  - Prefix to use with index file names (default="taxonomy").
    #  * force: <bool>     - Force overwrite existing index files.
    #
    # == Examples
    #
    # To create OTU clusters do:
    #
    def index_taxonomy(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :output_dir, :prefix, :force)
      options_required(options, :output_dir)
      options_allowed_values(options, force: [nil, true, false])
      options_files_exists_force(options, :report)

      FileUtils.mkdir_p(options[:output_dir]) unless File.exist?(options[:output_dir])

      options[:prefix] ||= "taxonomy"

      unless options[:force]
        files = [
          File.join(options[:output_dir], "#{options[:prefix]}_node2oligos.tch"),
          File.join(options[:output_dir], "#{options[:prefix]}_taxtree.tch"),
          File.join(options[:output_dir], "#{options[:prefix]}_k_oligo2nodes.tch"),
          File.join(options[:output_dir], "#{options[:prefix]}_p_oligo2nodes.tch"),
          File.join(options[:output_dir], "#{options[:prefix]}_c_oligo2nodes.tch"),
          File.join(options[:output_dir], "#{options[:prefix]}_o_oligo2nodes.tch"),
          File.join(options[:output_dir], "#{options[:prefix]}_f_oligo2nodes.tch"),
          File.join(options[:output_dir], "#{options[:prefix]}_g_oligo2nodes.tch"),
          File.join(options[:output_dir], "#{options[:prefix]}_s_oligo2nodes.tch"),
        ]

        files.each do |file|
          raise BioPieces::OptionError, "File exists: #{file} - use 'force: true' to override" if File.exist? file
        end
      end

      lmb = lambda do |input, output, status|
        status[:sequences_in] = 0

        status_track(status) do
          index = BioPieces::Taxonomy::Index.new(options)

          input.each do |record|
            status[:records_in] += 1

            if record[:SEQ_NAME] and record[:SEQ]
              status[:sequences_in] += 1

              index.add(BioPieces::Seq.new(seq_name: seq_name, seq: record[:SEQ]))
            end

            output << record
            status[:records_out] += 1
          end

          index.save
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

