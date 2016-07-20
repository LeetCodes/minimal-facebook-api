#!/usr/bin/env ruby

require 'minimal-facebook-api'
require 'colorize'

def display_info
 puts "[*] #{__FILE__.colorize(:color => :red)} <login> <password> <uid | link>"
 puts "[*] This script enumerates friends of targeted account"
 print "[*] "
 print "NOTE: ".colorize(:color => :red)
 puts "The list depends on privacy settings of account you will to scan"
 exit
end

def main
 display_info if ARGV.size != 3
 puts "[*] Attempting to login"
 begin
  interface = Facebook::Authorize.new(:login => ARGV[0], :password => ARGV[1]).interface
  puts "[*] Searching for #{ARGV[2].colorize(:color => :cyan)}"
  if ARGV[2] =~ /^\d+$/
   account = interface.account(:uid => ARGV[2])
  else
   account = interface.account(:link => ARGV[2])
  end
  account.friends.each_pair do |key, value|
   print "[+] #{key.to_s.colorize(:color => :green)} => #{value[:first_name].colorize(:color => :yellow)}"
   print " #{value[:middle_name].colorize(:color => :yellow)}" if value[:middle_name]
   print " #{value[:last_name].colorize(:color => :yellow)}" if value[:last_name]
   puts
  end
 rescue RuntimeError, ArgumentError => error
  print "[!] ".colorize(:color => :red)
  puts error.to_s
 end
end

main
