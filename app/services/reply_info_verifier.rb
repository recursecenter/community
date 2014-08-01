class ReplyInfoVerifier
  def self.generate(user, thread)
    new.generate(user, thread)
  end

  def self.verify(info)
    new.verify(info)
  end

  def initialize
    secret = Rails.application.secrets[:email_secret_key]
    @verifier = ActiveSupport::MessageVerifier.new(secret, serializer: YAML)
  end

  def generate(user, thread)
    @verifier.generate([user.id, thread.id])
  end

  def verify(info)
    user_id, thread_id = @verifier.verify(info)

    [User.find(user_id), DiscussionThread.find(thread_id)]
  end
end
