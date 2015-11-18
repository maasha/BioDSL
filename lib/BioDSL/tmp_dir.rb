# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
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
# This software is part of BioDSL (http://maasha.github.io/BioDSL).            #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
module BioDSL
  # Module to provide a temporary directory.
  module TmpDir
    require 'tempfile'

    # Create a temporary directory in block context. The directory is deleted
    # when the TmpDir object is garbage collected or the Ruby intepreter exits.
    # If called with a list of filenames, these are provided as block arguments
    # such that the files parent are the temporary directory. However, the last
    # block argument is always the path to the temporary directory.
    #
    # @param files [Array] List of file names.
    #
    # @example
    #   BioDSL::TmpDir.create do |dir|
    #     puts dir
    #       # => "<tmp_dir>"
    #   end
    #
    # @example
    #   BioDSL::TmpDir.create("foo", "bar") do |foo, bar, dir|
    #     puts foo
    #       # => "<tmp_dir>/foo"
    #     puts bar
    #       # => "<tmp_dir>/foo"
    #     puts dir
    #       # => "<tmp_dir>"
    #   end
    def self.create(*files, &block)
      fail 'no block given' unless block

      Dir.mktmpdir(nil, BioDSL::Config::TMP_DIR) do |dir|
        paths = files.each_with_object([]) { |e, a| a << File.join(dir, e) }

        if paths.empty?
          block.call(dir)
        else
          block.call(paths << dir)
        end
      end
    end
  end
end
