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
# This software is part of the BioDSL (www.BioDSL.org).                        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioDSL
  # == Align sequences in the stream using Mothur.
  #
  # This is a wrapper for the +mothur+ command +align.seqs()+. Basically,
  # it aligns sequences to a reference alignment.
  #
  # Please refer to the manual:
  #
  # http://www.mothur.org/wiki/Align.seqs
  #
  # Mothur must be installed for +align_seq_mothurs+ to work. Read more here:
  #
  # http://www.mothur.org/
  #
  # == Usage
  #
  #    align_seq_mothur(<template_file: <file>>[, cpus: <uint>])
  #
  # === Options
  #
  # * template_file: <file>  - File with template alignment in FASTA format.
  # * cpus: <uint>           - Number of CPU cores to use (default=1).
  #
  # == Examples
  #
  # To align the entries in the FASTA file `test.fna` to the template alignment
  # in the file `template.fna` do:
  #
  #    BD.new.
  #    read_fasta(input: "test.fna").
  #    align_seq_mothur(template_file: "template.fna").
  #    run
  class AlignSeqMothur
    require 'English'
    require 'BioDSL/helpers/aux_helper'

    include AuxHelper

    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Constructor for the AlignSeqMothur class.
    #
    # @param [Hash] options Options hash.
    # @option options [String] :template_file Path to template file.
    # @option options [Integer] :cpus         Number of CPUs to use.
    #
    # @return [AlignSeqMothur] Returns an instance of the class.
    def initialize(options)
      @options = options

      aux_exist('mothur')
      check_options
      defaults
    end

    # Return a lambda for the align_seq_mothur command.
    #
    # @return [Proc] Returns the align_seq_mothur command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        TmpDir.create('input.fna', 'input.align') do |tmp_in, tmp_out, tmp_dir|
          process_input(input, output, tmp_in)
          run_mothur(@options[:template_file], @options[:cpus], tmp_dir, tmp_in)
          process_output(output, tmp_out)
        end
      end
    end

    private

    # Check the options.
    def check_options
      options_allowed(@options, :template_file, :cpus)
      options_required(@options, :template_file)
      options_files_exist(@options, :template_file)
      options_assert(@options, ':cpus >= 1')
      options_assert(@options, ":cpus <= #{BioDSL::Config::CORES_MAX}")
    end

    # Set default options.
    def defaults
      @options[:cpus] ||= 1
    end

    # Process all records in the input stream and write those with sequences to
    # file and all other records to the output stream.
    #
    # @param input  [BioDSL::Stream] The input stream.
    # @param output [BioDSL::Stream] The output stream.
    # @param tmp_in [String]            Path to temporary file.
    def process_input(input, output, tmp_in)
      BioDSL::Fasta.open(tmp_in, 'w') do |ios|
        input.each_with_index do |record, i|
          @status[:records_in] += 1

          if record[:SEQ]
            write_entry(ios, record, i)
          else
            output << record
            @status[:records_out] += 1
          end
        end
      end
    end

    # Write a record containing sequence information to a FASTA file IO handle.
    # If no sequence_name is found in the record use the sequence index
    # instead.
    #
    # @param ios    [Fasta::IO] FASTA IO.
    # @param record [Hash]      BioDSL record to create FASTA entry from.
    # @param i      [Integer]   Sequence index.
    def write_entry(ios, record, i)
      seq_name = record[:SEQ_NAME] || i.to_s
      entry    = BioDSL::Seq.new(seq_name: seq_name, seq: record[:SEQ])

      @status[:sequences_in] += 1
      @status[:residues_in] += entry.length

      ios.puts entry.to_fasta
    end

    # Read all FASTA entries from output file and emit to the output stream.
    #
    # @param output  [BioDSL::Stream] The output stream.
    # @param tmp_out [String]            Path to temporary file.
    def process_output(output, tmp_out)
      BioDSL::Fasta.open(tmp_out) do |ios|
        ios.each do |entry|
          output << entry.to_bp
          @status[:records_out] += 1
          @status[:sequences_out] += 1
          @status[:residues_out] += entry.length
        end
      end
    end

    # Run Mothur using a system call.
    #
    # @param template_file [String]  Path to template file.
    # @param cpus          [Integer] Number of CPUs to use.
    # @param tmp_dir       [String]  Path to temporary dir.
    # @param tmp_in        [String]  Path to temporary file.
    #
    # @raise [RunTimeError] If system call fails.
    def run_mothur(template_file, cpus, tmp_dir, tmp_in)
      cmd = <<-CMD.gsub(/^\s+\|/, '').delete("\n")
        |mothur "#set.dir(input=#{tmp_dir});
        |set.dir(output=#{tmp_dir});
        |align.seqs(candidate=#{tmp_in},
        |template=#{template_file},
        |processors=#{cpus})"
      CMD

      if BioDSL.verbose
        system(cmd)
      else
        system("#{cmd} > /dev/null 2>&1")
      end

      fail 'Mothur failed' unless $CHILD_STATUS.success?
    end
  end
end
