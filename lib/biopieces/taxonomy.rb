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
# This software is part of Biopieces (www.biopieces.org).                        #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  # Module containing classes for creating a taxonomic database and searching this.
  module Taxonomy
    require 'lz4-ruby'
    require 'narray'

    TAX_LEVELS = [:r, :k, :p, :c, :o, :f, :g, :s]

    class Databases
      require 'tokyocabinet'
      include TokyoCabinet

      # Connect all databases.
      def self.connect(dir, prefix)
        databases = {}

        TAX_LEVELS.inject([:taxtree]) { |memo, obj| memo << "#{obj}_kmer2nodes".to_sym }.each do |name|
          databases[name] = HDB::new
        end

        databases.each do |name, database|
          if !database.open(File.join(dir, "#{prefix}_#{name}.tch"), HDB::OWRITER | HDB::OCREAT)
            ecode = database.ecode
            STDERR.printf("open error: %s\n", database.errmsg(ecode))
          end
        end

        databases
      end

      # Disconnect all databases.
      def self.disconnect(databases)
        databases.values do |database|
          if !database.close
            ecode = database.ecode
            STDERR.printf("close error: %s\n", database.errmsg(ecode))
          end
        end
      end
    end

    # Class for creating and databasing an index of a taxonomic tree. This is
    # done in two steps. 1) A temporary tree is creating using the taxonomic
    # strings from the sequence names in a FASTA file. 2) A simplistic tree
    # is constructed from the temporary tree allowing this to be saved to files
    # using Tokyo Cabinet. The resulting index consists of the following files:
    #  * taxonomy_taxtree.tch      - return node for a given node id.
    #  * taxonomy_r_kmer2nodes.tch - return list of root    level node ids for a given kmer.
    #  * taxonomy_k_kmer2nodes.tch - return list of kingdom level node ids for a given kmer.
    #  * taxonomy_p_kmer2nodes.tch - return list of phylum  level node ids for a given kmer.
    #  * taxonomy_c_kmer2nodes.tch - return list of class   level node ids for a given kmer.
    #  * taxonomy_o_kmer2nodes.tch - return list of order   level node ids for a given kmer.
    #  * taxonomy_f_kmer2nodes.tch - return list of family  level node ids for a given kmer.
    #  * taxonomy_g_kmer2nodes.tch - return list of genus   level node ids for a given kmer.
    #  * taxonomy_s_kmer2nodes.tch - return list of species level node ids for a given kmer.
    class Index
      # Constructor Index object.
      def initialize(options)
        @options      = options                                       # Option hash.
        @id           = 0                                             # Node id.
        @tree         = TaxNode.new(nil, :r, nil, nil, nil, @id)      # Root level tree node.
        @id          += 1
        @kmers        = Vector.new(4 ** @options[:kmer_size], "byte") # Kmer vector for storing observed kmers.
        @max_children = 0                                             # Stats info.
      end

      # Method to add a Sequence entry to the taxonomic tree. The sequence name
      # contain a sequnce ID (integer) and the taxonomic string.
      #
      # Example FASTA entry:
      # >2 K#Bacteria;P#Proteobacteria;C#Gammaproteobacteria;O#Vibrionales;F#Vibrionaceae;G#Vibrio;S#Vibrio
      # UCCUACGGGAGGCAGCAGUGGGGAAUAUUGCACAAUGGGCGCAAGCCUGAUGCAGCCAUGCCGCGUGUAUGAAGAAGGCCUUCGGGUUGUAACUC ...
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
      # Each oligo is encoded as an kmer (integer) by encoding two bits per nucletoide:
      #
      # A = 00
      # U = 01
      # C = 10
      # G = 11
      #
      # E.g. UCCUACGG = 0110100100101111 = 26927
      #
      # For each node in the tree a vector is kept containing information of
      # all observed oligos for that particular node. Thus all child nodes 
      # contain a subset of oligos compared to the parent node.
      def add(entry)
        node  = @tree
        kmers = entry.to_kmers(kmer_size: @options[:kmer_size], step_size: @options[:step_size])

        @kmers.zero!
        @kmers[kmers] = 1 unless kmers.empty?
        
        seq_id, tax_string = entry.seq_name.split(' ', 2)

        tax_levels = tax_string.split(';')

        tax_levels.each do |tax_level|
          level, name = tax_level.split('#')

          if name
            if node[name]
              node[name].kmers |= @kmers
            else
              node[name] = TaxNode.new(node, level.downcase.to_sym, name, @kmers.dup, seq_id.to_i, @id)
              @id += 1
            end

            node = node[name]
          end
        end

        self
      end

      # Remap and save taxonomic tree to index files.
      def save
        databases = Databases.connect(@options[:output_dir], @options[:prefix])

        kmer_hash = Hash.new { |h1, k1| h1[k1] = Hash.new { |h2, k2| h2[k2] = Set.new } }

        tree_remap(@tree, kmer_hash, databases)

        kmer_hash.each do |level, hash|
          hash.each do |kmer, nodes|
            databases["#{level}_kmer2nodes".to_sym][kmer] = nodes.to_a.sort.pack("I*")
          end
        end
      ensure
        Databases.disconnect(databases)

        puts "Nodes: #{@id}   Max children: #{@max_children}" if $VERBOSE
      end

      private

      # Remap the taxonomic tree using simple nodes and build a hash with
      # all nodes per kmer.
      def tree_remap(node, kmer_hash, databases)
        databases[:taxtree][node.node_id] = Node.new(node.seq_id, node.node_id, node.level, node.name, node.parent_id).to_marshal

        node.kmers.to_a.map { |kmer| kmer_hash[node.level][kmer].add(node.node_id) }   # FIXME BOTTLE NECK

        @max_children = node.children.size if node.children.size > @max_children

        node.children.each_value { |child| tree_remap(child, kmer_hash, databases) }
      end

      # Class with methods to manipulate a vector used to hold uniq kmers (integers).
      # The vector is encoded in a byte array using NArray compressed using LZ4 to
      # save memory.
      class Vector
        attr_reader :kmers

        # Constructor for creating a new Vector object of a given size.
        def initialize(size, type)
          @size  = size
          @type  = type
          @kmers = LZ4::compress(NArray.new(@type, @size).to_s)
        end

        # Set all values in the vector to zero.
        def zero!
          na = NArray.to_na(LZ4::uncompress(@kmers), @type)
          na.fill! 0
          @kmers = LZ4::compress(na.to_s)

          nil # save GC
        end

        # Use the given kmers array as index to set all positions in the
        # vector to the given value.
        def []=(kmers, value)
          na = NArray.to_na(LZ4::uncompress(@kmers), @type)
          na[NArray.to_na(kmers)] = value
          @kmers = LZ4::compress(na.to_s)
        end

        # Perform bitwise OR between two vectors.
        def |(vector)
          na1 = NArray.to_na(LZ4::uncompress(@kmers), @type)
          na2 = NArray.to_na(LZ4::uncompress(vector.kmers), @type)
          @kmers = LZ4::compress((na1 | na2).to_s)
          
          self
        end

        # Method to return all kmers saved in a vector as a list of integers.
        def to_a
          na = NArray.to_na(LZ4::uncompress(@kmers), @type)
          (na > 0).where.to_s.unpack("I*")
        end

        # Method to return the count of true values in a vector.
        def count_true
          na = NArray.to_na(LZ4::uncompress(@kmers), @type)
          na.count_true
        end
      end

      # Class for the nodes used for constructing the taxonomic tree.
      class TaxNode
        attr_accessor :kmers
        attr_reader :parent, :level, :name, :children, :seq_id, :node_id

        # Constructor for TaxNode objects.
        def initialize(parent, level, name, kmers, seq_id, node_id)
          @parent   = parent   # Parent node.
          @level    = level    # Taxonomic level.
          @name     = name     # Taxonomic name.
          @kmers    = kmers    # Kmer vector.
          @seq_id   = seq_id   # Sequence id.
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

      # Class for simple taxonomic tree where each node have the attributes:
      # seq_id:  sequence id.
      # node_id: node id.
      # level:   taxonomic level.
      # name:    taxnonomic name.
      # parent:  parent node id.
      Node = Struct.new(:seq_id, :node_id, :level, :name, :parent) do
        def to_marshal
          Marshal.dump(self)
        end
      end
    end

    # Class for searching sequences in a taxonomic database. The database
    # consists a taxonomic tree index and indices for each taxonomic level
    # saved in the following Tokyo Cabinet files:
    #  * taxonomy_taxtree.tch      - return node for a given node id.
    #  * taxonomy_r_kmer2nodes.tch - return list of root    level node ids for a given kmer.
    #  * taxonomy_k_kmer2nodes.tch - return list of kingdom level node ids for a given kmer.
    #  * taxonomy_p_kmer2nodes.tch - return list of phylum  level node ids for a given kmer.
    #  * taxonomy_c_kmer2nodes.tch - return list of class   level node ids for a given kmer.
    #  * taxonomy_o_kmer2nodes.tch - return list of order   level node ids for a given kmer.
    #  * taxonomy_f_kmer2nodes.tch - return list of family  level node ids for a given kmer.
    #  * taxonomy_g_kmer2nodes.tch - return list of genus   level node ids for a given kmer.
    #  * taxonomy_s_kmer2nodes.tch - return list of species level node ids for a given kmer.
    class Search < Databases
      MAX_COUNT    = 200_000
      MAX_HITS     = 1_000
      BYTES_IN_INT = 4
      BYTES_IN_HIT = 2 * BYTES_IN_INT

      # Constructor for initializing a Search object.
      def initialize(options)
        @options   = options
        @databases = Databases.connect(@options[:dir], @options[:prefix])
        @count_ary = BioPieces::CAry.new(MAX_COUNT, BYTES_IN_INT)
        @hit_ary   = BioPieces::CAry.new(MAX_HITS, BYTES_IN_HIT)
        @cache     = Hash.new { |h, k| h[k] = {} }
      end

      # Method to execute a search for a given sequence entry. First the
      # sequence is broken down into unique kmers of a given kmer_size
      # overlapping with a given step_size. See Taxonomy::Index.add.
      # Now, for each taxonomic level, starting from species all nodes
      # for each kmer is looked up in the database. The nodes containing
      # most kmers are considered hits. If there are no hits a the taxonomic
      # level, we move to the next level. Hits are sorted according to how
      # many kmers matched this particular node and a consensus taxonomy
      # string is determined. Hits are also filtered with the following
      # options:
      #   * hits_max  - Include maximally this number of hits in the consensus
      #                 determination.
      #   * best_only - Include only the best scoreing hits in the consensus
      #                 determination. That is if a hit consists of 344 kmers
      #                 out of 345 possible, only hits with 344 kmers are
      #                 included.
      #   * coverage  - Filter hits based on kmer coverage. If a hit contains
      #                 fewer kmers than the total amount of kmers x coverage
      #                 it will be filtered.
      #   * consensus - For a number of hits accept consensus at a given level
      #                 if this percentage is identical.
      def execute(entry)
        kmers = entry.to_kmers(kmer_size: @options[:kmer_size], step_size: @options[:step_size])

        puts "DEBUG Q: #{entry.seq_name}" if $VERBOSE

        TAX_LEVELS.reverse.each do |level|
          kmers_lookup(kmers, level)

          hit_count = hits_select_C(@count_ary.ary, @count_ary.count, @hit_ary.ary, kmers.size, (@options[:best_only] ? 1 : 0), @options[:coverage])
          hit_count = @options[:hits_max] if @options[:hits_max] < hit_count

          if hit_count == 0
            puts "DEBUG no hits @ #{level}" if $VERBOSE
          else
            puts "DEBUG hit(s) @ #{level}" if $VERBOSE
            taxpaths = []

            (0 ... hit_count).each do |i|
              node_id, count = @hit_ary.ary[BYTES_IN_HIT * i ... BYTES_IN_HIT * i + BYTES_IN_HIT].unpack("II")

              taxpath = TaxPath.new(@databases, node_id, count, kmers.size)

              if $VERBOSE
                seq_id  = Marshal.load(@databases[:taxtree][node_id]).seq_id
                puts "DEBUG S_ID: #{seq_id} KMERS: [#{count}/#{kmers.size}] #{taxpath}"
              end

              taxpaths << taxpath
            end

            return Result.new(hit_count, compile_consensus(taxpaths, hit_count).tr('_', ' '))
          end
        end

        Result.new(0, "Unclassified")
      end

      private

      # Method that disconnects and closes all databases.
      def disconnect
        Databases.disconnect(@databases)
      end

      # Method that given a list of kmers and a taxonomic level
      # lookups all the nodes for each kmer and increment the
      # count array posisions for all nodes. The lookup for each
      # kmer is initially done from a database, but subsequent
      # lookups for that particular kmer is cached.
      def kmers_lookup(kmers, level)
        @count_ary.zero!

        kmers.each do |kmer|
          if @cache[level] and nodes = @cache[level][kmer]
            increment_C(@count_ary.ary, nodes, nodes.size / BYTES_IN_INT)
          elsif nodes = @databases["#{level}_kmer2nodes".to_sym][kmer]
            increment_C(@count_ary.ary, nodes, nodes.size / BYTES_IN_INT)
            @cache[level][kmer] = nodes
          end
        end
      end

      def compile_consensus(taxpaths, hit_size)
        hash = Hash.new { |h1, k1| h1[k1] = Hash.new { |h2, k2| h2[k2] =  Hash.new(0) } }
        consensus = []

        taxpaths.each do |taxpath|
          taxpath.nodes[1 .. -1].each do |node|
            node.name.split('_').each_with_index do |subname, i|
              hash[node.level][i][subname] += 1
            end
          end
        end

        hash.each do |level, subhash|
          cons   = []
          scores = []

          subhash.each_value do |subsubhash|
            subsubhash.sort_by { |_, count| count }.reverse.each do |subname, count|
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
          "Unclassified"
        else
          consensus.join(';')
        end
      end

      inline do |builder|
        builder.prefix %{
          typedef struct
          {
             unsigned int node_id;
             unsigned int count;
          } hit;
        }

        # Qsort hit struct comparision function.
        # Returns negative if a > b and positive if b > a.
        builder.prefix %{
          int hit_cmp_by_count(const void *a, const void *b)
          {
            hit *ia = (hit *) a;
            hit *ib = (hit *) b;

            return (int) (ib->count - ia->count);
          }
        }

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

            for (i = length - 1; i >= 0; i--) {
              count_ary[nodes_ary[i]]++;
            }
          }
        }

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

            hit new_hit = {0, 0};
            int count   = 0;
            int max     = 0;
            int i       = 0;
            int j       = 0;

            for (i = count_ary_len - 1; i >= 0; i--)
            {
              if ((count = count_ary[i]))
              {
                if (best_only)
                {
                  if (count < max) {
                    continue;
                  } else {
                    max = count;
                  }
                }

                if (count >= kmers_size * coverage)
                {
                  new_hit.node_id = i;
                  new_hit.count   = count;

                  hit_ary[j] = new_hit;

                  j++;
                }
              }
            }

            if (j > 1) {
              qsort(hit_ary, j, sizeof(hit), hit_cmp_by_count);
            }

            return UINT2NUM(j);
          }
        }
      end

      Result = Struct.new(:hits, :taxonomy)

      class TaxPath
        attr_reader :nodes

        def initialize(databases, node_id, kmers_observed, kmers_total)
          @databases      = databases
          @node_id        = node_id
          @kmers_observed = kmers_observed
          @kmers_total    = kmers_total
          @nodes          = taxonomy_backtrack
        end

        # Method that returns a list of nodes for a given node_id and all
        # parent ids up the taxonomy tree.
        def taxonomy_backtrack
          nodes = []

          node_id = @node_id

          while node = Marshal.load(@databases[:taxtree][node_id])
            nodes << node

            node_id = node.parent

            break if node_id.nil?
          end

          nodes.reverse
        end

        # Returns formatted taxonomy string.
        def to_s
          levels = []

          @nodes[1 .. -1].each do |node|
            levels << "#{node.level.upcase}##{node.name}"
          end

          levels.join(';')
        end
      end
    end
  end
end
