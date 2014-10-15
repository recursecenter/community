json.extract! subforum_group, :name, :id
json.subforums do
  json.array! subforum_group.subforums do |subforum|
    json.extract! subforum, :id, :name, :slug, :ui_color, :description
    json.n_subscribers subforum.subscribers.count
    json.n_threads subforum.threads_for_user(current_user).count

    json.threads do
      json.array! NewThreadsQuery.new(subforum, current_user) do |thread|
        json.extract! thread, :id, :title, :slug, :highest_post_number, :last_post_number_read, :pinned
        json.last_post_created_at thread.last_post_created_at.to_i
        json.last_posted_to_by thread.last_author_name
        json.unread thread.unread?

        if thread.next_unread_post_number
          json.post_number thread.next_unread_post_number
        end

        json.created_by do
          json.extract! thread.created_by, :name
        end
      end
    end
  end
end
