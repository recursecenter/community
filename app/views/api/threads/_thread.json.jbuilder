json.extract! thread, :id, :title
json.posts do
  json.array! thread.posts do |post|
    json.partial! 'api/posts/post', post: post
  end
end
