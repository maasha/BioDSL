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
# This software is part of Biopieces (www.biopieces.org).                      #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
module BioPieces
  # Command class for initiating and calling commands.
  class Command
    attr_reader :name, :status

    # Constructor for Command objects.
    #
    # @param name    [Symbol] Name of command.
    # @param lmb     [Proc]   Lambda for command callback execution.
    # @param options [Hash]   Options hash.
    def initialize(name, lmb, options)
      @name    = name
      @lmb     = lmb
      @options = options
      @status  = Status.new(name, options)
    end

    # Callback method for executing a Command lambda.
    #
    # @param args [Array] List of arguments used in the callback.
    def call(*args)
      @lmb.call(*args, @status)
    end

    # Terminate the status.
    def terminate
      @status.terminate
    end

    # Return string representation of a Command object.
    #
    # @return [String] With formated command.
    def to_s
      options_list = []

      @options.each do |key, value|
        options_list << case value.class.to_s
                        when 'String'
                          value = Regexp.quote(value) if key == :delimiter
                          %(#{key}: "#{value}")
                        when 'Symbol'
                          "#{key}: :#{value}"
                        else
                          "#{key}: #{value}"
                        end
      end

      @options.empty? ? @name : "#{@name}(#{options_list.join(', ')})"
    end
  end
end
