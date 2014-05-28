json.extract! thread, :id, :title
json.posts do
  json.array! thread.posts.order(:created_at).includes(:author) do |post|
    json.partial! 'api/posts/post', post: post
  end
end
