require 'delegate'

class SubforumWithRecentThreads < DelegateClass(Subforum)
  attr_reader :recent_threads

  def initialize(subforum, recent_threads)
    super(subforum)
    @recent_threads = recent_threads
  end
end
