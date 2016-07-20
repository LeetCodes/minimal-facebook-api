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
  account.stories.each do |story|
   puts "[+] #{story.owner_name.colorize(:color => :green).bold} '#{story.owner_link.colorize(:color => :yellow)}' at #{story.publish_date} [L#{story.likes.to_s.colorize(:color => :cyan).bold}, C#{story.comments_count.to_s.colorize(:color => :cyan).bold}, R#{story.resources.size.to_s.colorize(:color => :cyan).bold}]"
   story.expand if story.expandable?
   puts "    #{story.text}" unless story.text.empty?
   story.comments.each_with_index do |comment, index|
    puts "    [#{index}] #{comment.owner_name.colorize(:color => :red).bold} '#{comment.owner_link.colorize(:color => :yellow)}' [L#{comment.likes.to_s.colorize(:color => :cyan).bold}, R#{comment.replies_count.to_s.colorize(:color => :cyan).bold}]"
    puts "     #{comment.text}" unless comment.text.empty?
    comment.replies.each_with_index do |reply, _index|
     puts "       [#{_index}] #{reply.owner_name.colorize(:color => :green).bold} '#{reply.owner_link.colorize(:color => :yellow)}' [L#{reply.likes.to_s.colorize(:color => :cyan).bold}]"
     puts "        #{reply.text}" unless reply.text.empty?
    end
   end
  end
 rescue RuntimeError, ArgumentError => error
  print "[!] ".colorize(:color => :red)
  puts error.to_s
 end
end

main
