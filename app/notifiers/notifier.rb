class Notifier
  def should_email?(u)
    true
  end

  def possible_recipient?(u)
    possible_recipients.include?(u)
  end
end
