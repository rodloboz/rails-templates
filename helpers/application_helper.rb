require 'net/http'

module ApplicationHelper
  def avatar_url(user)
    if user.avatar.present?
      url = user.avatar
    elsif gravatar?(user)
      gravatar = Digest::MD5::hexdigest(user.email).downcase
      url = "http://gravatar.com/avatar/#{gravatar}.png"
    else
      url = "default-avatar.png"
    end
  end

  def gravatar?(user)
    gravatar_check = "http://gravatar.com/avatar/#{Digest::MD5.hexdigest(user.email.downcase)}.png?d=404"
    uri = URI.parse(gravatar_check)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    response.code.to_i != 404 # from d=404 parameter
  end
end
