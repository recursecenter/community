require 'openssl'

class ReplyInfoVerifier
  class InvalidSignature < StandardError; end

  def self.generate(user, post)
    new.generate(user, post)
  end

  def self.verify(info)
    new.verify(info)
  end

  def initialize
    @secret = Rails.application.secrets[:email_secret_key]
  end

  def generate(user, post)
    data = "#{user.id}-#{post.id}"
    "#{data}--#{generate_digest(data)}"
  end

  def verify(signed_info)
    raise InvalidSignature if signed_info.blank?
    signed_info = signed_info.downcase

    data, digest = signed_info.split("--")
    if data.present? && digest.present? && SecureEquals.secure_equals(digest, generate_digest(data))
      user_id, post_id = data.split("-")
      [User.find(user_id), Post.find(post_id)]
    else
      raise InvalidSignature
    end
  end

private
  def generate_digest(data)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, @secret, data)
  end
end
