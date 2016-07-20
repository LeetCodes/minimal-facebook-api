#!/usr/bin/env ruby

require 'minimal-facebook-api'
require 'colorize'

def display_info
 puts "[*] #{__FILE__.colorize(:color => :red)} <login> <password> <uid | link>"
 puts "[*] This script displays info about certain facebook profile"
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
  account.info.each_pair do |key, value|
   puts "[+] #{key.to_s.colorize(:color => :green)} => #{value.colorize(:color => :yellow)}"
  end
 rescue RuntimeError, ArgumentError => error
  print "[!] ".colorize(:color => :red)
  puts error.to_s
 end
end

main
