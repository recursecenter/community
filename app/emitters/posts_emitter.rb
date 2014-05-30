class PostsEmitter < PubSub::Emitter
  def created
    @post = Post.find(params[:id])
  end
end
