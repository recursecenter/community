require 'delegate'

class ThreadWithLastAuthor < DelegateClass(ThreadWithVisitedStatus)
  attr_reader :creator_name, :last_author_name

  def initialize(thread, creator_name, last_author_name)
    super(thread)
    @creator_name = creator_name
    @last_author_name = last_author_name
  end
end
