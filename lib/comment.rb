module Facebook
 class Comment

  attr_reader :id, :owner_name, :owner_link, :text, :likes, :replies_count

  def initialize(_parameters)
   raise ArgumentError.new("No comment") if _parameters[:comment].nil?
   raise ArgumentError.new("No Mechanize agent") if _parameters[:agent].nil?
   @comment, @agent = _parameters[:comment], _parameters[:agent].dup

   initialize_body
  end
  def initialize_body
   # Get comment ID
   @id = @comment['id']
   # Get owner info
   owner = @comment.xpath("./h3/a[1]")[0]
   @owner_name = owner.text
   @owner_link = Facebook::strip_uri(owner['href'])
   # Get message text
   @text = @comment.xpath('./div[1]').text
   @likes = 0
   @replies_count = 0
   # Find a pattern for comment interface like "Edit, Like, Report etc."
   interface_pattern = String.new
   unless @comment.xpath('./div[last()]/div[@id]').empty?
    # This comment has replies
    interface_pattern = "./div[last()-1]//a"
    @replies_link = @comment.xpath('./div[last()]/div[@id]/div/a')[0]['href']
    @replies_count = @comment.xpath('./div[last()]/div[@id]/div/a').text.split(' ')[0].to_i
   else
    # This comment has no replies
    interface_pattern = "./div[last()]//a"
   end
   @comment.xpath("#{interface_pattern}").each do |interface|
    case interface.text.to_s
    when "Like"
     @liked = false
     @like_link = interface['href']
    when "Unlike"
     @liked = true
     @like_link = interface['href']
    when "Report"
     @report_link = interface['href']
    when "Reply"
     @reply_link = interface['href']
    when /^(\d+)$/
     @likes = $1
    end
   end
  end
  def like()
   return false if @like_link.nil?
   @agent.get(@like_link)
   return true
  end
  def liked?()
   return @liked
  end
  def replies()
   return Array.new if @replies_link.nil? or @replies_count == 0
   previous_replies = @replies_link
   entries = Array.new
   begin
    # Get replies
    replies_page = @agent.get(previous_replies)
    replies_page.xpath('//div[contains(@id, \'root\')]/div/div[last()-1]/div').each do |reply|
     if reply.at_css('span').text.to_s =~ /previous/
      previous_comments = reply.at_css('a')['href']
      next
     end
     entries.unshift(Comment.new(:agent => @agent, :comment => reply))
    end
    link = replies_page.xpath("//div[contains(text(),'previous')]/a")[0]
    unless link.nil?
     if link['href'] == previous_replies
      # Facebook BUG
      previous_replies = nil
     else
      previous_replies = link['href']
     end
    else
     previous_replies = nil
    end
   end while previous_replies
   return entries
  end

  private :initialize_body

 end
end
