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
# This software is part of Biopieces (www.biopieces.org).                      #
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

# Namespace for BioPieces.
module BioPieces
  require 'pp'
  require 'biopieces/cary'
  require 'biopieces/commands'
  require 'biopieces/debug'
  require 'biopieces/helpers'
  require 'biopieces/seq'
  require 'biopieces/config'
  require 'biopieces/hamming'
  require 'biopieces/version'
  require 'biopieces/filesys'
  require 'biopieces/csv'
  require 'biopieces/fork'
  require 'biopieces/html_report'
  require 'biopieces/pipeline'
  require 'biopieces/fasta'
  require 'biopieces/fastq'
  require 'biopieces/math'
  require 'biopieces/mummer'
  require 'biopieces/taxonomy'
  require 'biopieces/tmp_dir'
  require 'biopieces/serializer'
  require 'biopieces/stream'
  require 'biopieces/test'
  require 'biopieces/usearch'
  require 'biopieces/verbose'
end

BP = BioPieces::Pipeline # Module alias for irb short hand
