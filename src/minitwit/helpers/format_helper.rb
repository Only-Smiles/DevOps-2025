module FormatHelper
  # Format datetime
  def format_datetime(timestamp)
    Time.at(timestamp).utc.strftime('%Y-%m-%d @ %H:%M')
  end

  # Gravatar URL
  def gravatar_url(email, size = 80)
    hash = Digest::MD5.hexdigest(email.strip.downcase)
    "http://www.gravatar.com/avatar/#{hash}?d=identicon&s=#{size}"
  end
  
  # Format messages for API response
  def format_messages_for_api(messages)
    messages.map do |msg|
      {
        "content" => msg["text"],
        "pub_date" => msg["pub_date"],
        "user" => msg["username"]
      }
    end
  end
end