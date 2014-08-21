json.extract! subforum_group, :name, :id
json.subforums do
  json.array! subforum_group.subforums do |subforum|
    json.extract! subforum, :id, :name, :slug, :ui_color
    json.recent_threads do
      json.array! subforum.threads_for_user(current_user).order(updated_at: :desc) do |thread|
        json.extract! thread, :id, :title, :slug
        json.updated_at thread.updated_at.to_i
        json.last_posted_to_by thread.posts.last.author.name
        json.unread thread.unread?
        if thread.next_unread_post_number
          json.post_number thread.next_unread_post_number
        end
      end
    end
  end
end
