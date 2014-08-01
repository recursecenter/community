module RecipientVariables
  extend ActiveSupport::Concern

  def recipient_variables(recipients, thread)
    recipients.map do |recipient|
      [recipient.email, {"reply_info" => ReplyInfoVerifier.generate(recipient, thread)}]
    end.to_h
  end
end
