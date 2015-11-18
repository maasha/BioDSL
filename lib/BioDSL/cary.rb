# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                  #
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
# This software is part of BioDSL (www.BioDSL.org).                              #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioDSL
  # Error class for all exceptions to do with CAry.
  class CAryError < StandardError; end

  # Class to manipulate a Ruby byte array which is fit for inline C manipulation.
  class CAry
    require 'inline'

    attr_reader :count, :size, :ary

    # Class method to store to a given file a given ary.
    def self.store(file, ary)
      File.open(file, 'w') do |ios|
        ios.write([ary.count].pack("I"))
        ios.write([ary.size].pack("I"))
        ios.write(ary.ary)
      end

      nil
    end

    # Class method to retrieve and return an ary from a given file.
    def self.retrieve(file)
      count = nil
      size  = nil
      ary   = nil

      File.open(file) do |ios|
        count = ios.read(4).unpack("I").first
        size  = ios.read(4).unpack("I").first
        ary   = ios.read
      end

      CAry.new(count, size, ary)
    end

    # Method to initialize a new CAry object which is either empty
    # or created from a given byte string. Count is the number of
    # elements in the ary, and size is the byte size of a element.
    def initialize(count, size, ary = nil)
      raise CAryError, "count must be positive - not #{count}" if count <= 0
      raise CAryError, "size must be positive - not #{size}"   if size  <= 0

      @count = count
      @size  = size
      @ary   = ary || "\0" * count * size
    end

    # Method to set all members in an ary to 1.
    def fill!
      self.zero!
      self.~
    end

    # Method to set all members in an ary to 1.
    def fill
      CAry.new(@count, @size).fill!
    end

    # Method to set all members in an ary to zero.
    def zero!
      zero_ary_C(@ary, @count * @size)
      self
    end

    # Method to set all members in an ary to zero.
    def zero
      CAry.new(@count, @size).zero!
    end

    # Method to do bitwise AND operation between two CArys.
    def &(cary)
      raise BioDSL::CAryError, "Bad object type: #{cary.class}" unless cary.is_a? CAry
      raise BioDSL::CAryError, "Counts mismatch: #{self.count} != #{cary.count}" if self.count != cary.count
      raise BioDSL::CAryError, "Sizes mismatch: #{self.size} != #{cary.size}"    if self.size != cary.size

      bitwise_and_C(@ary, cary.ary, @count * @size)

      self
    end

    # Method to do bitwise OR operation between two CArys.
    def |(cary)
      raise BioDSL::CAryError, "Bad object type: #{cary.class}" unless cary.is_a? CAry
      raise BioDSL::CAryError, "Counts mismatch: #{self.count} != #{cary.count}" if self.count != cary.count
      raise BioDSL::CAryError, "Sizes mismatch: #{self.size} != #{cary.size}"    if self.size != cary.size

      bitwise_or_C(@ary, cary.ary, @count * @size)

      self
    end

    # Method to do bitwise XOR operation between two CArys.
    def ^(cary)
      raise BioDSL::CAryError, "Bad object type: #{cary.class}" unless cary.is_a? CAry
      raise BioDSL::CAryError, "Counts mismatch: #{self.count} != #{cary.count}" if self.count != cary.count
      raise BioDSL::CAryError, "Sizes mismatch: #{self.size} != #{cary.size}"    if self.size != cary.size

      bitwise_xor_C(@ary, cary.ary, @count * @size)

      self
    end

    # Method to complement all bits in an ary.
    def ~
      complement_ary_C(@ary, @count * @size)
      self
    end

    # Method that returns a string from an ary.
    def to_s
      @ary.unpack('B*').first
    end

    private

    inline do |builder|
      # Method that given a byte array and its size in bytes
      # sets all bytes to 0.
      builder.c %{
        void zero_ary_C(
          VALUE _ary,       // Byte array to zero.
          VALUE _ary_size   // Size of array.
        )
        {
          char         *ary      = (char *) StringValuePtr(_ary);
          unsigned int  ary_size = FIX2UINT(_ary_size);

          bzero(ary, ary_size);
        }
      }

      # Method that given two byte arrays perform bitwise AND operation
      # beween these and save the result in the first.
      builder.c %{
        void bitwise_and_C(
          VALUE _ary1,      // Byte array to recieve.
          VALUE _ary2,      // Byte array to &.
          VALUE _ary_size   // Size of arrays.
        )
        {
          char         *ary1     = (char *) StringValuePtr(_ary1);
          char         *ary2     = (char *) StringValuePtr(_ary2);
          unsigned int  ary_size = FIX2UINT(_ary_size);
          int           i        = 0;

          for (i = ary_size - 1; i >= 0; i--)
          {
            ary1[i] = ary1[i] & ary2[i];
          }
        }
      }

      # Method that given two byte arrays perform bitwise OR operation
      # beween these and save the result in the first.
      builder.c %{
        void bitwise_or_C(
          VALUE _ary1,      // Byte array to recieve.
          VALUE _ary2,      // Byte array to &.
          VALUE _ary_size   // Size of arrays.
        )
        {
          char         *ary1     = (char *) StringValuePtr(_ary1);
          char         *ary2     = (char *) StringValuePtr(_ary2);
          unsigned int  ary_size = FIX2UINT(_ary_size);
          int           i        = 0;

          for (i = ary_size - 1; i >= 0; i--)
          {
            ary1[i] = ary1[i] | ary2[i];
          }
        }
      }

      # Method that given two byte arrays perform bitwise XOR operation
      # beween these and save the result in the first.
      builder.c %{
        void bitwise_xor_C(
          VALUE _ary1,      // Byte array to recieve.
          VALUE _ary2,      // Byte array to &.
          VALUE _ary_size   // Size of arrays.
        )
        {
          char         *ary1     = (char *) StringValuePtr(_ary1);
          char         *ary2     = (char *) StringValuePtr(_ary2);
          unsigned int  ary_size = FIX2UINT(_ary_size);
          int           i        = 0;

          for (i = ary_size - 1; i >= 0; i--)
          {
            ary1[i] = ary1[i] ^ ary2[i];
          }
        }
      }

      # Method that given a byte array and its size in bytes
      # complements all bits using bitwise ~.
      builder.c %{
        void complement_ary_C(
          VALUE _ary,       // Byte array complement.
          VALUE _ary_size   // Size of array.
        )
        {
          char         *ary      = (char *) StringValuePtr(_ary);
          unsigned int  ary_size = FIX2UINT(_ary_size);
          int           i        = 0;

          for (i = ary_size - 1; i >= 0; i--)
          {
            ary[i] = ~ary[i];
          }
        }
      }
    end
  end
end
