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
    MAX_NODES  = 200_000

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
        @kmers[kmers] = 1
        
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

    class Search < Databases
      def initialize(options)
        @options   = options
        @databases = Databases.connect(@options[:dir], @options[:prefix])
        @result    = NArray.int(MAX_NODES)
      end

      def execute(entry)
        kmers = entry.to_kmers(kmer_size: @options[:kmer_size], step_size: @options[:step_size])

        puts "DEBUG Q: #{entry.seq_name}" if $VERBOSE

        TAX_LEVELS.reverse.each do |level|
          @result.fill! 0

          database = @databases["#{level}_kmer2nodes".to_sym]

          kmers.each do |kmer|
            if nodes = database[kmer]
              na = NArray.to_na(nodes, "int")
              @result[na] += 1
            end
          end

          hits = []

          (@result > 0).where.to_a.each do |node_id|
            count = @result[node_id]

            if count >= kmers.size * @options[:coverage]
              hits << Hit.new(node_id, count)
            end
          end

          hits = hits.sort_by { |_, count| count }.reverse.first(@options[:hits_max])

          if hits.size == 0
            puts "DEBUG no hits @ #{level}" if $VERBOSE
          else
            puts "DEBUG hit(s) @ #{level}" if $VERBOSE

            taxpaths = []

            hits.each_with_index do |hit, i|
              taxpath = TaxPath.new(@databases, hit.node_id, hit.count, kmers.size)
                
              puts "DEBUG S: #{taxpath} [#{hit.count}/#{kmers.size}]" if $VERBOSE

              taxpaths << taxpath
            end

            seq_id = Marshal.load(@databases[:taxtree][hits.first.node_id]).seq_id
            pp seq_id

            return Result.new(seq_id, hits.size, compile_consensus(taxpaths, hits.size).tr('_', ' '))
          end
        end
      end

      def disconnect
        Databases.disconnect(@databases)
      end

      private

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

      Hit    = Struct.new(:node_id, :count)
      Result = Struct.new(:seq_id, :hits, :taxonomy)

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
