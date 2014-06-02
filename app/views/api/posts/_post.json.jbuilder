json.extract! post, :id, :body, :thread_id, :created_at
json.editable can?(:edit, post)

json.author post.author, :id, :hacker_school_id, :name, :avatar_url
