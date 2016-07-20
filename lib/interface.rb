module Facebook
 class Interface
  FRIEND_REGEX = '/friends/hovercard/mbasic/'
  MORE_FRIENDS_REGEX = '/friends/center/friends/'
  UNBLOCK_FRIEND_REGEX = '/privacy/touch/unblock/'
  def initialize(_parameters)
   raise ArgumentError.new('No site handle') unless _parameters.key?(:main_site) and _parameters[:main_site]
   raise ArgumentError.new('No composer') unless _parameters.key?(:composer) and _parameters[:composer]
   raise ArgumentError.new('No agent') unless _parameters.key?(:agent) and _parameters[:agent]

   @main_site = _parameters[:main_site]
   @composer = _parameters[:composer]
   @agent = _parameters[:agent].dup
  end #initialize
  def post_message(_parameters)
   post_composer = @composer.dup
   if _parameters.key?(:message) and _parameters[:message]
    post_composer.xc_message = _parameters[:message]
   end
   if _parameters.key?(:image)
    post_composer = @agent.submit(post_composer, post_composer.button_with(:name => 'view_photo')).forms.first
    post_composer.radiobuttons[3].check
    post_composer.file_uploads.first.file_name = _parameters[:image]
    post_composer.file_uploads.first.file_data = File.new(_parameters[:image]).read
    post_composer = @agent.submit(post_composer, post_composer.button_with(:name => 'add_photo_done')).forms.first
   end
   @agent.submit(post_composer, post_composer.button_with(:name => 'view_post'))
  end #post_message
  def friends()
   unless @friends
    page = @agent.get('https://m.facebook.com/friends/center/friends/')
    @friends = Hash.new
    more_friends = false
    begin
     more_friends = false
     page.links.each do |link|
      if link.href =~ /#{FRIEND_REGEX}/
       name = { :first_name => nil,
                :middle_name => nil,
                :last_name => nil }
       if link.to_s.scan(/ /).count == 2
        name[:first_name], name[:middle_name], name[:last_name] = link.to_s.split(' ')
       else
        name[:first_name], name[:last_name] = link.to_s.split(' ')
       end
       @friends[link.href[/uid=(\d{1,})/, 1]] = name
      elsif link.href =~ /#{MORE_FRIENDS_REGEX}/
       page = @agent.get("https://m.facebook.com/#{link.href}")
       more_friends = true
      end
     end
    end while more_friends
    @friends
   else
    @friends
   end
  end #friends
  def emails
   addresses = Array.new
   # Get page
   email_page = @agent.get('https://m.facebook.com/settings/email')
   # Get mails
   email_page.xpath('//div[contains(@id,\'root\')]/div/div[1]/div[1]/span/span').each do |span|
    addresses.push(span.text.to_s.split(' ')[0])
   end
   return addresses
  end
  def primary_email
   # Get page
   email_page = @agent.get('https://m.facebook.com/settings/email')
   # Get primary mail
   return email_page.xpath('//div[contains(@id,\'root\')]/div/div[1]/table//span').text.to_s
  end
  def change_password(_old_password, _new_password)
   # Get page
   email_page = @agent.get('https://m.facebook.com/settings/account/?password')
   # Find a form
   email_page.form_with(:action => /\/password\/change\//) do |f|
    # Fill it
    f.old_password = _old_password
    f.new_password = _new_password
    f.confirm_password = _new_password
    # Submit
   end.submit
  end
  def name
   # Get page
   general_page = @agent.get('https://m.facebook.com/settings/account')
   # Find name
   name = general_page.xpath('//div[contains(@id,\'root\')]/div/table[1]//td[1]//span').text().to_s
   # Divide name to hash
   full_name = Hash.new
   if name.count(' ') == 2
    full_name[:first_name], full_name[:middle_name], full_name[:last_name] = name.split(' ')
   elsif name.count(' ') == 1
    full_name[:first_name], full_name[:last_name] = name.split(' ')
   else
    full_name[:first_name] = name
   end
   return full_name
  end
  def add_email(_password, _email)
   # Get page
   mail_page = @agent.get('https://m.facebook.com/settings/email/add')
   # Check if feature is blocked
   if mail_page.body =~ /You're/
    raise RuntimeError.new("Feature is temporarily blocked")
   end
   # Fill form and add email address
   x = mail_page.form_with(:action => /email/) do |f|
    f.email = _email
    f.save_password = _password
   end.submit
  end
  def blacklist
   page = @agent.get('https://m.facebook.com/privacy/touch/block/')
   list = Array.new
   page.css('tr').each do |tr|
    tr = tr.to_s
    if tr =~ /#{UNBLOCK_FRIEND_REGEX}/
     name = tr[/<h3>([^<]+)<\/h3>/, 1]
     link = tr[/href="([^"]+)"/, 1]
     list.push(BlockedAccount.new(:agent => @agent, :link => link, :name => name))
    end
   end
   return list
  end
  def account(_parameters)
   Account.new(:uid => _parameters[:uid], :name => _parameters[:name], :link => _parameters[:link], :agent => @agent)
  end #account
 end #Interface
end #Facebook
