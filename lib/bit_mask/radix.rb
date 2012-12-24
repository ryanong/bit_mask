class BitMask
  module Radix
    class << self
      def integer_to_string(integer, characters)
        characters = process_characters(characters)
        radix = characters.length

        result = ''
        while integer != 0
          result += characters[integer%radix]
          integer /= radix
        end
        result.reverse
      end

      def string_to_integer(string, characters)
        characters = process_characters(characters)
        radix = characters.length

        int_val = 0
        string.reverse.split('').each_with_index do |char,index|
          if char_index = characters.index(char)
            int_val += (char_index)*(radix**(index))
          else
            raise ArgumentError, "Character #{char} at index #{index} is not a valid character for Base #{characters} String."
          end
        end
        int_val
      end

      private

      def process_characters(characters)
        if characters.is_a? String
          characters = characters.split('')
        end
        if characters != characters.uniq
          raise ArgumentError, "There are duplicate characters in #{characters}"
        end
        characters
      end
    end
  end
end
