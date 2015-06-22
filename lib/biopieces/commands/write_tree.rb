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
  # == Write aligned sequences from stream as a tree.
  #
  # Description
  #
  # +write_tree+ takes aligned sequences from the stream and uses FastTree to to
  # create a distance tree between the sequences. The tree is in Newick format.
  # FastTree must be installed.
  #
  # For more about the FastTree here:
  #
  # http://www.microbesonline.org/fasttree/
  #
  # == Usage
  #    write_tree([, output: <file>[, force: <bool>[, type: <string>]]])
  #
  # === Options
  # * output <file> - Output file.
  # * force <bool>  - Force overwrite existing output file.
  # * type <string> - Sequence type :dna|:rna|:protein (default=:dna).
  #
  # == Examples
  #
  # To create a tree from aligned FASTA sequences in the file `align.fna` do:
  #
  #    BP.new.
  #    read_fasta(input: "align.fna").
  #    write_tree(output: "align.tree").
  #    run
  class WriteTree
    require 'open3'
    require 'biopieces/helpers/aux_helper'

    include AuxHelper

    STATS = %i(records_in records_out sequences_in residues_in)

    # Constructor for WriteTree.
    #
    # @param options  [Hash]    Options hash.
    # @option options [String]  :output
    # @option options [Boolean] :force
    # @option options [Symbol]  :type
    #
    # @return [WriteTree] Class instance.
    def initialize(options)
      @options = options

      aux_exist('FastTree')
      check_options
      status_init(STATS)

      @cmd = compile_command
    end

    # rubocop: disable Metrics/AbcSize

    # Return command lambda for write_tree.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        Open3.popen3(@cmd) do |stdin, stdout, stderr, wait_thr|
          input.each_with_index do |record, i|
            @status[:records_in] += 1

            write_seq(stdin, record, i) if record[:SEQ]

            output << record && @status[:records_out] += 1 if output
          end

          stdin.close

          tree_data = stdout.read.chomp

          stdout.close

          exit_status = wait_thr.value

          fail stderr.read unless exit_status.success?

          write_tree(tree_data)
        end

        status_assign(status, STATS)
      end
    end

    # rubocop: enable Metrics/AbcSize

    private

    # Check options.
    def check_options
      options_allowed(@options, :force, :output, :type)
      options_allowed_values(@options, type: [:dna, :rna, :protein])
      options_files_exist_force(@options, :output)
    end

    # Compile command for running FastTree.
    #
    # @return [String] FastTree command.
    def compile_command
      cmd = []
      cmd << 'FastTree'
      cmd << '-nt'    unless @options[:type] == :protein
      cmd << '-quiet' unless BioPieces.verbose
      cmd.join(' ')
    end

    # Write a record with sequence to stdin.
    #
    # @param stdin  [IO]      Open3 IO.
    # @param record [Hash]    BioPieces record.
    # @param i      [Integer] Record index.
    def write_seq(stdin, record, i)
      entry = BioPieces::Seq.new_bp(record)
      entry.seq_name ||= i

      @status[:sequences_in] += 1
      @status[:residues_in]  += entry.length

      stdin.puts entry.to_fasta
    end

    # Write tree data to file or stdout.
    #
    # @param tree_data [String] Tree data in Newick format.
    def write_tree(tree_data)
      if @options[:output]
        File.open(@options[:output], 'w') do |ios|
          ios.puts tree_data
        end
      else
        puts tree_data
      end
    end
  end
end
