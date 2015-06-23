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
# This software is part of the Biopieces framework (www.biopieces.org).        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  # == Run classify_seq_mothur on sequences in the stream.
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
  # Mothur must be installed for +classify_seq_mothurs+ to work. Read more here:
  #
  # http://www.mothur.org/
  #
  # == Usage
  #
  #    classify_seq_mothur(<database: <file>>, <taxonomy: <file>>
  #                        [, confidence: <uint>[, cpus: <uint>]])
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
  #    classify_seq_mothur(database: database, taxonomy: taxonomy).
  #    grab(exact: true, keys: :RECORD_TYPE, select: "taxonomy").
  #    write_table(output: "classified.tab", header: true, force: true,
  #                skip: [:RECORD_TYPE]).
  #    run
  class ClassifySeqMothur
    require 'English'
    require 'biopieces/helpers/aux_helper'

    include AuxHelper

    STATS = %i(records_in records_out sequences_in sequences_out
               residues_in residues_out)

    # Constructor for ClassifySeqMothur.
    #
    # @param options [Hash] Options hash.
    # @option options [String] :database Path to database file.
    # @option options [String] :taxonomy Path to taxonomy file.
    # @option options [Integer] :confidence Confidence cutoff.
    # @option options [Integer] :cpus Number of CPUs to use.
    #
    # @return [ClassifySeqMothur] Instance of class.
    def initialize(options)
      @options = options

      aux_exist('mothur')
      check_options
      defaults
    end

    # Command lambda for ClassifySeqMothur.
    #
    # @return [Proc] Lambda for the command.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        TmpDir.create('input.fasta') do |tmp_in, tmp_dir|
          process_input(input, output, tmp_in)
          run_mothur(tmp_dir, tmp_in)
          tmp_out = Dir.glob("#{tmp_dir}/input.*.taxonomy").first
          process_output(output, tmp_out)
        end
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :database, :taxonomy, :confidence, :cpus)
      options_required(@options, :database, :taxonomy)
      options_files_exist(@options, :database, :taxonomy)
      options_assert(@options, ':confidence > 0')
      options_assert(@options, ':confidence <= 100')
      options_assert(@options, ':cpus >= 1')
      options_assert(@options, ":cpus <= #{BioPieces::Config::CORES_MAX}")

      defaults
    end

    # Set default options.
    def defaults
      @options[:confidence] ||= 80
      @options[:cpus]       ||= 1
    end

    # Process input data and save sequences to a temporary file for
    # classifcation.
    #
    # @param input  [Enumerator] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    # @param tmp_in [String] Path to temporary FASTA file.
    def process_input(input, output, tmp_in)
      BioPieces::Fasta.open(tmp_in, 'w') do |ios|
        input.each_with_index do |record, i|
          @status[:records_in] += 1

          if record[:SEQ]
            @status[:sequences_in]  += 1
            @status[:sequences_out] += 1
            @status[:residues_in]   += record[:SEQ].length
            @status[:records_out]   += record[:SEQ].length
            seq_name = record[:SEQ_NAME] || i.to_s

            entry = BioPieces::Seq.new(seq_name: seq_name, seq: record[:SEQ])

            ios.puts entry.to_fasta
          end

          output << record
          @status[:records_out] += 1
        end
      end
    end

    # Run Mothur using a system call.
    #
    # @param tmp_dir [String] Path to temporary dir.
    # @param tmp_in  [String] Path to input file.
    #
    # @raise [RunTimeError] If system call fails.
    def run_mothur(tmp_dir, tmp_in)
      cmd = <<-CMD.gsub(/^\s+\|/, '').delete("\n")
        |mothur "#set.dir(input=#{tmp_dir});
        |set.dir(output=#{tmp_dir});
        |classify.seqs(fasta=#{tmp_in},
        |reference=#{@options[:database]},
        |taxonomy=#{@options[:taxonomy]},
        |method=wang,
        |processors=#{@options[:cpus]})"
      CMD

      BioPieces.verbose ? system(cmd) : system("#{cmd} > /dev/null 2>&1")

      fail 'Mothur failed' unless $CHILD_STATUS.success?
    end

    # Parse mothur classfication output and emit to stream.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param tmp_out [String] Path to file with classfication result.
    def process_output(output, tmp_out)
      BioPieces::CSV.open(tmp_out) do |ios|
        ios.each_hash do |new_record|
          new_record[:SEQ_NAME] = new_record[:V0]
          new_record[:TAXONOMY] = new_record[:V1]
          new_record[:TAXONOMY].tr!('"', '')
          new_record.delete(:V0)
          new_record.delete(:V1)
          new_record[:TAXONOMY]    = confidence_filter(new_record)
          new_record[:RECORD_TYPE] = 'taxonomy'
          output << new_record
          @status[:records_out] += 1
        end
      end
    end

    # Filter taxonomic leveles based on the confidence.
    #
    # @param record [Hash] BioPieces record with taxonomy.
    #
    # @return [String] Return taxonomic string.
    def confidence_filter(record)
      new_levels = []

      record[:TAXONOMY].split(';').each do |level|
        next unless level =~ /^([^(]+)\((\d+)\)$/
        name       = Regexp.last_match(1)
        confidence = Regexp.last_match(2).to_i

        if confidence >= @options[:confidence]
          new_levels << "#{name}(#{confidence})"
        end
      end

      new_levels.empty? ? 'Unclassified' : new_levels.join(';')
    end
  end
end
