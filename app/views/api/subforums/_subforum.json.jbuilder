json.extract! subforum, :name, :id
json.threads do
  json.array! subforum.threads do |thread|
    json.extract! thread, :title, :id
    json.created_by thread.created_by.name
  end
end
