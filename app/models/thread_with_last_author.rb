require 'delegate'

class ThreadWithLastAuthor < DelegateClass(ThreadWithVisitedStatus)
  attr_reader :last_author_name

  def initialize(thread, last_author_name)
    super(thread)
    @last_author_name = last_author_name
  end
end
