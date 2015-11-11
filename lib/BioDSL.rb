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
# This software is part of BioDSL (www.github.com/maasha/BioDSL).              #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

fail 'Ruby 2.0 or later required' if RUBY_VERSION < '2.0'

# Commify numbers.
class Numeric
  def commify
    to_s.gsub(/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/, '\1,')
  end
end

# Convert string to float or integer if applicable.
class String
  def to_num
    Integer(self)
    to_i
  rescue ArgumentError
    begin
      Float(self)
      to_f
    rescue ArgumentError
      self
    end
  end
end

# Namespace for BioDSL.
module BioDSL
  require 'pp'
  require 'BioDSL/cary'
  require 'BioDSL/commands'
  require 'BioDSL/debug'
  require 'BioDSL/helpers'
  require 'BioDSL/seq'
  require 'BioDSL/config'
  require 'BioDSL/hamming'
  require 'BioDSL/version'
  require 'BioDSL/filesys'
  require 'BioDSL/csv'
  require 'BioDSL/fork'
  require 'BioDSL/html_report'
  require 'BioDSL/pipeline'
  require 'BioDSL/fasta'
  require 'BioDSL/fastq'
  require 'BioDSL/math'
  require 'BioDSL/mummer'
  require 'BioDSL/taxonomy'
  require 'BioDSL/tmp_dir'
  require 'BioDSL/serializer'
  require 'BioDSL/stream'
  require 'BioDSL/test'
  require 'BioDSL/usearch'
  require 'BioDSL/verbose'
end

BD = BioDSL::Pipeline # Module alias for irb short hand
