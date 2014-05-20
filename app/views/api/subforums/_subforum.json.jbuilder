json.extract! subforum, :name
json.threads do
  json.array! subforum.threads do |thread|
    json.extract! thread, :title
    json.created_by thread.created_by.name
  end
end
