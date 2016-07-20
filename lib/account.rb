module Facebook
 class Account
  ADD_FRIEND_REGEX = "profile_add_friend.php"
  PENDING_FRIEND_REGEX = "friendrequest/cancel/"
  REMOVE_FRIEND_REGEX = "removefriend.php"
  BLOCK_FRIEND_REGEX = "privacy/touch/block"
  FRIEND_REGEX = "fref=fr_tab"
  MORE_FRIENDS_REGEX = "startindex="
  PROFILE_PHOTO_REGEX_1 = "/profile/picture/view/"
  PROFILE_PHOTO_REGEX_2 = "/photo.php"
  POKE_REGEX = "/pokes/inline"

  attr_reader :link, :uri, :uid

  def initialize(_parameters)
   raise ArgumentError.new('No agent') unless _parameters.key?(:agent) and _parameters[:agent]
   # Copy mechanize agent
   @agent = _parameters[:agent].dup
   if _parameters[:uid]
    # Fetch profile
    @uid = _parameters[:uid]
    @main_site = @agent.get("https://m.facebook.com/#{@uid}")
    # Build links
    link = @main_site.uri.to_s
    if link =~ /profile\.php\?/
     @uri = "/#{link[/facebook\.com\/([^&]+)/, 1]}"
    else
     @uri = "/#{link[/facebook\.com\/([A-Za-z0-9\.]+)(\?.*):?/, 1]}"
    end
    @link = "https://facebook.com#{uri}"
   elsif _parameters[:link]
    link = _parameters[:link]
    if link =~ /facebook\.com/
     # Change link to mobile
     link.sub('wwww.', 'm.')
     # Check if link is profile-style link
     if link =~ /profile\.php/
      # Extract UID and craft @uri
      @uid = link[/profile\.php\?id=(\d+)[^\d]*/, 1]
      @uri = "/#{link[/facebook\.com\/([^&]+)/, 1]}"
     else
      @uri = "/#{link[/facebook\.com\/([A-Za-z0-9\.]+)(\?.*)?/, 1]}"
     end
     @link = "https://m.facebook.com#{@uri}"
     @main_site = @agent.get(@link)
     unless @uid
      # Extract UID
      @main_site.links.each do |link|
       href = link.href.to_s
       if href =~ /#{PROFILE_PHOTO_REGEX_1}/
        @uid = href[/profile_id=(\d+)/, 1]
        break
       elsif href =~ /#{PROFILE_PHOTO_REGEX_2}/
        @uid = href[/&id=(\d+)/, 1]
        break
       end
      end
      # Raise exception if no UID
      raise RuntimeError.new("Unable to extract UID") unless @uid
     end
    # Check if URI
    elsif link =~ /^\/[^\/]+$/
     # Check if this is profile.php-style URI
     if link =~ /profile\.php/
      # Extract UID and craft @uri
      @uid = link[/profile\.php\?id=(\d+)[^\d]*/, 1]
      @uri = "/#{link[/\/([^&]+)/, 1]}"
     else
      @uri = "/#{link[/\/([A-Za-z0-9\.]+)(\?.*)?/, 1]}"
     end
     @link = "https://m.facebook.com#{@uri}"
     @main_site = @agent.get(@link)
     unless @uid
      # Extract UID
      @main_site.links.each do |link|
       href = link.href.to_s
       if href =~ /#{PROFILE_PHOTO_REGEX_1}/
        @uid = href[/profile_id=(\d+)/, 1]
        break
       elsif href =~ /#{PROFILE_PHOTO_REGEX_2}/
        @uid = href[/&id=(\d+)/, 1]
        break
       end
      end
     end
     raise RuntimeError.new("Unable to extract UID") unless @uid
    end
   else
    raise ArgumentError.new("No account info specified")
   end
  end #initialize
  def add()
   # Send friend request to this account
   @main_site.link_with(:href => /#{ADD_FRIEND_REGEX}/).click
  end
  def friend_request?()
   # If link exists then cancel option is available
   return false unless @main_site.link_with(:href => /#{PENDING_FRIEND_REGEX}/)
   return true
  end
  def cancel_friend_request()
   # Cancel pending friend request
   link = @main_site.link_with(:href => /#{PENDING_FRIEND_REGEX}/).click
  end
  def remove()
   # Remove friend from friend list
   link = @main_site.link_with(:href => /#{REMOVE_FRIEND_REGEX}/)
   if link
    link.click
    return true
   end
   return false
  end
  def friend?()
   # If You can remove friend from friend list, then it's your friend
   return false unless @main_site.link_with(:href => /#{REMOVE_FRIEND_REGEX}/)
   return true
  end
  def block()
   confirmation = @main_site.link_with(:href => /#{BLOCK_FRIEND_REGEX}/).click
   confirmation_dialog = confirmation.form_with(:action => /#{BLOCK_FRIEND_REGEX}/)
   @agent.submit(confirmation_dialog, confirmation_dialog.button_with(:name => 'confirmed'))
  end
  def friends(_parameters = {})
   friend_list_site = @agent.get("#{@uri}/friends")
   friend_list = Hash.new()
   count = 0
   more_friends = false
   begin
    more_friends = false
    friend_list_site.links.each do |link|
     if link.href.to_s =~ /#{FRIEND_REGEX}/
      name = { :first_name => nil,
               :nick  => nil,
               :last_name => nil }
      if link.to_s.scan(/ /).count == 2
       name[:first_name], name[:nick], name[:last_name] = link.to_s.split(' ')
      elsif link.to_s.scan(/ /).count == 1
       name[:first_name], name[:last_name] = link.to_s.split(' ')
      else
       name[:first_name] = link.to_s
      end
      friend_list[Facebook::strip_uri(link.href)] = name
      count += 1
      break if _parameters.key?(:limit) and _parameters[:limit] == count
     elsif link.href.to_s =~ /#{MORE_FRIENDS_REGEX}/
      friend_list_site = @agent.get(link.href.to_s)
      more_friends = true
     end
    end
   end while more_friends
   friend_list
  end #friends
  def refresh()
   @main_site = @agent.get(@link)
  end
  def stories(_parameters = {})
   stories = Array.new
   next_stories = "https://m.facebook.com#{uri}"
   timeline = @agent.get(next_stories)
   timeline.xpath('//div[@id="structured_composer_async_container"]/div[last()]//a/@href').each do |year|
    begin
     container = timeline.xpath('//div[@id="structured_composer_async_container"]/div[1]/div[last()]')
     next unless container.xpath('./div/h3').empty?
     container.xpath('./div/*').each do |post|
      # Long post?
      if post.xpath('string-length(./@class)') == 11
       post.xpath('./div[last()]/div/div').each do |sub_post|
        stories.push(Story.new(:post => sub_post, :agent => @agent))
       end
      else
       stories.push(Story.new(:post => post, :agent => @agent))
      end
     end
     next_stories = timeline.xpath("//a[contains(text(),'Show more')]/@href")
     break if next_stories.empty?
     timeline = @agent.get(next_stories)
    end while not next_stories.empty?
    timeline = @agent.get(year)
   end
   return stories
  end
  def send(_parameters)
   raise ArgumentError.new("No data to send") unless _parameters.key?(:text) or
                                                     _parameters.key?(:images)
   unless @send_site
    form = @agent.get("https://m.facebook.com/messages/thread/#{@uid}").form_with(:action => /\/messages\/send/)
    @send_site = @agent.submit(form, form.button_with(:name => 'send_photo'))
   end
   text, images = _parameters.values_at(:text, :images)
   send_form = @send_site.form
   send_form.body = text unless text.nil?
   if images
    images.each_with_index do |path, index|
     break if index == 3
     send_form.file_uploads[index].file_name = path
     send_form.file_uploads[index].file_data = File.new(path).read
    end
   end
   send_form.submit()
  end
  def poke()
   @main_site.link_with(:href => /#{POKE_REGEX}/).click
  end
  def info()
   if @uri =~ /profile/
    info_page = @agent.get("https://m.facebook.com/#{@uri}&v=info")
   else
    info_page = @agent.get("https://m.facebook.com/#{@uri}/about")
   end
   data_entries = Hash.new
   %w(living basic-info contact-info nicknames).each do |category|
    section = info_page.xpath("//div[@id=\"#{category}\"]/div/div[last()]")
    section.xpath("./div/*").each do |div|
     entry = div.at_css('span').text.downcase.gsub(' ', '_')
     next if entry =~ /ask_for/ or entry =~ /you_requested/
     td = div.xpath('.//td[last()]')
     data_entries[entry.to_sym] = (td ? td.text.strip : "")
    end
   end
   return data_entries
  end
 end #Account
end #Facebook
