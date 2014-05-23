json.extract! thread, :id, :title
json.posts do
  json.array! thread.posts.includes(:author) do |post|
    json.partial! 'api/posts/post', post: post
  end
end
