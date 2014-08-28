json.extract! subforum, :name, :id, :slug, :ui_color
json.subforum_group_name subforum.subforum_group.name
json.threads do
  json.array! threads do |thread|
    json.extract! thread, :title, :id, :slug
    json.updated_at thread.updated_at.to_i
    json.created_by thread.created_by.name
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
