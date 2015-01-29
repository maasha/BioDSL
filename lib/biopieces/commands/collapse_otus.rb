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
    # == Collapse OTUs based on identicial taxonomy strings.
    # 
    # +collapse_otus+ collapses OTUs in OTU style records if the TAXONOMY
    # string is redundant. At the same time the sample counts (+_COUNT+)
    # is incremented the collapsed OTUs.
    #
    # == Usage
    # 
    #    collapse_otus()
    #
    # === Options
    #
    # == Examples
    #
    # Here is an OTU table with four rows, one of which has a redundant Taxonomy string:
    #    
    #    BP.new.read_table(input: "otu_table.txt").dump.run
    #
    #    {:OTU=>"OTU_1",
    #     :CM1_COUNT=>881,
    #     :CM10_COUNT=>234,
    #     :TAXONOMY=>
    #      "Bacteria(100);Firmicutes(100);Bacilli(100);Lactobacillales(100);Leuconostocaceae(100);Leuconostoc(100)"}
    #    {:OTU=>"OTU_0",
    #     :CM1_COUNT=>3352,
    #     :CM10_COUNT=>4329,
    #     :TAXONOMY=>
    #      "Bacteria(100);Firmicutes(100);Bacilli(100);Lactobacillales(100);Streptococcaceae(100);Lactococcus(100)"}
    #    {:OTU=>"OTU_5",
    #     :CM1_COUNT=>5,
    #     :CM10_COUNT=>0,
    #     :TAXONOMY=>
    #      "Bacteria(100);Proteobacteria(100);Gammaproteobacteria(100);Pseudomonadales(100);Pseudomonadaceae(100);Pseudomonas(100)"}
    #    {:OTU=>"OTU_3",
    #     :CM1_COUNT=>228,
    #     :CM10_COUNT=>200,
    #     :TAXONOMY=>
    #      "Bacteria(100);Firmicutes(100);Bacilli(100);Lactobacillales(100);Streptococcaceae(100);Lactococcus(100)"}
    #
    # In order to collapse the redudant OTU simply run the stream through +collapse_otus+:
    #
    #    BP.new.read_table(input: "otu_table.txt").collapse_otus.dump.run
    #
    #    {:OTU=>"OTU_1",
    #     :CM1_COUNT=>881,
    #     :CM10_COUNT=>234,
    #     :TAXONOMY=>
    #      "Bacteria(100);Firmicutes(100);Bacilli(100);Lactobacillales(100);Leuconostocaceae(100);Leuconostoc(100)"}
    #    {:OTU=>"OTU_0",
    #     :CM1_COUNT=>3580,
    #     :CM10_COUNT=>4529,
    #     :TAXONOMY=>
    #      "Bacteria(100);Firmicutes(100);Bacilli(100);Lactobacillales(100);Streptococcaceae(100);Lactococcus(100)"}
    #    {:OTU=>"OTU_5",
    #     :CM1_COUNT=>5,
    #     :CM10_COUNT=>0,
    #     :TAXONOMY=>
    #      "Bacteria(100);Proteobacteria(100);Gammaproteobacteria(100);Pseudomonadales(100);Pseudomonadaceae(100);Pseudomonas(100)"}
    def collapse_otus(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :output, :force)
      options_allowed_values(options, force: [true, false, nil])
      options_files_exists_force(options, :output)

      lmb = lambda do |input, output, status|
        status[:otus_in]  = 0
        status[:otus_out] = 0
        hash = {}

        status_track(status) do
          input.each do |record|
            status[:records_in] += 1

            if record[:TAXONOMY]
              status[:otus_in] += 1

              key = record[:TAXONOMY].gsub(/\(\d+\)/, '').to_sym

              if hash.has_key? key
                record.each do |k, v|
                  if k =~ /_COUNT$/
                    hash[key][k] += v
                  end
                end
              else
                hash[key] = record
              end
            else
              output << record
              status[:records_out] += 1
            end
          end

          hash.each_value do |record|
            output << record
            status[:otus_out]    += 1
            status[:records_out] += 1
          end

          status[:otus_delta]         = status[:otus_out] - status[:otus_in]
          status[:otus_delta_percent] = (100 * status[:otus_delta].to_f / status[:otus_in]).round(2)
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

