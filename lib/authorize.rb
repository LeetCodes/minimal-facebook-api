module Facebook
 class Authorize
  RECOVER_REGEX = '/recover/initiate/'
  SECURITY_CHECKPOINT_REGEX = '/login/checkpoint/'
  CHANGE_LANGUAGE_ENGLISH_REGEX = 'en_US'

  attr_reader :interface, :login, :password

  def initialize()
  end
  def initialize(_parameters)
   login(_parameters)
  end
  def login(_parameters)
   raise ArgumentError.new('No login') unless _parameters.key?(:login) and _parameters[:login]
   raise ArgumentError.new('No password') unless _parameters.key?(:password) and _parameters[:password]

   @login, @password = _parameters[:login], _parameters[:password]
   # Initialize mechanize agent
   @agent = Mechanize.new
   # Generate random user_agent
   @agent.user_agent = (1...rand(50)).map { (' '..'~').to_a[rand(94)] }.join
   # Get mobile version of facebook site
   page = @agent.get('https://m.facebook.com/')
   # Fill login form
   login_form = page.forms.first
   login_form.email = @login
   login_form.pass = @password
   @main_site = login_form.submit()
   # Search for reocver account link
   @main_site.links.each do |link|
    raise RuntimeError.new("Invalid login or password") if link.href =~ /#{RECOVER_REGEX}/
   end
   # Search for security checkpoint
   raise RuntimeError.new("Security checkpoint") if @main_site.form_with(:action => /#{SECURITY_CHECKPOINT_REGEX}/)
   # Logged in
   # Change language to english
   @main_site.links.each do |link|
    link.click if link.href =~ /#{CHANGE_LANGUAGE_ENGLISH_REGEX}/
   end
   if @main_site.form_with(:action => /\/login\/device\-based\/update\-nonce\//)
    @main_site = @main_site.forms.last.submit
   end
   @composer = @main_site.form_with(:action => /\/composer\/mbasic\//)
   @composer = @agent.submit(@composer, @composer.button_with(:name => 'view_overview')).forms.first
   @interface = Interface.new(:main_site => @main_site, :composer => @composer, :agent => @agent)
  end #login
 end #Authorize
end #Facebook
