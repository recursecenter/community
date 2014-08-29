json.extract! thread, :id, :title, :slug
json.ui_color thread.subforum.ui_color
json.posts do
  json.array! thread.posts.order(:post_number).includes(:author) do |post|
    json.partial! 'api/posts/post', post: post
  end
end
json.subforum do
  json.extract! thread.subforum, :id, :name, :slug
end
json.autocomplete_users @autocomplete_users, :id, :first_name, :last_name
json.broadcast_groups @valid_broadcast_groups, :id, :name
json.subscription do
  json.partial! 'api/subscriptions/subscription', subscription: thread.subscription_for(current_user)
end
