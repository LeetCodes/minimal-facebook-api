#!/usr/bin/env ruby

require 'colorize'
require 'kashalot'

interface = Kashalot::Facebook::Authorize.new(:login => 'login',
                                              :password => 'password').interface
begin
 interface.friends.each_pair do |uid, name|
  interface.account(:uid => uid).stories.each do |story|
   if story.birthday
    puts "#{story.owner_name.colorize(:color => :red).bold} [#{'BIRTHDAY'.colorize(:color => :yellow)}] =>"
    next
   end
   puts "#{story.owner_name.colorize(:color => :red).bold} [#{story.publish_date.colorize(:color => :yellow)}, C#{story.comments_count.to_s.colorize(:color => :red).bold}, L#{story.likes.to_s.colorize(:color => :red).bold}] =>"
   story.expand if story.expandable?
   puts " #{story.text}"
   story.comments.each do |comment|
    puts "  #{comment.owner_name.colorize(:color => :yellow).bold} [##{comment.id}, #{comment.owner_link.colorize(:color => :yellow)}, L#{comment.likes.to_s.colorize(:color => :cyan).bold}, R#{comment.replies_count.to_s.colorize(:color => :cyan).bold}] =>"
    puts "   #{comment.text.colorize(:color => :white)}"
    comment.replies.each do |reply|
     puts "    #{reply.owner_name.colorize(:color => :green).bold} [##{reply.id}, #{reply.owner_link.colorize(:color => :yellow)}, L#{reply.likes.to_s.colorize(:color => :cyan).bold}] =>"
     puts "     #{reply.text.colorize(:color => :white)}"
    end
   end
   puts
  end
  puts
 end
end
