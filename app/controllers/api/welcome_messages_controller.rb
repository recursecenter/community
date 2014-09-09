class Api::WelcomeMessagesController < Api::ApiController
  skip_authorization_check only: :read

  def read
    current_user.update(last_read_welcome_message_at: Time.zone.now)
    head 200
  end
end
