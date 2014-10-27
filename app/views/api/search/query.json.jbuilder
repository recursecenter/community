json.results @records do |record|
  json.post do
    json.extract! record, :id, :body, :post_number
  end
  json.author do
    json.extract! record.author, :email, :hacker_school_id, :name
  end
  json.thread do
    json.extract! record.thread, :id, :slug
  end

  json.subforum do
    json.extract! record.thread.subforum, :id, :slug, :ui_color, :name
    json.subforum_group_name record.thread.subforum.subforum_group.name
  end

  json.highlight @highlights.fetch(record.id.to_s).first
end

json.metadata do
  json.current_page @current_page
  json.total_pages @total_pages
  json.took @took
  json.query @query
  json.filters @filters
end