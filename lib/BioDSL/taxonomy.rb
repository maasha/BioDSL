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
# This software is part of BioDSL (www.github.com/maasha/BioDSL).              #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioDSL
  class TaxonomyError < StandardError; end

  # Module containing classes for creating a taxonomic database and searching
  # this.
  module Taxonomy
    require 'narray'

    TAX_LEVELS = [:r, :k, :p, :c, :o, :f, :g, :s]

    # rubocop: disable ClassLength

    # Class for creating and databasing an index of a taxonomic tree. This is
    # done in two steps. 1) A temporary tree is creating using the taxonomic
    # strings from the sequence names in a FASTA file. 2) A simplistic tree
    # is constructed from the temporary tree allowing this to be saved to files.
    # The resulting index consists of the following files:
    #  * taxonomy_tax_index.dat  - return node for a given node id.
    #  * taxonomy_kmer_index.dat - return list of node ids for a given level and
    #                              kmer.
    class Index
      require 'set'

      attr_reader :size, :node_id
      alias_method :size, :node_id

      # Constructor Index object.
      def initialize(options)
        @options   = options                                       # Option hash
        @seq_id    = 0                                             # Sequence id
        @node_id   = 0                                             # Node id
        @tree      = TaxNode.new(nil, :r, 'root', nil, @node_id)   # Root node
        @node_id  += 1

        %i(kmer_size step_size output_dir prefix).each do |option|
          fail TaxonomyError, "missing #{option} option" unless @options[option]
        end
      end

      # Method to add a Sequence entry to the taxonomic tree. The sequence name
      # contain a taxonomic string.
      #
      # Example entry:
      # seq_name: K#Bacteria;P#Proteobacteria;C#Gammaproteobacteria; \
      #           O#Vibrionales;F#Vibrionaceae;G#Vibrio;S#Vibrio
      # seq:      UCCUACGGGAGGCAGCAGUGGGGAAUAUUGCACAAUGGGCGCAAGCCUGA \
      #           UGCAGCCAUGCCGCGUGUAUGAAGGCCUUCGGGUUGUAACUC ...
      #
      # The sequence is reduced to a list of oligos of a given size and a given
      # step size, e.g. 8 and 1, respectively:
      #
      # UCCUACGG
      #  CCUACGGG
      #   CUACGGGA
      #    UACGGGAG
      #     ACGGGAGG
      #      ...
      #
      # Each oligo is encoded as an kmer (integer) by encoding two bits per
      # nucleotide:
      #
      # A = 00
      # U = 01
      # C = 10
      # G = 11
      #
      # E.g. UCCUACGG = 0110100100101111 = 26927
      #
      # For each node in the tree a set is kept containing information of
      # all observed oligos for that particular node. Thus all child nodes
      # contain a subset of oligos compared to the parent node.
      def add(entry)
        node       = @tree
        old_name   = false
        tax_levels = entry.seq_name.split(';')

        if tax_levels.size != TAX_LEVELS.size - 1
          fail TaxonomyError, "Wrong number of tax levels in #{entry.seq_name}"
        end

        tax_levels.each_with_index do |tax_level, i|
          level, name = tax_level.split('#')

          if level.downcase.to_sym != TAX_LEVELS[i + 1]
            fail TaxonomyError, "Unexpected tax id in #{entry.seq_name}"
          end

          if name
            if i > 0 && !old_name
              fail TaxonomyError, "Gapped tax level info in #{entry.seq_name}"
            end

            if (child = node[name])
            else
              child = TaxNode.new(node, level.downcase.to_sym, name, @seq_id,
                                  @node_id)
              @node_id += 1
            end

            if leaf?(tax_levels, i)
              kmers = entry.to_kmers(kmer_size: @options[:kmer_size],
                                     step_size: @options[:step_size])
              child.kmers |= Set.new(kmers)
            end

            node[name] = child
            node = node[name]
          end

          old_name = name
        end

        @seq_id += 1

        self
      end

      # Remap and save taxonomic tree to index files.
      def save
        tree_union(@tree)

        save_kmer_index
        save_tax_index
      end

      # Testing method to get a node given an id. Returns nil if node wasn't
      # found.
      def get_node(id)
        queue = [@tree]

        until queue.empty?
          node = queue.shift

          return node if node.node_id == id

          node.children.each_value do |child|
            queue.unshift(child) unless child.nil?
          end
        end

        nil
      end

      # Method that traverses the tax tree and populate all parent nodes with
      # the union of all kmers from the patents children.
      def tree_union(node = @tree)
        node.children.each_value { |child| tree_union(child) }

        node.children.each_value do |child|
          if node.kmers.nil? && child.kmers.nil?
          elsif node.kmers.nil?
            node.kmers = child.kmers
          else
            node.kmers |= child.kmers if child.kmers
          end
        end
      end

      private

      # Method that determines if a node is a leaf or not.
      def leaf?(tax_levels, i)
        if tax_levels[i + 1] && tax_levels[i + 1].split('#')[1]
          false
        else
          true
        end
      end

      # Save tax index to file.
      def save_tax_index
        file = File.join(@options[:output_dir],
                         "#{@options[:prefix]}_tax_index.dat")
        File.open(file, 'wb') do |ios|
          ios.puts %w(#SEQ_ID NODE_ID LEVEL NAME PARENT_ID).join("\t")
          queue = [@tree]

          until queue.empty?
            node = queue.shift

            ios.puts [node.seq_id, node.node_id, node.level, node.name,
                      node.parent_id].join("\t")

            node.children.each_value do |child|
              queue.unshift(child) unless child.nil?
            end
          end
        end
      end

      # Construct and save kmer index to file. This is done BFS style one
      # taxonomic level at a time to save memory.
      def save_kmer_index
        file = File.join(@options[:output_dir],
                         "#{@options[:prefix]}_kmer_index.dat")
        File.open(file, 'wb') do |ios|
          ios.puts %w(#LEVEL KMER NODES).join("\t")

          level = 0
          queue = [@tree]

          until queue.empty?
            kmer_index = Hash.new { |h, k| h[k] = [] }
            new_queue = []

            queue.each do |node|
              node.kmers.to_a.map { |kmer| kmer_index[kmer] << node.node_id }
              node.children.each_value { |child| child && new_queue << child }
            end

            kmer_index.keys.sort.each do |kmer|
              nodes = kmer_index[kmer].sort.join(';')

              ios.puts [TAX_LEVELS[level], kmer, nodes].join("\t")
            end

            queue = new_queue
            level += 1
          end

          kmer_index
        end
      end

      # Class for the nodes used for constructing the taxonomic tree.
      class TaxNode
        attr_accessor :kmers
        attr_reader :parent, :level, :name, :children, :seq_id, :node_id

        # Constructor for TaxNode objects.
        def initialize(parent, level, name, seq_id, node_id)
          @parent   = parent   # Parent node.
          @level    = level    # Taxonomic level.
          @name     = name     # Taxonomic name.
          @kmers    = Set.new  # Kmer set.
          @seq_id   = seq_id   # Sequ id (a representative seq for debugging).
          @node_id  = node_id  # Node id.
          @children = {}       # Child node hash.
        end

        # Returns parent node id if a parent exist, else nil.
        def parent_id
          @parent.node_id if @parent
        end

        # Returns an array of children node ids.
        def children_ids
          ids = []

          @children.each_value { |child| ids << child.id }

          ids
        end

        # Getter method for node children.
        def [](key)
          @children[key]
        end

        # Setter method for node children.
        def []=(key, value)
          @children[key] = value
        end
      end
    end

    # Class for searching sequences in a taxonomic database. The database
    # consists a taxonomic tree index and indices for each taxonomic level
    # saved in the following files:
    #  * taxonomy_tax_index.dat  - return node for a given node id.
    #  * taxonomy_kmer_index.dat - return list of node ids for a given level and
    #                              kmer.
    class Search
      MAX_COUNT    = 200_000
      MAX_HITS     = 2_000    # Max num of shared oligos between two sequences.
      BYTES_IN_INT = 4
      BYTES_IN_HIT = 2 * BYTES_IN_INT

      # Constructor for initializing a Search object.
      def initialize(options)
        @options    = options

        symbols = %i(kmer_size step_size dir prefix consensus coverage hits_max)

        symbols.each do |opt|
          fail TaxonomyError, "missing #{opt} option" unless @options[opt]
        end

        @count_ary  = BioDSL::CAry.new(MAX_COUNT, BYTES_IN_INT)
        @hit_ary    = BioDSL::CAry.new(MAX_HITS, BYTES_IN_HIT)
        @tax_index  = load_tax_index
        @kmer_index = load_kmer_index
      end

      # Method to execute a search for a given sequence entry. First the
      # sequence is broken down into unique kmers of a given kmer_size
      # overlapping with a given step_size. See Taxonomy::Index.add.
      # Now, for each taxonomic level, starting from species all nodes
      # for each kmer is looked up in the database. The nodes containing
      # most kmers are considered hits. If there are no hits at a taxonomic
      # level, we move to the next level. Hits are sorted according to how
      # many kmers matched this particular node and a consensus taxonomy
      # string is determined. Hits are also filtered with the following
      # options:
      #   * hits_max  - Include maximally this number of hits in the consensus.
      #   * best_only - Include only the best scoring hits in the consensus.
      #                 That is if a hit consists of 344 kmers out of 345
      #                 possible, only hits with 344 kmers are included.
      #   * coverage  - Filter hits based on kmer coverage. If a hit contains
      #                 fewer kmers than the total amount of kmers x coverage
      #                 it will be filtered.
      #   * consensus - For a number of hits accept consensus at a given level
      #                 if within this percentage.
      def execute(entry)
        kmers = entry.to_kmers(kmer_size: @options[:kmer_size],
                               step_size: @options[:step_size])

        puts "DEBUG Q: #{entry.seq_name}" if BioDSL.debug

        TAX_LEVELS.reverse.each do |level|
          kmers_lookup(kmers, level)

          hit_count = hits_select_C(@count_ary.ary, @count_ary.count,
                                    @hit_ary.ary, kmers.size,
                                    (@options[:best_only] ? 1 : 0),
                                    @options[:coverage])
          hit_count = @options[:hits_max] if @options[:hits_max] < hit_count

          if hit_count == 0
            puts "DEBUG no hits @ #{level}" if BioDSL.debug
          else
            puts "DEBUG hit(s) @ #{level}"  if BioDSL.debug
            taxpaths = []

            (0...hit_count).each do |i|
              start = BYTES_IN_HIT * i
              stop  = BYTES_IN_HIT * i + BYTES_IN_HIT

              node_id, count = @hit_ary.ary[start...stop].unpack('II')

              taxpath = TaxPath.new(node_id, count, kmers.size, @tax_index)

              if BioDSL.debug
                seq_id = @tax_index[node_id].seq_id
                puts "DEBUG S_ID: #{seq_id} KMERS: [#{count}/#{kmers.size}] \
                      #{taxpath}"
              end

              taxpaths << taxpath
            end

            return Result.new(hit_count, compile_consensus(taxpaths, hit_count).
                   tr('_', ' '))
          end
        end

        Result.new(0, 'Unclassified')
      end

      private

      # Method to load and return the tax_index from file.
      def load_tax_index
        tax_index = {}
        file = File.join(@options[:dir], "#{@options[:prefix]}_tax_index.dat")
        File.open(file) do |ios|
          ios.each do |line|
            line.chomp!

            next if line[0] == '#'

            seq_id, node_id, level, name, parent_id = line.split("\t")

            tax_index[node_id.to_i] = Node.new(seq_id.to_i, node_id.to_i,
                                               level.to_sym, name,
                                               parent_id.to_i)
          end
        end

        tax_index
      end

      # Method to load and return the kmer_index from file.
      def load_kmer_index
        kmer_index = Hash.new { |h, k| h[k] = {} }
        file = File.join(@options[:dir], "#{@options[:prefix]}_kmer_index.dat")
        File.open(file) do |ios|
          ios.each do |line|
            line.chomp!

            next if line[0] == '#'

            level, kmer, nodes = line.split("\t")

            kmer_index[level.to_sym][kmer.to_i] = nodes.split(';').map(&:to_i).
                                                  pack('I*')
          end
        end

        kmer_index
      end

      # Method that given a list of kmers and a taxonomic level
      # lookups all the nodes for each kmer and increment the
      # count array posisions for all nodes. The lookup for each
      # kmer is initially done from a database, but subsequent
      # lookups for that particular kmer are cached.
      def kmers_lookup(kmers, level)
        @count_ary.zero!

        kmers.each do |kmer|
          next unless @kmer_index[level]

          if (nodes = @kmer_index[level][kmer])
            increment_C(@count_ary.ary, nodes, nodes.size / BYTES_IN_INT)
          end
        end
      end

      # Method that given a list of taxonomic paths determines a consensus for
      # each taxonomic level. E.g. for the kingdom level if 60% of the taxpaths
      # indicate 'Bacteria' and the consensus is 50% then the consensus for the
      # kingdom level will be reported as 'Bacteria(60)'. If the name at any
      # level consists of multiple words they are treated independently. E.g if
      # we have three taxpath at the species level with the names:
      #
      #   *  Escherichia coli K-12
      #   *  Escherichia coli sp. AC3432
      #   *  Escherichia coli sp. AC1232
      #
      # The corresponding consensus for that level will be reported as
      # 'Escherichia coli sp.(100/100/66)'. The forth word in the last two
      # taxonomy strings (AC3432 and AC1232) have a consensus below 50% and are
      # ignored.
      def compile_consensus(taxpaths, hit_size)
        consensus = []
        tax_hash  = decompose_consensus(taxpaths)

        tax_hash.each do |level, subhash|
          cons   = []
          scores = []

          subhash.each_value do |subsubhash|
            subsubhash.sort_by { |_, count| count }.reverse.
              each do |subname, count|
              if count >= hit_size * @options[:consensus]
                cons   << subname
                scores << ((count / hit_size.to_f) * 100).to_i
              end
            end
          end

          break if cons.empty?

          consensus << "#{level.upcase}##{cons.join('_')}(#{scores.join('/')})"
        end

        if consensus.empty?
          'Unclassified'
        else
          consensus.join(';')
        end
      end

      # Method that given a list of taxonomic paths splits these into a data
      # structure appropriate for subsequence determination of the taxonomic
      # consensus.
      def decompose_consensus(taxpaths)
        tax_hash = Hash.new do |h1, k1|
          h1[k1] = Hash.new { |h2, k2| h2[k2] =  Hash.new(0) }
        end

        taxpaths.each do |taxpath|
          taxpath.nodes[1..-1].each do |node|  # Ignoring root level, start at 1
            node.name.split('_').each_with_index do |subname, i|
              tax_hash[node.level][i][subname] += 1
            end
          end
        end

        tax_hash
      end

      inline do |builder|
        # Struct for a 'hit' containing two pieces of information:
        #   * node_id - Node id for this particular node.
        #   * count   - Number of kmers matching this particular node.
        builder.prefix %(
          typedef struct
          {
             unsigned int node_id;
             unsigned int count;
          } hit;
        )

        # Qsort hit struct comparision function for sorting
        # hits according to count (highest count first).
        # Returns negative if a > b and positive if b > a.
        builder.prefix %{
          int hit_cmp_by_count_C(const void *a, const void *b)
          {
            hit *ia = (hit *) a;
            hit *ib = (hit *) b;

            return (int) (ib->count - ia->count);
          }
        }

        # Method to select only the best hits from the hit ary, which is sorted
        # according to count (highest count first).
        builder.prefix %{
          void hits_select_best_only_C(
            hit *hit_ary,               // hit array.
            unsigned int *hit_ary_len   // hit array length.
          )
          {
            unsigned int i   = 0;
            unsigned int max = 0;

            max = hit_ary[i].count;

            i++;

            while ((i < *hit_ary_len) && (hit_ary[i].count == max)){
              i++;
            }

            *hit_ary_len = i;
          }
        }

        # Method for incrementing the count_ary. Each position in the count_ary
        # corresponds to a node_id. The value at the position that is
        # incremented corresponds to the number of shared kmers between this
        # node id and the query sequence.
        builder.c %{
          void increment_C(
            VALUE _count_ary,   // Count ary.
            VALUE _nodes_ary,   // Nodes ary.
            VALUE _length       // Nodes ary length.
          )
          {
            int *count_ary = (int *) StringValuePtr(_count_ary);
            int *nodes_ary = (int *) StringValuePtr(_nodes_ary);
            int  length    = FIX2INT(_length);
            int  i         = 0;

            for (i = 0; i < length; i++) {
              count_ary[nodes_ary[i]]++;
            }
          }
        }

        # Method for selecting hits based from the count_ary. Hits are selected
        # on a number of specified parameters:
        #   * best_only - if this is true only top scoring hits are reported.
        #   * coverage  - Filter hits based on kmer coverage. If a hit contains
        #                 fewer kmers than the total amount of kmers x coverage
        #                 it will be filtered.
        # The resulting hit_ary is sorted according to count (highest count
        # first) and the size of the hit_ary is returned.
        builder.c %{
          VALUE hits_select_C(
            VALUE _count_ary,       // Count ary.
            VALUE _count_ary_len,   // Count ary length.
            VALUE _hit_ary,         // Hit ary.
            VALUE _kmers_size,      // Number of kmers.
            VALUE _best_only,       // Option best_only
            VALUE _coverage         // Option coverage
          )
          {
            int    *count_ary     = (int *) StringValuePtr(_count_ary);
            int     count_ary_len = FIX2INT(_count_ary_len);
            hit    *hit_ary       = (hit *) StringValuePtr(_hit_ary);
            int     kmers_size    = FIX2INT(_kmers_size);
            int     best_only     = FIX2INT(_best_only);
            double  coverage      = NUM2DBL(_coverage);

            hit          new_hit = {0, 0};
            int          count   = 0;
            int          i       = 0;
            unsigned int j       = 0;

            for (i = 0; i < count_ary_len; i++)
            {
              if ((count = count_ary[i]))
              {
                if (count >= kmers_size * coverage)
                {
                  new_hit.node_id = i;
                  new_hit.count   = count;

                  hit_ary[j] = new_hit;

                  j++;
                }
              }
            }

            if (j > 1)
            {
              qsort(hit_ary, j, sizeof(hit), hit_cmp_by_count_C);

              if (best_only) {
                hits_select_best_only_C(hit_ary, &j);
              }
            }

            return UINT2NUM(j);
          }
        }
      end

      # Structure for taxonomic tree nodes.
      Node = Struct.new(:seq_id, :node_id, :level, :name, :parent_id)

      # Structure for holding the search result.
      Result = Struct.new(:hits, :taxonomy)

      # Class holding methods for manipulating tanomic paths.
      class TaxPath
        attr_reader :nodes

        # Constructor method for TaxPath objects.
        def initialize(node_id, kmers_observed, kmers_total, tax_index)
          @node_id        = node_id
          @kmers_observed = kmers_observed
          @kmers_total    = kmers_total
          @tax_index      = tax_index
          @nodes          = taxonomy_backtrack
        end

        # Method that returns a list of nodes for a given node_id and all
        # parent ids up the taxonomy tree.
        def taxonomy_backtrack
          nodes = []

          node_id = @node_id

          while (node = @tax_index[node_id])
            nodes << node

            break if node.level == :r # At root level

            node_id = node.parent_id
          end

          nodes.reverse
        end

        # Returns formatted taxonomy string.
        def to_s
          levels = []

          @nodes[1..-1].each do |node|
            levels << "#{node.level.upcase}##{node.name}"
          end

          levels.join(';')
        end
      end
    end
  end
end
