module Facebook
 def self.strip_uri(link)
  if link =~ /profile\.php/
   link = "/#{link[/\/([^&]+)/, 1]}"
  else
   link = "/#{link[/\/([A-Za-z0-9\.]+)(\?.*)?/, 1]}"
  end
  return link
 end
end
