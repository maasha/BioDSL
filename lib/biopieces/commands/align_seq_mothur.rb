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
  #    BP.new.
  #    read_fasta(input: "test.fna").
  #    align_seq_mothur(template_file: "template.fna").
  #    run
  class AlignSeqMothur
    require 'English'
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/status_helper'
    require 'biopieces/helpers/aux_helper'

    extend OptionsHelper
    include OptionsHelper
    extend AuxHelper
    include AuxHelper
    include StatusHelper

    # Check the options and return a lambda for the command.
    #
    # @param [Hash] options Options hash.
    # @option options [String] :template_file Path to template file.
    # @option options [Integer] :cpus         Number of CPUs to use.
    #
    # @return [Proc] Returns the command lambda.
    def self.lmb(options)
      options_allowed(options, :template_file, :cpus)
      options_required(options, :template_file)
      options_files_exist(options, :template_file)
      options_assert(options, ':cpus >= 1')
      options_assert(options, ":cpus <= #{BioPieces::Config::CORES_MAX}")
      aux_exist('mothur')

      options[:cpus] ||= 1

      new(options).lmb
    end

    # Constructor for the AlignSeqMothur class.
    #
    # @param [Hash] options Options hash.
    # @option options [String] :template_file Path to template file.
    # @option options [Integer] :cpus         Number of CPUs to use.
    #
    # @return [AlignSeqMothur] Returns an instance of the class.
    def initialize(options)
      @options       = options
      @records_in    = 0
      @records_out   = 0
      @sequences_in  = 0
      @sequences_out = 0
      @residues_in   = 0
      @residues_out  = 0
      @tmp_dir       = File.join(Dir.tmpdir, "#{Time.now.to_i}#{$PID}")
      @tmp_in        = File.join(@tmp_dir, 'input.fasta')
      @tmp_out       = File.join(@tmp_dir, 'input.align')

      status_init(:records_in, :records_out, :sequences_in, :sequences_out,
                  :residues_in, :residues_out)
    end

    # Return a lambda for the align_seq_mothur command.
    #
    # @return [Proc] Returns the align_seq_mothur command lambda.
    def lmb
      lambda do |input, output, status|
        begin
          Dir.mkdir(@tmp_dir)

          process_input(input, output)
          run_mothur(@options[:template_file], @options[:cpus])
          process_output(output)
        ensure
          File.unlink('8mer') if File.exist? '8mer'
          FileUtils.rm_rf(@tmp_dir)

          status_assign(status, :records_in, :records_out, :sequences_in,
                                :sequences_out, :residues_in, :residues_out)
        end
      end
    end

    private

    # Process all records in the input stream and write those with sequences to
    # file and all other records to the output stream.
    #
    # @param input  [BioPieces::Stream] The input stream.
    # @param output [BioPieces::Stream] The output stream.
    def process_input(input, output)
      BioPieces::Fasta.open(@tmp_in, 'w') do |ios|
        input.each_with_index do |record, i|
          @records_in += 1

          if record[:SEQ]
            write_entry(ios, record, i)
          else
            output << record
            @records_out += 1
          end
        end
      end
    end

    # Write a record containing sequence information to a FASTA file IO handle.
    # If no sequence_name is found in the record use the sequence index
    # instead.
    #
    # @param ios    [Fasta::IO] FASTA IO.
    # @param record [Hash]      BioPieces record to create FASTA entry from.
    # @param i      [Integer]   Sequence index.
    def write_entry(ios, record, i)
      seq_name = record[:SEQ_NAME] || i.to_s
      entry    = BioPieces::Seq.new(seq_name: seq_name, seq: record[:SEQ])

      @sequences_in += 1
      @residues_in  += entry.length

      ios.puts entry.to_fasta
    end

    # Read all FASTA entries from output file and emit to the output stream.
    #
    # @param output [BioPieces::Stream] The output stream.
    def process_output(output)
      BioPieces::Fasta.open(@tmp_out) do |ios|
        ios.each do |entry|
          output << entry.to_bp
          @records_out   += 1
          @sequences_out += 1
          @residues_out  += entry.length
        end
      end
    end

    # Run Mothur using a system call.
    #
    # @param template_file [String] Path to template file.
    # @param cpus          [Integer] Number of CPUs to use.
    #
    # @raise [RunTimeError] If system call fails.
    def run_mothur(template_file, cpus)
      cmd = <<-CMD.gsub(/^\s+\|/, '').delete("\n")
        |mothur "#set.dir(input=#{@tmp_dir});
        |set.dir(output=#{@tmp_dir});
        |align.seqs(candidate=#{@tmp_in},
        |template=#{template_file},
        |processors=#{cpus})"
      CMD

      if BioPieces.verbose
        system(cmd)
      else
        system("#{cmd} > /dev/null 2>&1")
      end

      fail 'Mothur failed' unless $CHILD_STATUS.success?
    end
  end
end
