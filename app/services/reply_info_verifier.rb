require 'openssl'

class ReplyInfoVerifier
  class InvalidSignature < StandardError; end

  def self.generate(user, thread)
    new.generate(user, thread)
  end

  def self.verify(info)
    new.verify(info)
  end

  def initialize
    @secret = Rails.application.secrets[:email_secret_key]
  end

  def generate(user, thread)
    data = "#{user.id}-#{thread.id}"
    "#{data}--#{generate_digest(data)}"
  end

  def verify(signed_info)
    raise InvalidSignature if signed_info.blank?
    signed_info = signed_info.downcase

    data, digest = signed_info.split("--")
    if data.present? && digest.present? && SecureEquals.secure_equals(digest, generate_digest(data))
      user_id, thread_id = data.split("-")
      [User.find(user_id), DiscussionThread.find(thread_id)]
    else
      raise InvalidSignature
    end
  end

private
  def generate_digest(data)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, @secret, data)
  end
end
