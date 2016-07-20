#!/usr/bin/env ruby

require 'minimal-facebook-api'
require 'colorize'

def display_info
 puts "[*] #{__FILE__.colorize(:color => :red)} <login> <password>"
 puts "[*] Displays UID of every friend in your friendlist"
 exit
end

def main
 display_info if ARGV.size != 2
 puts "[*] Attempting to login"
 begin
  interface = Facebook::Authorize.new(:login => ARGV[0], :password => ARGV[1]).interface
  puts "[*] Fetching friend list"
  interface.friends.each_pair do |uid, name|
   first_name, middle_name, last_name = name.values_at(:first_name, :middle_name, :last_name)
   print "[+] #{uid.colorize(:color => :green)} => #{first_name.colorize(:color => :yellow)}"
   print " #{middle_name.colorize(:color => :yellow)}" if middle_name
   print " #{last_name.colorize(:color => :yellow)}" if last_name
   puts
  end
 rescue RuntimeError, ArgumentError => error
  print "[!] ".colorize(:color => :red)
  puts error.to_s
 end
end

main
