#!/usr/bin/env ruby

require 'minimal-facebook-api'
require 'colorize'

def display_info
 puts "[*] #{__FILE__.colorize(:color => :red)} <login> <password>"
 puts "[*] This script displays email addresses"
 exit
end

def main
 display_info if ARGV.size != 2
 puts "[*] Attempting to login"
 begin
  interface = Facebook::Authorize.new(:login => ARGV[0], :password => ARGV[1]).interface
  interface.emails.each do |email|
   puts "[+] #{email.colorize(:color => :green)}"
  end
 rescue RuntimeError, ArgumentError => error
  print "[!] ".colorize(:color => :red)
  puts error.to_s
 end
end

main
