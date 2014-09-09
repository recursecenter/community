json.partial! 'user', user: current_user

json.extract! current_user, :welcome_message

notifications = current_user.notifications.unread.map do |n|
  n.to_builder.attributes!
end

json.notifications notifications

json.subscription_info do
    json.subforum_groups SubforumGroup.includes_subforums_for_user(current_user) do |group|
      json.extract! group, :name
        json.subforum_subscriptions group.subforums do |subforum|
          json.extract! subforum, :name
          json.subforum_id subforum.id
          subscription = subforum.subscription_for(current_user)
          json.extract! subscription, :subscribed, :reason
        end
    end
end
