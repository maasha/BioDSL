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
  module Taxonomy
    require 'tokyocabinet'

    class Index
      include TokyoCabinet

      def initialize(options)
        @options   = options
        @id        = 0
        @tree      = TaxNode.new(nil, 'R', nil, nil, @id)
        @id       += 1
        @oligos    = NArray.byte(4 ** @options[:kmer_size])
      end

      def add(entry)
        node  = @tree
        kmers = entry.to_kmers(kmer_size: @options[:kmer_size], step_size: @options[:step_size])

        @oligos.fill! 0
        @oligos[NArray.to_na(kmers)] = 1
        
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
              @oligos |= node[name].oligos
              node[name].oligos = @oligos
            else
              node[name] = TaxNode.new(node, level, name, @oligos, @id)
              @id += 1
            end

            node = node[name]
          end
        end

        self
      end

      def databases_connect
        databases = {}

        [:node2oligos,
         :taxtree,
         :r_oligo2nodes,
         :k_oligo2nodes,
         :p_oligo2nodes,
         :c_oligo2nodes,
         :o_oligo2nodes,
         :f_oligo2nodes,
         :g_oligo2nodes,
         :s_oligo2nodes].each do |name|
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

      def databases_close(databases)
        databases.values do |database|
          if !database.close
            ecode = database.ecode
            STDERR.printf("close error: %s\n", database.errmsg(ecode))
          end
        end
      end

      def save
        databases = databases_connect

        kmer_hash = Hash.new { |h1, k1| h1[k1] = Hash.new { |h2, k2| h2[k2] = Set.new } }

        hash_oligos(@tree, kmer_hash, databases)

        kmer_hash.each do |level, hash|
          hash.each do |kmer, nodes|
            databases["#{level[0]}_oligo2nodes".to_sym][kmer] = nodes.to_a.sort.pack("I*")
          end
        end

        databases_close(databases)
      end

      def hash_oligos(node, kmer_hash, databases)
        kmers = node.oligos.to_a.each_with_index.reject { |e, _| e.zero? }.map(&:last)
        databases[:node2oligos][node.id] = kmers.pack("I*")
        databases[:taxtree][node.id]     = Node.new(node.id, node.level, node.name, node.parent_id, node.children_ids, kmers.size).to_marshal

        kmers.map { |kmer| kmer_hash[node.level][kmer].add(node.id) }

        node.children.each_value { |child| hash_oligos(child, kmer_hash, databases) }
      end

      class TaxNode
        attr_accessor :oligos
        attr_reader :parent, :level, :name, :children, :id

        def initialize(parent, level, name, oligos, id)
          @parent = parent
          @level  = level
          @name   = name
          @oligos = oligos
          @id     = id

          @children = {}
        end

        def parent_id
          @parent.id if @parent
        end

        def children_ids
          ids = []

          @children.each_value { |child| ids << child.id }

          ids
        end

        def [](key)
          @children[key]
        end

        def []=(key, value)
          @children[key] = value
        end
      end

      Node = Struct.new(:id, :level, :name, :parent, :children, :count) do
        def to_marshal
          Marshal.dump(self)
        end
      end
    end
  end
end
