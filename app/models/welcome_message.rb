class WelcomeMessage < ActiveRecord::Base
  def self.latest
    order(created_at: :desc).first
  end

  def self.for(user)
    welcome_message = latest
    if welcome_message && (user.last_read_welcome_message_at.nil? ||
                           welcome_message.created_at > user.last_read_welcome_message_at)
      welcome_message
    end
  end
end
