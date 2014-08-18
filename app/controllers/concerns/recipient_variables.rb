module RecipientVariables
  extend ActiveSupport::Concern

  def recipient_variables(recipients, post)
    recipients.map do |recipient|
      [recipient.email, {"reply_info" => ReplyInfoVerifier.generate(recipient, post)}]
    end.to_h
  end
end
