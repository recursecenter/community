require 'set'

# each notifier's initializer needs to take the subject
#   remove Ability.new from the coordinator and add it to the notifiers (possibly in the superclass)
# implement the missing mailer methods
# use

class NotificationCoordinator
  attr_reader :notifiers, :email_recipients

  def initialize(*notifiers)
    @notifiers = notifiers
    @email_recipients = Hash.new { |h, k| h[k] = [] }
  end

  def notify(subject)
    users.each do |u|
      next if Ability.new(u).cannot? :read, subject

      notifiers.each do |n|
        if n.possible_recipient?(u) && n.should_email?(u)
          email_recipients[n] << u
          next
        end
      end
    end

    notifiers.each do |n|
      n.notify(subject, email_recipients[n])
    end
  end

private
  def users
    @users ||= notifiers.map do |n|
      n.possible_recipients
    end.flatten.to_set
  end
end
