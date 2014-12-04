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
    # == Run classify_seq on sequences in the stream.
    # 
    # This is a wrapper for the +mothur+ command +classify.seqs()+. Basically,
    # it classifies sequences in the stream given a database file and a taxonomy
    # file which can be downloaded here:
    #
    # http://www.mothur.org/w/images/5/59/Trainset9_032012.pds.zip
    #
    # Please refer to the manual:
    #
    # http://www.mothur.org/wiki/Classify.seqs
    #
    # Mothur must be installed for +classify_seqs+ to work. Read more here:
    #
    # http://www.mothur.org/
    # 
    # == Usage
    # 
    #    classify_seq(<database: <file>>, <taxonomy: <file>>[, confidence: <uint>[, cpus: <uint>]])
    # 
    # === Options
    #
    # * database:   <file> - Database to search.
    # * taxonomy:   <file> - Taxonomy file for mapping names.
    # * confidence: <uint> - Confidence threshold (defualt=80).
    # * cpus:       <uint> - Number of CPU cores to use (default=1).
    #
    # == Examples
    # 
    # To classify a bunch of OTU sequences in the file +otus.fna+ we do:
    #
    #    database = "trainset9_032012.pds.fasta"
    #    taxonomy = "trainset9_032012.pds.tax"
    #
    #    BP.new.
    #    read_fasta(input: "otus.fna").
    #    classify_seq(database: database, taxonomy: taxonomy).
    #    grab(exact: true, keys: :RECORD_TYPE, select: "taxonomy").
    #    write_table(output: "classified.tab", header: true, force: true, skip: [:RECORD_TYPE]).
    #    run
    def classify_seq(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :dir, :prefix, :kmer_size, :step_size, :hits_max, :consensus, :coverage)
      options_required(options, :dir)
      options_dirs_exist(options, :dir)
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

      lmb = lambda do |input, output, status|
        status[:sequences_in]  = 0

        status_track(status) do
          begin
            search = BioPieces::Taxonomy::Search.new(options)

            input.each_with_index do |record, i|
              status[:records_in] += 1

              if record[:SEQ]
                status[:sequences_in] += 1
                seq_name = record[:SEQ_NAME] || i.to_s

                result = search.execute(BioPieces::Seq.new(seq_name: seq_name, seq: record[:SEQ]))

                record[:TAXONOMY]      = result.taxonomy
                record[:TAXONOMY_HITS] = result.hits
                record[:TAXONOMY_ID]   = result.seq_id
              end

              output << record
              status[:records_out] += 1
            end
          ensure
            search.disconnect
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

