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
    # == Create taxonomy index from sequences in the stream.
    #
    # +index_taxonomy+ is used to create a taxonomy index to allow subsequent
    # taxonomic classification with +classify_seq+. The records with taxnomic
    # information must contain :SEQ_NAME and :SEQ keys where the :SEQ_NAME
    # value must be formatted with an initial ID number followed by a space and
    # then the taxonomy string progressing from kingdom to species level. Only
    # the following leves are accepted:
    #
    #  * K - kingdom
    #  * P - phylum
    #  * C - class
    #  * O - order
    #  * F - family
    #  * G - genus
    #  * S - species
    #
    # Truncated taxonomic strings are allowed, e.g. a string that stops at
    # family level. Below is an example of a full taxonomic string:
    #
    #     32 K#Bacteria;P#Actinobacteria;C#Actinobacteria;O#Acidimicrobiales;F#Acidimicrobiaceae;G#Ferrimicrobium;S#Ferrimicrobium acidiphilum
    #
    # The resulting index consists of the following files (here using the
    # default "taxonomy" as prefix) which are saved to a specified +output_dir+:
    #
    #  * taxonomy_tax_index.dat  - return node for a given node id.
    #  * taxonomy_kmer_index.dat - return list of node ids for a given level and kmer.
    #
    # The index is constructed by breaking the sequences into kmers of a given
    # kmer_size and using a given step_size:
    #
    # Example FASTA entry:
    #
    #    >2 K#Bacteria;P#Proteobacteria;C#Gammaproteobacteria;O#Vibrionales;F#Vibrionaceae;G#Vibrio;S#Vibrio
    #    UCCUACGGGAGGCAGCAGUGGGGAAUAUUGCACAAUGGGCGCAAGCCUGAUGCAGCCAUGCCGCGUGUAUGAAGAAGGCCUUCGGGUUGUAACUC ...
    #
    # This sequence is broken down to a list of oligos using the default
    # kmer_size and step_size of 8 and 1, respectively:
    #
    #    UCCUACGG
    #     CCUACGGG
    #      CUACGGGA
    #       UACGGGAG
    #        ACGGGAGG
    #         ...
    #
    # Oligos containing ambiguity codes are skipped. Each oligo is encoded as
    # an kmer (integer) by encoding two bits per nucletoide:
    #
    #  * A = 00
    #  * U = 01
    #  * C = 10
    #  * G = 11
    #
    # E.g. UCCUACGG = 0110100100101111 = 26927
    #
    # For each node in the tree a vector is kept containing information of all
    # observed oligos for that particular node. Thus all child nodes contain a
    # subset of oligos compared to the parent node. Finally, the tree is saved
    # to files.
    #
    # It should be noted that the speed and accuarcy of the classification is
    # strongly dependent on the size and quality of the taxonomic database used
    # (RDP, GreenGenes or Silva) and for a particular amplicon it is strongly
    # recommended to create a slice from the database aligment matching the
    # amplicon.
    #
    # == Usage
    # 
    #    index_taxonomy(<output_dir: <dir>>[, kmer_size: <uint>[, step_size: <uint>
    #                   [, prefix: <string>[, force: <bool>]]]])
    # 
    # === Options
    #
    #  * output_dir: <dir> - Output directory to contain index files.
    #  * kmer_size: <uint> - Size of kmer to use (default=8).
    #  * step_size: <uint> - Size of steps (default=1).
    #  * prefix: <string>  - Prefix to use with index file names (default="taxonomy").
    #  * force: <bool>     - Force overwrite existing index files.
    #
    # == Examples
    #
    #    BP.new.read_fasta(input: "RDP_11_Bacteria.fna").index_taxonomy(output_dir: "RDP_11").run
    def index_taxonomy(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :output_dir, :kmer_size, :step_size, :prefix, :force)
      options_required(options, :output_dir)
      options_allowed_values(options, force: [nil, true, false])
      options_files_exists_force(options, :report)
      options_assert(options, ":kmer_size > 0")
      options_assert(options, ":kmer_size <= 12")
      options_assert(options, ":step_size > 0")
      options_assert(options, ":step_size <= 12")

      FileUtils.mkdir_p(options[:output_dir]) unless File.exist?(options[:output_dir])

      options[:prefix]    ||= "taxonomy"
      options[:kmer_size] ||= 8
      options[:step_size] ||= 1

      files = [
        File.join(options[:output_dir], "#{options[:prefix]}_taxtree.tch"),
        File.join(options[:output_dir], "#{options[:prefix]}_r_kmer2nodes.tch"),
        File.join(options[:output_dir], "#{options[:prefix]}_k_kmer2nodes.tch"),
        File.join(options[:output_dir], "#{options[:prefix]}_p_kmer2nodes.tch"),
        File.join(options[:output_dir], "#{options[:prefix]}_c_kmer2nodes.tch"),
        File.join(options[:output_dir], "#{options[:prefix]}_o_kmer2nodes.tch"),
        File.join(options[:output_dir], "#{options[:prefix]}_f_kmer2nodes.tch"),
        File.join(options[:output_dir], "#{options[:prefix]}_g_kmer2nodes.tch"),
        File.join(options[:output_dir], "#{options[:prefix]}_s_kmer2nodes.tch"),
      ]

      files.each do |file|
        if File.exist? file
          if options[:force]
            File.unlink file
          else
            raise BioPieces::OptionError, "File exists: #{file} - use 'force: true' to overwrite"
          end
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

              _, seq_name = record[:SEQ_NAME].split(' ', 2)

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

