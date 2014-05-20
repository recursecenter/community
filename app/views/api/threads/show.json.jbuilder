json.extract! @thread, :id, :title
json.posts do
  json.array! @thread.posts do |post|
    json.extract! post, :id, :body
    json.author post.author, :id, :name
  end
end
