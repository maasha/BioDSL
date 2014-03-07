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
# This software is part of the Biopieces framework (www.biopieces.org).          #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

raise "Ruby 2.0 or later required" if RUBY_VERSION < "2.0"

module BioPieces
  require 'pp'
  require 'msgpack'
  require 'inline'
  require 'mail'
  require 'narray'
  require 'open3'
  require 'stringio'
  require 'tempfile'
  require 'biopieces/commands'
  require 'biopieces/helpers'
  require 'biopieces/string'
  require 'biopieces/seq'
  autoload :Config,   'biopieces/config'
  autoload :Version,  'biopieces/version'
  autoload :Filesys,  'biopieces/filesys'
  autoload :Pipeline, 'biopieces/pipeline'
  autoload :Fasta,    'biopieces/fasta'
  autoload :Math,     'biopieces/math'
end

BP = BioPieces::Pipeline # Module alias for irb short hand
