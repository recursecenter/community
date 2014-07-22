json.extract! thread, :id, :title, :slug
json.posts do
  json.array! thread.posts.order(:created_at).includes(:author) do |post|
    json.partial! 'api/posts/post', post: post
  end
end
json.subforum do
  json.extract! thread.subforum, :id, :name, :slug
end
json.autocomplete_users @autocomplete_users, :id, :first_name, :last_name
json.broadcast_groups Group.all, :id, :name
json.subscription do
  json.partial! 'api/subscriptions/subscription', subscription: thread.subscription_for(current_user)
end
