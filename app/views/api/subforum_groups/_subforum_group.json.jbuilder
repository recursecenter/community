json.extract! subforum_group, :name, :id
json.subforums SubforumsWithCountsQuery.new(subforum_group.subforums, current_user) do |subforum|
  json.extract! subforum, :id, :name, :slug, :ui_color, :description
  json.n_subscribers subforum.subscriber_count
  json.n_threads subforum.thread_count

  json.threads NewThreadsQuery.new(subforum, current_user) do |thread|
    json.extract! thread, :id, :title, :slug, :highest_post_number, :last_post_number_read, :pinned
    json.last_post_created_at thread.last_post_created_at.to_i
    json.last_posted_to_by thread.last_author_name
    json.unread thread.unread?

    if thread.next_unread_post_number
      json.post_number thread.next_unread_post_number
    end

    json.created_by do
      json.name thread.creator_name
    end
  end
end
