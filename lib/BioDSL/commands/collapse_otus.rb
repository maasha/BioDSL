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
# This software is part of the BioDSL framework (www.BioDSL.org).        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioDSL
  # == Collapse OTUs based on identicial taxonomy strings.
  #
  # +collapse_otus+ collapses OTUs in OTU style records if the TAXONOMY string
  # is redundant. At the same time the sample counts (+_COUNT+) is incremented
  # the collapsed OTUs.
  #
  # == Usage
  #
  #    collapse_otus
  #
  # === Options
  #
  # == Examples
  #
  # Here is an OTU table with four rows, one of which has a redundant Taxonomy
  # string:
  #
  #    BD.new.read_table(input: "otu_table.txt").dump.run
  #
  #    {:OTU=>"OTU_1",
  #     :CM1_COUNT=>881,
  #     :CM10_COUNT=>234,
  #     :TAXONOMY=>
  #      "Bacteria(100);Firmicutes(100);Bacilli(100);Lactobacillales(100); \
  #      Leuconostocaceae(100);Leuconostoc(100)"}
  #    {:OTU=>"OTU_0",
  #     :CM1_COUNT=>3352,
  #     :CM10_COUNT=>4329,
  #     :TAXONOMY=>
  #      "Bacteria(100);Firmicutes(100);Bacilli(100);Lactobacillales(100); \
  #      Streptococcaceae(100);Lactococcus(100)"}
  #    {:OTU=>"OTU_5",
  #     :CM1_COUNT=>5,
  #     :CM10_COUNT=>0,
  #     :TAXONOMY=>
  #      "Bacteria(100);Proteobacteria(100);Gammaproteobacteria(100); \
  #      Pseudomonadales(100);Pseudomonadaceae(100);Pseudomonas(100)"}
  #    {:OTU=>"OTU_3",
  #     :CM1_COUNT=>228,
  #     :CM10_COUNT=>200,
  #     :TAXONOMY=>
  #      "Bacteria(100);Firmicutes(100);Bacilli(100);Lactobacillales(100); \
  #      Streptococcaceae(100);Lactococcus(100)"}
  #
  # In order to collapse the redudant OTU simply run the stream through
  # +collapse_otus+:
  #
  #    BD.new.read_table(input: "otu_table.txt").collapse_otus.dump.run
  #
  #    {:OTU=>"OTU_1",
  #     :CM1_COUNT=>881,
  #     :CM10_COUNT=>234,
  #     :TAXONOMY=>
  #      "Bacteria(100);Firmicutes(100);Bacilli(100);Lactobacillales(100); \
  #      Leuconostocaceae(100);Leuconostoc(100)"}
  #    {:OTU=>"OTU_0",
  #     :CM1_COUNT=>3580,
  #     :CM10_COUNT=>4529,
  #     :TAXONOMY=>
  #      "Bacteria(100);Firmicutes(100);Bacilli(100);Lactobacillales(100); \
  #      Streptococcaceae(100);Lactococcus(100)"}
  #    {:OTU=>"OTU_5",
  #     :CM1_COUNT=>5,
  #     :CM10_COUNT=>0,
  #     :TAXONOMY=>
  #      "Bacteria(100);Proteobacteria(100);Gammaproteobacteria(100); \
  #      Pseudomonadales(100);Pseudomonadaceae(100);Pseudomonas(100)"}
  class CollapseOtus
    STATS = %i(records_in records_out otus_in otus_out)

    # Constructor for CollapseOtus.
    #
    # @param options [Hash] Options Hash.
    def initialize(options)
      @options = options

      check_options
    end

    # Return the CollapseOtus command lambda.
    #
    # @return [Proc] Lambda for the command.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        hash = {}

        input.each do |record|
          @status[:records_in] += 1

          if record[:TAXONOMY]
            @status[:otus_in] += 1

            collapse_tax(hash, record)
          else
            output << record
            @status[:records_out] += 1
          end
        end

        write_tax(hash, output)
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, nil)
    end

    # Collapse identical taxonomies by removing duplicates and adding their
    # counts.
    #
    # @param hash [Hash] Hash with taxonomy records.
    # @param record [Hash] BioDSL record with taxonomy info.
    def collapse_tax(hash, record)
      key = record[:TAXONOMY].gsub(/\(\d+\)/, '').to_sym

      if hash.key? key
        record.each do |k, v|
          hash[key][k] += v if k[-6..-1] == '_COUNT'
        end
      else
        hash[key] = record
      end
    end

    # Output collapsed taxonomy records.
    #
    # @param hash [Hash] Hash with taxonomy records.
    # @param output [Enumerator::Yielder] Output stream.
    def write_tax(hash, output)
      hash.each_value do |record|
        output << record
        @status[:otus_out]    += 1
        @status[:records_out] += 1
      end
    end
  end
end
