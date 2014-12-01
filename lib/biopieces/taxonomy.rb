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
    require 'tokyocabinet'
    require 'lz4-ruby'
    require 'narray'

    # Class for creating and databasing an index of a taxonomic tree. This is
    # done in two steps. 1) A temporary tree is creating using the taxonomic
    # strings from the sequence names in a FASTA file. 2) A simplistic tree
    # is constructed from the temporary tree allowing this to be saved to files
    # using Tokyo Cabinet. The resulting index consists of the following files:
    #  * taxonomy_taxtree.tch      - return node for a given node id.
    #  * taxonomy_node2kmers.tch   - return list of kmers for a given node id.
    #  * taxonomy_r_kmer2nodes.tch - return list of root    level node ids for a given kmer.
    #  * taxonomy_k_kmer2nodes.tch - return list of kingdom level node ids for a given kmer.
    #  * taxonomy_p_kmer2nodes.tch - return list of phylum  level node ids for a given kmer.
    #  * taxonomy_c_kmer2nodes.tch - return list of class   level node ids for a given kmer.
    #  * taxonomy_o_kmer2nodes.tch - return list of order   level node ids for a given kmer.
    #  * taxonomy_f_kmer2nodes.tch - return list of family  level node ids for a given kmer.
    #  * taxonomy_g_kmer2nodes.tch - return list of genus   level node ids for a given kmer.
    #  * taxonomy_s_kmer2nodes.tch - return list of species level node ids for a given kmer.
    class Index
      include TokyoCabinet

      # Constructor Index object.
      def initialize(options)
        @options = options                               # Option hash.
        @id      = 0                                     # Node id.
        @tree    = TaxNode.new(nil, 'R', nil, nil, @id)  # Root level tree node.
        @id     += 1
        @kmers  = Vector.new(4 ** @options[:kmer_size])  # Kmer vector for storing observed kmers.
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
        @kmers[kmers] = 1
        
        seq_id, tax_string = entry.seq_name.split(' ')

        tax_levels = tax_string.split(';')

        tax_levels.each do |tax_level|
          level, name = tax_level.split('#')

          case level
          when 'R' then level = :root
          when 'K' then level = :kingdom
          when 'P' then level = :phylum
          when 'C' then level = :class
          when 'O' then level = :order
          when 'F' then level = :family
          when 'G' then level = :genus
          when 'S' then level = :species
          end

          if name
            if node[name]
              @kmers |= node[name].kmers
              node[name].kmers = @kmers
            else
              node[name] = TaxNode.new(node, level, name, @kmers, @id)
              @id += 1
            end

            node = node[name]
          end
        end

        self
      end

      # Remap and save taxonomic tree to index files.
      def save
        databases = databases_connect

        kmer_hash = Hash.new { |h1, k1| h1[k1] = Hash.new { |h2, k2| h2[k2] = Set.new } }

        tree_remap(@tree, kmer_hash, databases)

        kmer_hash.each do |level, hash|
          hash.each do |kmer, nodes|
            databases["#{level[0]}_kmer2nodes".to_sym][kmer] = nodes.to_a.sort.pack("I*")
          end
        end

        databases_close(databases)
      end

      private

      # Remap the taxonomic tree using simple nodes and build a hash with
      # all nodes per kmer.
      def tree_remap(node, kmer_hash, databases)
        kmers = node.kmers.to_a

        databases[:node2kmers][node.id] = kmers.pack("I*")
        databases[:taxtree][node.id]    = Node.new(node.id, node.level, node.name, node.parent_id, node.children_ids, kmers.size).to_marshal

        kmers.map { |kmer| kmer_hash[node.level][kmer].add(node.id) }

        node.children.each_value { |child| tree_remap(child, kmer_hash, databases) }
      end

      # Connect all databases.
      def databases_connect
        databases = {}

        [:node2kmers,
         :taxtree,
         :r_kmer2nodes,
         :k_kmer2nodes,
         :p_kmer2nodes,
         :c_kmer2nodes,
         :o_kmer2nodes,
         :f_kmer2nodes,
         :g_kmer2nodes,
         :s_kmer2nodes].each do |name|
          databases[name] = HDB::new
        end

        databases.each do |name, database|
          if !database.open(File.join(@options[:output_dir], "#{@options[:prefix]}_#{name}.tch"), HDB::OWRITER | HDB::OCREAT)
            ecode = database.ecode
            STDERR.printf("open error: %s\n", database.errmsg(ecode))
          end
        end

        databases
      end

      # Close all databases.
      def databases_close(databases)
        databases.values do |database|
          if !database.close
            ecode = database.ecode
            STDERR.printf("close error: %s\n", database.errmsg(ecode))
          end
        end
      end

      # Class with methods to manipulate a vector used to hold uniq kmers (integers).
      # The vector is encoded in a byte array using NArray compressed using LZ4 to
      # save memory.
      class Vector
        attr_reader :kmers

        # Constructor for creating a new Vector object of a given size.
        def initialize(size)
          @size  = size
          @kmers = LZ4::compress(NArray.byte(@size).to_s)
        end

        # Set all values in the vector to zero.
        def zero!
          na = NArray.to_na(LZ4::uncompress(@kmers), "byte")
          na.fill! 0
          @kmers = LZ4::compress(na.to_s)

          nil # save GC
        end

        # Use the given kmers array as index to set all positions in the
        # vector to the given value.
        def []=(kmers, value)
          na = NArray.to_na(LZ4::uncompress(@kmers), "byte")
          na[NArray.to_na(kmers)] = value
          @kmers = LZ4::compress(na.to_s)
        end

        # Perform bitwise OR between two vectors.
        def |(vector)
          na1 = NArray.to_na(LZ4::uncompress(@kmers), "byte")
          na2 = NArray.to_na(LZ4::uncompress(vector.kmers), "byte")
          @kmers = LZ4::compress((na1 | na2).to_s)
          
          self
        end

        # Method to return all kmers saved in a vector as a list of integers.
        def to_a
          na = NArray.to_na(LZ4::uncompress(@kmers), "byte")
          na.to_a.each_with_index.reject { |e, _| e.zero? }.map(&:last)
        end
      end

      # Class for the nodes used for constructing the taxonomic tree.
      class TaxNode
        attr_accessor :kmers
        attr_reader :parent, :level, :name, :children, :id

        # Constructor for TaxNode objects.
        def initialize(parent, level, name, kmers, id)
          @parent = parent   # Parent node.
          @level  = level    # Taxonomic level.
          @name   = name     # Taxonomic name.
          @kmers  = kmers    # Kmer vector.
          @id     = id       # Node id.

          @children = {}     # Child node hash.
        end

        # Returns parent node id if a parent exist, else nil.
        def parent_id
          @parent.id if @parent
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
      # id: node id.
      # level: taxonomic level.
      # name: taxnonomic name.
      # parent: parent node id.
      # children: array with child node ids.
      # count: count of observed kmers for this node.
      Node = Struct.new(:id, :level, :name, :parent, :children, :count) do
        def to_marshal
          Marshal.dump(self)
        end
      end
    end
  end
end
