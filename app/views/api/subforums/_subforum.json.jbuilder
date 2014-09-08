json.extract! subforum, :name, :id, :slug, :ui_color, :description
json.subforum_group_name subforum.subforum_group.name
json.n_subscribers subforum.subscribers.count
json.threads do
  json.array! threads do |thread|
    json.extract! thread, :id, :title, :slug, :highest_post_number, :last_post_number_read
    json.n_subscribers thread.subscribers.count
    json.updated_at thread.updated_at.to_i
    json.last_posted_to_by thread.posts.last.author.name
    json.unread thread.unread?
    if thread.next_unread_post_number
      json.post_number thread.next_unread_post_number
    end
  end
end
json.autocomplete_users @autocomplete_users, :id, :first_name, :last_name
json.broadcast_groups @valid_broadcast_groups, :id, :name
json.subscription do
  json.partial! 'api/subscriptions/subscription', subscription: subforum.subscription_for(current_user)
end
