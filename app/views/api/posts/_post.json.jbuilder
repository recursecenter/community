json.extract! post, :id, :body, :thread_id
json.created_at post.created_at.to_i
json.editable can?(:edit, post)

json.author post.author, :id, :hacker_school_id, :name, :avatar_url, :batch_name
