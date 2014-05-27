json.extract! post, :id, :body, :thread_id
json.editable can?(:edit, post)

json.author post.author, :id, :name, :avatar_url
