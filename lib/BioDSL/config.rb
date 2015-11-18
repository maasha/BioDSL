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
  # Module with Config constants.
  module Config
    require 'parallel'
    require 'BioDSL/helpers/options_helper'

    extend OptionsHelper

    HISTORY_FILE             = File.join(ENV['HOME'], '.BioDSL_history')
    LOG_FILE                 = File.join(ENV['HOME'], '.BioDSL_log')
    RC_FILE                  = File.join(ENV['HOME'], '.BioDSLrc')
    STATUS_PROGRESS_INTERVAL = 0.1   # update progress every n second.

    options = options_load_rc({}, :pipeline)

    TMP_DIR = if options && !options[:tmp_dir].empty?
                options[:tmp_dir].first
              else
                Dir.tmpdir
              end

    CORES_MAX = if options && !options[:processor_count].empty?
                  options[:processor_count].first.to_i
                else
                  Parallel.processor_count
                end
  end
end
