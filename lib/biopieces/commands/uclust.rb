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
    # == Run uclust on sequences in the stream.
    # 
    # This is a wrapper for the +usearch+ tool to run the program uclust.
    # Basically sequence type records are clustered de-novo and records
    # containing sequence and cluster information is output. If the +align+
    # option is given the sequnces will be aligned.
    #
    # Please refer to the manual:
    #
    # http://www.drive5.com/usearch/manual/cmd_cluster_smallmem.html
    #
    # Usearch 7.0 must be installed for +usearch+ to work. Read more here:
    #
    # http://www.drive5.com/usearch/
    # 
    # == Usage
    # 
    #    uclust(<identity: float>, <strand: "plus|both">[, align: <bool>[, cpus: <uint>]])
    # 
    # === Options
    #
    # * identity: <float>  - Similarity for matching in percent between 0.0 and 1.0.
    # * strand:   <string> - For nucleotide search report hits from plus or both strands.
    # * align:    <bool>   - Align sequences.
    # * cpus:     <uint>   - Number of CPU cores to use (default=1).
    #
    # == Examples
    # 
    def uclust(options = {})
      require 'parallel'

      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :identity, :strand, :align, :cpus)
      options_required(options, :identity, :strand)
      options_allowed_values(options, strand: ["plus", "both", :plus, :both])
      options_allowed_values(options, align:  [nil, false, true])
      options_assert(options, ":identity >  0.0")
      options_assert(options, ":identity <= 1.0")
      options_assert(options, ":cpus >= 1")
      options_assert(options, ":cpus <= #{Parallel.processor_count}")

      options[:cpus] ||= 1

      lmb = lambda do |input, output, status|
        status[:sequences_in] = 0

        status_track(status) do
          begin
            tmp_in  = Tempfile.new("uclust")
            tmp_out = Tempfile.new("uclust")

            BioPieces::Fasta.open(tmp_in, 'w') do |ios|
              input.each_with_index do |record, i|
                status[:records_in] += 1


                if record[:SEQ]
                  status[:sequences_in] += 1
                  seq_name = record[:SEQ_NAME] || i.to_s

                  entry = BioPieces::Seq.new(seq_name: seq_name, seq: record[:SEQ])

                  ios.puts entry.to_fasta
                else
                  output << record

                  status[:records_out] += 1
                end
              end
            end

            begin
              BioPieces::Usearch.cluster_smallmem(input: tmp_in, 
                                                  output: tmp_out,
                                                  strand: options[:strand],
                                                  identity: options[:identity],
                                                  align: options[:align],
                                                  cpus: options[:cpus],
                                                  verbose: options[:verbose])

              if options[:align]
                cluster = 0

                BioPieces::Fasta.open(tmp_out) do |ios|
                  ios.each do |entry|
                    if entry.seq_name == 'consensus'
                      cluster += 1
                    else
                      record = {}
                      record[:RECORD_TYPE] = "uclust"
                      record[:CLUSTER]     = cluster
                      record.merge!(entry.to_bp)

                      output << record
                      status[:records_out] += 1
                    end
                  end
                end
              else
                BioPieces::Usearch.open(tmp_out) do |ios|
                  ios.each(:uc) do |record|
                    record[:RECORD_TYPE] = "uclust"
                    output << record
                    status[:records_out] += 1
                  end
                end
              end
            rescue BioPieces::UsearchError => e
              unless e.message =~ /Empty input file/
                raise
              end
            end
          ensure
            tmp_in.unlink
            tmp_out.unlink
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

