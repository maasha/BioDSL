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
    # == Classify sequences in the stream.
    # 
    # +classify_seq+ searches sequences in the stream against a pre-indexed
    # (using +index_taxonomy+) database. The database consists a taxonomic tree
    # index and indices for each taxonomic level saved in the following files
    # (here using the prefix "taxonomy"):
    #
    #  * taxonomy_tax_index.dat  - return node for a given node id.
    #  * taxonomy_kmer_index.dat - return list of node ids for a given level and kmer.
    #
    # Each sequence is broken down into unique kmers of a given kmer_size
    # overlapping with a given step_size - see +index_taxonomy+. Now, for each
    # taxonomic level, starting from species all nodes for each kmer is looked
    # up in the database. The nodes containing most kmers are considered hits.
    # If there are no hits at a taxonomic level, we move to the next level.
    # Hits are sorted according to how many kmers matched this particular node
    # and a consensus taxonomy string is determined. Hits are also filtered
    # with the following options:
    #
    #  * hits_max  - Include maximally this number of hits in the consensus.
    #  * best_only - Include only the best scoring hits in the consensus.
    #                That is if a hit consists of 344 kmers out of 345
    #                possible, only hits with 344 kmers are included.
    #  * coverage  - Filter hits based on kmer coverage. If a hit contains
    #                fewer kmers than the total amount of kmers x coverage
    #                it will be filtered.
    #  * consensus - For a number of hits accept consensus at a given level
    #                if within this percentage.
    #
    # The output of +classify_seq+ are sequence type records with the
    # additional keys:
    #  
    #  * TAXONOMY_HITS - The number of hits used in the consensus.
    #  * TAXONOMY      - The taxonomy string.
    #
    # The consensus is determined from a list of taxonomic strings, i.e. the
    # TAXONOMIC_HITS, and is composed of a consensus for each taxonomic level.
    # E.g. for the kingdom level if 60% of the taxonomic strings indicate
    # 'Bacteria' and the consensus is 50% then the consensus for the kingdom
    # level will be reported as 'Bacteria(60)'. If the name at any level
    # consists of multiple words they are treated independently. E.g if we have
    # three taxonomic strings at the species level with the names:
    #
    #   *  Escherichia coli K-12
    #   *  Escherichia coli sp. AC3432
    #   *  Escherichia coli sp. AC1232
    #
    # The corresponding consensus for that level will be reported as
    # 'Escherichia coli sp.(100/100/66)'. The forth word in the last two
    # taxonomy strings (AC3432 and AC1232) have a consensus below 50% and are
    # ignored.
    # == Usage
    # 
    #    classify_seq(<dir: <dir>>[, prefix: <string>[, kmer_size: <uint>
    #                 [, step_size: <uint>[, hits_max: <uint>[, consensus: <float>
    #                 [, coverage: <float>[, best_only: <bool>]]]]]]])
    # 
    # === Options
    #
    # * dir:       <dir>    - Directory containing taxonomy files.
    # * prefix:    <string> - Taxonomy files prefix (default="taxonomy").
    # * kmer_size: <uint>   - Kmer size - same used creating the index (default=8).
    # * step_size: <uint>   - Step size (default=1).
    # * hits_max:  <uint>   - Maximum hits to include in consensus (default=50).
    # * consensus: <float>  - Consensus cutoff (default=0.51).
    # * coverage:  <float>  - Coverate cutoff (default=0.9).
    # * best_only: <bool>   - Only use best hits for consensus (default=true).
    #
    # == Examples
    # 
    # To classify a bunch of OTU sequences in the file +otus.fna+ we do:
    #
    #    BP.new.read_fasta(input: "otus.fna").classify_seq(dir: "RDP11_3").write_table(keys: [:SEQ_NAME, :TAXONOMY_HITS, :TAXONOMY]).run
    #    OTU_0  1 K#Bacteria(100);P#Proteobacteria(100);C#Gammaproteobacteria(100);O#Aeromonadales(100);F#Succinivibrionaceae(100);G#Succinivibrio(100);S#uncultured rumen bacterium(100)
    #    OTU_1  1 K#Bacteria(100);P#Proteobacteria(100);C#Gammaproteobacteria(100);O#Aeromonadales(100);F#Succinivibrionaceae(100);G#Succinivibrio(100)
    #    OTU_2  1 K#Bacteria(100);P#Proteobacteria(100);C#Gammaproteobacteria(100);O#Pasteurellales(100);F#Pasteurellaceae(100);G#Haemophilus(100);S#uncultured Haemophilus sp.(100)
    #    OTU_3  1 K#Bacteria(100);P#Proteobacteria(100);C#Gammaproteobacteria(100);O#Aeromonadales(100);F#Succinivibrionaceae(100);G#Succinivibrio(100)
    #    OTU_4  2 K#Bacteria(100);P#Fusobacteria(100);C#Fusobacteriia(100);O#Fusobacteriales(100);F#Fusobacteriaceae(100);G#Fusobacterium(100)
    def classify_seq(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :dir, :prefix, :kmer_size, :step_size, :hits_max, :consensus, :coverage, :best_only)
      options_required(options, :dir)
      options_dirs_exist(options, :dir)
      options_allowed_values(options, best_only: [nil, true, false])
      options_assert(options, ":kmer_size > 0")
      options_assert(options, ":kmer_size <= 12")
      options_assert(options, ":step_size > 0")
      options_assert(options, ":step_size <= 12")
      options_assert(options, ":hits_max > 0")
      options_assert(options, ":consensus > 0")
      options_assert(options, ":consensus <= 1")
      options_assert(options, ":coverage > 0")
      options_assert(options, ":coverage <= 1")
     
      options[:prefix]    ||= "taxonomy"
      options[:kmer_size] ||= 8
      options[:step_size] ||= 1
      options[:hits_max]  ||= 50
      options[:consensus] ||= 0.51
      options[:coverage]  ||= 0.9
      options[:best_only] ||= true

      lmb = lambda do |input, output, status|
        status[:sequences_in]  = 0

        status_track(status) do
          search = BioPieces::Taxonomy::Search.new(options)

          input.each_with_index do |record, i|
            status[:records_in] += 1

            if record[:SEQ]
              status[:sequences_in] += 1
              seq_name = record[:SEQ_NAME] || i.to_s

              result = search.execute(BioPieces::Seq.new(seq_name: seq_name, seq: record[:SEQ]))

              record[:TAXONOMY]      = result.taxonomy
              record[:TAXONOMY_HITS] = result.hits
              record[:RECORD_TYPE]   = "taxonomy"
            end

            output << record
            status[:records_out] += 1
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

