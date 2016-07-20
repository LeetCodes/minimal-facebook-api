# `minimal-facebook-api`
This is a minimal facebook HTTP-based API created in ruby for educational purposes.
* Enumerate facebook friends and fetch their info
* Enumerate their timelines and analyze, comment, un/like their content
* Un/block friends, add friends, search accounts by uid
* Send messages and images to anybody
* Post on your timeline

`minimal-facebook-api` gem contains several classes `Authorize, Interface, Account, BlockedAccount, Story, Comment` Most of them are self explanatory. `Interface` represents account you're currently logged on and `Account` represents account of your friend or total stranger. Examples are inside `examples/` directory.

```ruby
#!/usr/bin/env ruby

require 'minimal-facebook-api'

def display_info
 puts "[*] #{__FILE__} <login> <password> <uid | link>"
 puts "[*] This script displays info about certain facebook profile"
 exit
end

def main
 display_info if ARGV.size != 3
 puts "[*] Attempting to login"
 begin
  interface = Facebook::Authorize.new(:login => ARGV[0], :password => ARGV[1]).interface
  puts "[*] Searching for #{ARGV[2]}"
  if ARGV[2] =~ /^\d+$/
   account = interface.account(:uid => ARGV[2])
  else
   account = interface.account(:link => ARGV[2])
  end
  account.info.each_pair do |key, value|
   puts "[+] #{key.to_s} => #{value}"
  end
 rescue RuntimeError, ArgumentError => error
  puts "[!] #{error.to_s}"
 end
end

main
```

This tiny scripts enumerates info from user identified by certain `UID` or link. `Facebook::Authorize` has only 2 usable methods `login` which serves identical purpose as `initialize` and `interface` which returns control panel.

#### `Interface`
>`:post_message({:message => String, :images => []}) => nil` - Posts on your timeline the `:message` and `:images` up to 3, with default privacy settings.

>`:friends => Hash` - Returns a `Hash` of your friends. The key is `UID` of your friend's profile and value contains yet another `Hash` with keys: `{:first_name, :middle_name, :last_name}`.

>`:emails => Array` - Returns a `Array` of email addresses bound to your account.

>`:primary_email => String` - Returns a primary email address bound to your account.

>`:change_password(_old_password => String, _new_password => String) => nil` - Changes account password.

>`:name => Hash.new` - Returns a `Hash` with keys: `{:first_name, :middle_name, :last_name}`.

>`:add_email(_email => String) => nil` - Adds email address to your account. It will need to be confirmed.

>`:blacklist => Array` - Returns `Array` of `BlockedAccount`.

>`:account({:uid => String, :link => String}) => Account` - Creates new `Account` object of facebook account that can be found using `UID`, direct `link` or `uri` (Link and uri is treated as one thing)
