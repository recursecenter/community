class NewThread
  attr_reader :thread

  def self.create!(params)
    t = new(params.symbolize_keys)
    t.save!

    t.thread
  end

  def initialize(subforum:, author:, title:, body:)
    @thread = subforum.threads.build(created_by: author, title: title)
    @post_params = {body: body, author: author}
  end

  def save!
    @thread.transaction do
      @thread.save!
      @thread.posts.create!(@post_params)
    end
  end
end
