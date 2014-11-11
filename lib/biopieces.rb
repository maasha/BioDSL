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

raise "Ruby 2.0 or later required" if RUBY_VERSION < "2.0"

# Commify numbers.
class Numeric
  def commify
    self.to_s.gsub(/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/, '\1,')
  end
end

# Convert string to float or integer if applicable.
class String
  def to_num
    begin
      Integer(self)
      self.to_i
    rescue ArgumentError
      begin
        Float(self)
        self.to_f
      rescue ArgumentError
        self
      end
    end
  end
end

module BioPieces
  require 'biopieces/cary'
  require 'biopieces/commands'
  require 'biopieces/helpers'
  require 'biopieces/seq'
  require 'biopieces/config'
  require 'biopieces/hamming'
  require 'biopieces/version'
  require 'biopieces/filesys'
  require 'biopieces/csv'
  require 'biopieces/fork'
  require 'biopieces/gnuplot'
  require 'biopieces/render'
  require 'biopieces/pipeline'
  require 'biopieces/fasta'
  require 'biopieces/fastq'
  require 'biopieces/math'
  require 'biopieces/stream'
  require 'biopieces/usearch'
end

BP = BioPieces::Pipeline # Module alias for irb short hand
