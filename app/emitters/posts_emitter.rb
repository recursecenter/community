class PostsEmitter < PubSub::Emitter
  def created
    @post = Post.find(params[:id])
    @post.mark_as_visited(@session.current_user)
  end

  def updated
    @post = Post.find(params[:id])
  end
end
