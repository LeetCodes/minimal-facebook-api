module Facebook
 class Story
  ADVANCED_COMMENT_REGEX = "/mbasic/comment/advanced/"

  attr_reader :text, :owner_name, :owner_link, :resources,
              :likes, :comments_count, :publish_date

  def initialize(_parameters)
   @post = _parameters[:post]
   raise ArgumentError.new("No body or metadata of story") if @post.nil?
   raise ArgumentError.new("No Mechanize agent") if _parameters[:agent].nil?
   @agent = _parameters[:agent].dup

   initialize_body
   initialize_interface
  end # initialize
  def initialize_body
   @resources = Array.new
   # Possibliy a tagged post
   if not @post.xpath('./div[1]/h3').empty?
    # Tagged?
    if @post.xpath('./div[1]').text =~ /was tagged/
     @tagged = true
     @resource_link = @post.xpath('./div[1]/h3/a')[0]['href']
     @resource_type = @post.xpath('./div[1]/h3/a').text
     tagged_post = @post.xpath('./div[2]')
     @owner_link = Facebook::strip_uri(tagged_post.xpath('./div[1]/h3//strong/a')[0]['href'])
     @owner_name = tagged_post.xpath('./div[1]/h3//strong/a').text
     @text = tagged_post.xpath('./div[1]/div[1]').text
    # Normal post
    else
     @tagged = false
     @owner_link = Facebook::strip_uri(@post.xpath('./div[1]/h3//strong/a')[0]['href'])
     @owner_name = @post.xpath('./div[1]/h3//strong/a').text
     @text = @post.xpath('./div[1]/div[1]').text
     @post.xpath('./div[1]/div[1]//a').each do |link|
      if link.text == "More"
       @expand_link = link['href']
       break
      end
     end
    end
   # Normal post
   elsif not @post.xpath('./div[1]/div[1]/h3').empty?
    @tagged = false
    @owner_link = Facebook::strip_uri(@post.xpath('./div[1]/div[1]/h3//strong/a')[0]['href'])
    @owner_name = @post.xpath('./div[1]/div[1]/h3//strong/a').text
    @text = @post.xpath('./div[1]/div[2]').text
    @post.xpath('./div[1]/div[2]//a').each do |link|
     if link.text == "More"
      @expand_link = link['href']
      break
     end
    end
    # Gather all links
    if @post.xpath('./div[1]/div[3]')
     @post.xpath('./div[1]/div[3]//a').each do |resource|
      @resources.push(resource['href'])
     end
    end
    # PARSE 'WITH'
   end
  end # initialize_body
  def initialize_interface
   @comments_count, @likes = 0, 0
   @publish_date = @post.xpath('./div[2]/div[1]/abbr').text
   @post.xpath('./div[last()]//a').each do |interface|
    case interface.text.to_s
    when /^\d+$/
     @likes = interface.text.to_s
    when /^\d+ Comments?$/
     @comments_count = interface.text.to_s[/^(\d+) Comments?$/,1]
    when "Like"
     @liked = false
     @like_link = interface['href']
    when "Unlike"
     @liked = true
     @like_link = interface['href']
    when "Full Story"
     @full_story_link = interface['href']
    when "Report"
     @report_link = interface['href']
    when "Tag Photo"
     @tag_photo_link = interface['href']
    when "Share"
     @share_link = interface['href']
    end
   end
  end # initialize_interface
  def like
   return false if @like_link.nil?
   @agent.get(@like_link)
   return true
  end
  def resources?
   return (@resources.nil? ? false : true)
  end
  def liked?
   return @liked
  end
  def expandable?
   return (@expand_link.nil? ? false : true)
  end
  def expand
   return false unless expandable?
   expanded_story = @agent.get(@expand_link)
   @text = expanded_story.xpath('//div[@id="root"]/div/div/div[last()]/div[1]/div[1]/div[last()]').text
   return true
  end
  def reply(_parameters)
   return false if @full_story_link.nil?
   raise ArgumentError.new("No data to send") unless _parameters.key?(:text) or
                                                     _parameters.key?(:image)
   text, image = _parameters.values_at(:text, :image)
   unless @comment_section
    # Get advanced comment form
    @comment_section = @agent.get(@full_story_link)
    @comment_section = @agent.get("https://m.facebook.com#{@comment_section.xpath('//a[contains(text(),"Attach a Photo")]')[0]['href']}")
   end
   # Fill form
   form = @comment_section.forms.last
   form.comment_text = text unless text.nil?
   unless image.nil?
    form.file_uploads[0].file_name = image
    form.file_uploads[0].file_data = File.new(image).read
   end
   @agent.submit(form, form.button_with(:value => 'Comment'))
   return true
  end
  def comments
   return Array.new if @full_story_link.nil? or @comments_count == 0
   previous_comments = @full_story_link
   entries = Array.new
   begin
    # Get comments
    comment_page = @agent.get(previous_comments)
    comment_section = comment_page.xpath("//div[contains(@id,'root')]//div[@class]/div[(@id and @class)]/h3/..")
    comment_section.reverse.each do |comment|
     if comment['id'] =~ /prev/
      previous_comments = comment.at_css('a')['href']
      next
     elsif comment['id'] =~ /next/
      next
     elsif comment['id'] =~ /^u_/
     # Garbage
     elsif comment['id'] =~ /^[^\du]+/
      next
     end
     entries.unshift(Comment.new(:agent => @agent, :comment => comment))
    end
    link = comment_page.xpath("//div[contains(@id,'prev')]/a")[0]
    unless link.nil?
     if link['href'] == previous_comments
      # Facebook BUG
      previous_comments = nil
     else
      previous_comments = link['href']
     end
    else
     previous_comments = nil
    end
   end while previous_comments
   return entries
  end

  private :initialize_body, :initialize_interface

 end
end
