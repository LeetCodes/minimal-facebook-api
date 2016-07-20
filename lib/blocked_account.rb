module Facebook
 class BlockedAccount
  UNBLOCK_ACTION_REGEX = "/privacy/touch/unblock/"

  attr_reader :name, :uid

  def initialize(_parameters)
   raise ArgumentError.new("No agent") unless _parameters.key?(:agent) and _parameters[:agent]
   raise ArgumentError.new("No link") unless _parameters.key?(:link) and _parameters[:link]
   raise ArgumentError.new("No name") unless _parameters.key?(:name) and _parameters[:name]

   @agent = _parameters[:agent].dup
   @link = _parameters[:link]
   @name = _parameters[:name]
   @uid = @link[/unblock_id=(\d{1,})/, 1]
  end #initialize
  def unblock()
   confirmation = @agent.get("https://m.facebook.com/#{@link}")
   confirmation_dialog = confirmation.form_with(:action => /#{UNBLOCK_ACTION_REGEX}/)
   @agent.submit(confirmation_dialog, confirmation_dialog.button_with(:name => 'confirmed'))
   def unblock()
   end
  end #unblock
 end #BlockedAccount
end #Facebook
