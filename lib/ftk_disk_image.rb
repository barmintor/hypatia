require "rubygems"
require "active-fedora"

class FtkDiskImage
  
  # The txt file produced by FTK that contains the metadata about this disk image
  attr_accessor :txt_file
  # The number used to identify this disk
  attr_accessor :disk_number
  # The kind of disk this was (e.g., "5.25 inch Floppy Disk")
  attr_accessor :disk_type
  # The md5 checksum for the disk image
  attr_accessor :md5
  # The sha1 checksum for the disk image
  attr_accessor :sha1
  
  def initialize(args = {})
    if args[:txt_file]
      raise "Can't find txt file #{args[:txt_file]}" unless File.file? args[:txt_file]
      @txt_file = args[:txt_file]
      process_file
    end
  end
  
  # Go through the .txt file and extract the useful information
  def process_file
    lines_array = open(@txt_file) { |f| f.readlines }
    lines_array.each_with_index{|line, index| 
      case line
      when /Evidence Number/
        @disk_number = get_value_after_colon(line)
      when /Notes/
        @disk_type = get_value_after_colon(line)
      when /MD5/
        @md5 ||= get_value_after_colon(line)
      when /SHA15/
        @sha1 ||= get_value_after_colon(line)
      end
    }
  end

  # Take a String that looks like "Evidence Number: CM006" and extract the value after the colon
  # @param [String] line
  # @return [String] value after the colon (e.g. "CM006")
  def get_value_after_colon(line)
    line.split(': ').last.strip
  end
  
end