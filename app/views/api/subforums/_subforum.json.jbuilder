json.extract! subforum, :name, :id
json.threads do
  json.array! subforum.threads.order(updated_at: :desc) do |thread|
    json.extract! thread, :title, :id
    json.updated_at thread.updated_at.to_i
    json.created_by thread.created_by.name
  end
end
