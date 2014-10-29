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
    "v2--#{data}--#{generate_digest(data)}"
  end

  def verify(signed_info)
    raise InvalidSignature if signed_info.blank?
    signed_info = signed_info.downcase

    v2 = signed_info.slice!("v2--")

    data, digest = signed_info.split("--")
    if data.present? && digest.present? && SecureEquals.secure_equals(digest, generate_digest(data))
      user_id, resource_id = data.split("-")

      if v2
        [User.find(user_id), Post.find(resource_id)]
      else
        [User.find(user_id), DiscussionThread.find(resource_id).posts.by_number.last]
      end
    else
      raise InvalidSignature
    end
  end

private
  def generate_digest(data)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, @secret, data)
  end
end
