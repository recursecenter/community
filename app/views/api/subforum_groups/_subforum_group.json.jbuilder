json.extract! subforum_group, :name, :id
json.subforums do
  json.array! subforum_group.subforums do |subforum|
    json.extract! subforum, :id, :name, :slug, :ui_color
    json.recent_threads do
      json.array! subforum.threads_for_user(current_user).order(marked_unread_at: :desc).limit(3) do |thread|
        json.extract! thread, :id, :title, :slug
        json.marked_unread_at thread.marked_unread_at.to_i
        json.last_posted_to_by thread.posts.last.author.name
        json.unread thread.unread?
      end
    end
  end
end
