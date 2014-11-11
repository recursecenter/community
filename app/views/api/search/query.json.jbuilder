json.results @posts do |post|
  json.post do
    json.extract! post, :id, :body, :post_number
    json.created_at post.created_at.to_i
  end

  json.author do
    json.extract! post.author, :email, :hacker_school_id, :name
  end

  json.thread do
    json.extract! post.thread, :id, :slug, :title
  end

  json.subforum do
    json.extract! post.thread.subforum, :id, :slug, :ui_color, :name
    json.subforum_group_name post.thread.subforum.subforum_group.name
  end

  json.highlight @highlights[post.id.to_s].first
end

json.metadata do
  json.current_page @current_page
  json.total_pages @total_pages
  json.hits @hits
  json.query @query
  json.filters @filters
end
