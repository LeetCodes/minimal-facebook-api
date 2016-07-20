#!/usr/bin/env ruby

require 'minimal-facebook-api'
require 'colorize'

puts "[*] Attempting to login".colorize(:color => :cyan)

begin
 interface = Facebook::Authorize.new(:login => ARGV[0], :password => ARGV[1]).interface
rescue ArgumentError => error
 puts "[!] #{error.to_s}".colorize(:color => :red)
end

puts "[*] Fetching friend list".colorize(:color => :cyan)
interface.friends.each_pair do |uid, name|
 first_name, middle_name, last_name = name.values_at(:first_name, :middle_name, :last_name)
 if middle_name
  puts "[+] #{uid} => #{first_name} #{middle_name} #{last_name}"
 else
  puts "[+] #{uid} => #{first_name} #{last_name}"
 end
end
