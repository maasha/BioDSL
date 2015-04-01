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
  # Module for creating a namespace for all Commands.
  module Commands
    # == Filter rRNA sequences from the stream.
    #
    # Description
    #
    # +filter_rrna+ utilizes +sortmerna+ to identify and filter ribosomal RNA
    # sequences from the stream. The +sortmerna+ and +indexdb_rna+ executables
    # must be installed for +filter_rrna+ to work.
    #
    # Indexed reference files are produced using +indexdb_rna+.
    #
    # For more about the sortmerna look here:
    #
    # http://bioinfo.lifl.fr/RNA/sortmerna/
    #
    # == Usage
    #    filter_rrna(ref_fasta: <file(s)>, ref_index: <file(s)>)
    #
    # === Options
    # * ref_fasta <file(s)> - One or more reference FASTA files.
    # * ref_index <file(s)> - One or more index reference files.
    #
    # == Examples
    #
    # To filter all reads matching the SILVA archaea 23S rRNA do:
    #
    #    BP.new.
    #    read_fastq(input: "reads.fq").
    #    filter_rrna(ref_fasta: ["silva-arc-23s-id98.fasta"],
    #                ref_index: ["silva-arc-23s-id98.fasta.idx*"]).
    #    write_fastq(output: "clean.fq").
    #    run
    #
    def filter_rrna(options = {})
      require_relative 'filter_rrna/filter_rrna'

      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :ref_fasta, :ref_index)
      options_files_exist(options, :ref_fasta, :ref_index)
      aux_exist("sortmerna")

      lmb = FilterRrna.run(options)

      @commands << BioPieces::Pipeline::Command.new(__method__, options,
                                                    options_orig, lmb)

      self
    end
  end
end
