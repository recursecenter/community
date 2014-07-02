json.extract! thread, :id, :title, :slug
json.posts do
  json.array! thread.posts.order(:created_at).includes(:author) do |post|
    json.partial! 'api/posts/post', post: post
  end
end
json.autocomplete_users @autocomplete_users, :id, :first_name, :last_name
