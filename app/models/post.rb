class Post < ActiveRecord::Base
  include Searchable

  belongs_to :thread, class_name: "DiscussionThread"
  belongs_to :author, class_name: "User"
  has_and_belongs_to_many :broadcast_groups, class_name: "Group"
  has_many :mentions, class_name: "Notifications::Mention", dependent: :destroy

  validates :body, :author, :thread, presence: {allow_blank: false}

  before_create :update_thread_data

  scope :by_number, -> { order(post_number: :asc) }

  def update_thread_data
    DistributedLock.new("thread_#{thread.id}").synchronize do
      next_post_number = thread.highest_post_number + 1
      self.post_number = next_post_number
      thread.update(highest_post_number: next_post_number,
                    last_post_created_at: created_at,
                    last_post_created_by: author)
    end
  end

  def required_roles
    thread.subforum.required_roles
  end

  def mark_as_visited(user)
    thread.mark_post_as_visited(user, self)
  end

  def message_id
    format_message_id(thread_id, post_number)
  end

  def previous_message_id
    if post_number > 1
      format_message_id(thread_id, post_number-1)
    end
  end

  concerning :Searchable do
    included do
      # Additional indexer settings for posts to serve filtered queries.
      # We don't want them analyzed because we want them to be exact matches.
      settings index: {number_of_shards: 1} do
        mappings dynamic: 'true' do
          indexes :author, type: :string, index: "not_analyzed"
          indexes :author_email, type: :string, index: "not_analyzed"
          indexes :thread, type: :string, index: "not_analyzed"
          indexes :subforum, type: :string, index: "not_analyzed"
        end
      end

      # TODO: once Module::Concerning supports `class_methods { ... }`, get these out of `included`.
      # See:
      # - https://github.com/basecamp/concerning/pull/2
      # - https://github.com/rails/rails/issues/13942
      def self.generate_query(user, search_string, filters)
        # match query for exact matches, terms
        exact_match_query = {
          multi_match: {
            query: search_string,
            boost: 100,
            fields: [:thread_title, :body]
          }
        }

        # match query for phrase prefixes
        phrase_match_query = {
          multi_match: {
            query: search_string,
            boost: 10,
            fields: [:thread_title, :body],
            type: :phrase_prefix
          }
        }

        # Combine exact match and prefix queries and match all if query was empty
        if search_string.blank?
          subquery = {match_all: {}}
        else
          subquery = {bool: {should: [exact_match_query, phrase_match_query]}}
        end

        filters_with_permissions = filters.try(:dup) || {}

        # filter only subforums limited to the user
        filters_with_permissions['subforum_id'] = Subforum.for_user(user).pluck(:id)

        # create filtered query for available filter
        clauses = filters_with_permissions.map do |k, v|
          if v.kind_of?(Array)
            {terms: {k => v}}
          else
            {term: {k => v}}
          end
        end

        {filtered: {query: subquery, filter: {bool: {must: clauses}}}}
      end
    end

    # Search document format for posts
    def to_search_mapping
      {
        index: {
          _id: id,
          data: {
            body: body,
            created_at: created_at,
            author: author.name,
            author_email: author.email,
            thread: thread.title,
            subforum: thread.subforum.name,
            subforum_id: thread.subforum.id
          }
        }
      }
    end
  end

private
  def format_message_id(thread_id, post_number)
    "<thread-#{thread_id}/post-#{post_number}@community.hackerschool.com>"
  end
end
