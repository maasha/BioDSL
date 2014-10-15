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
  module Commands
    require 'biopieces/commands/add_key'
    require 'biopieces/commands/assemble_pairs'
    require 'biopieces/commands/clip_primer'
    require 'biopieces/commands/cluster_otus'
    require 'biopieces/commands/collect_otus'
    require 'biopieces/commands/dereplicate_seq'
    require 'biopieces/commands/dump'
    require 'biopieces/commands/grab'
    require 'biopieces/commands/mean_scores'
    require 'biopieces/commands/merge_values'
    require 'biopieces/commands/plot_histogram'
    require 'biopieces/commands/plot_scores'
    require 'biopieces/commands/read_fasta'
    require 'biopieces/commands/read_fastq'
    require 'biopieces/commands/read_table'
    require 'biopieces/commands/sort'
    require 'biopieces/commands/split_values'
    require 'biopieces/commands/trim_primer'
    require 'biopieces/commands/trim_seq'
    require 'biopieces/commands/uchime_ref'
    require 'biopieces/commands/usearch_global'
    require 'biopieces/commands/write_fasta'
    require 'biopieces/commands/write_fastq'
    require 'biopieces/commands/write_table'
  end
end
