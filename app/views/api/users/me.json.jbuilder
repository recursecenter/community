json.partial! 'user', user: current_user

notifications = current_user.notifications.unread.map do |n|
  n.to_builder.attributes!
end

json.notifications notifications
