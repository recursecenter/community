class Post < ActiveRecord::Base
  belongs_to :thread, class_name: "DiscussionThread"
  belongs_to :author, class_name: "User"
  has_and_belongs_to_many :broadcast_groups, class_name: "Group"
  has_many :mentions, class_name: "Notifications::Mention", dependent: :destroy

  validates :body, :author, :thread, presence: {allow_blank: false}

  before_create :update_thread_data
  before_create :set_message_id

  scope :by_number, -> { order(post_number: :asc) }

  MAX_WORDS_IN_HIGHLIGHT = 35

  include PgSearch::Model
  pg_search_scope :search,
                  against: :body,
                  using: {
                    tsearch: {
                      dictionary: "english",
                      highlight: {
                        StartSel: "<span class='highlight'>",
                        StopSel: "</span>",
                        MaxWords: MAX_WORDS_IN_HIGHLIGHT,
                      }
                    }
                  }

  scope :with_null_pg_search_highlight, -> do
    select("posts.*", "ts_headline('english', posts.body, to_tsquery('english', ''), 'MaxWords=#{MAX_WORDS_IN_HIGHLIGHT}') AS pg_search_highlight")
  end

  scope :author_named, ->(author_name) do
    users = User.where("users.first_name || ' ' || users.last_name = ?", author_name)

    where(author_id: users)
  end

  scope :for_user, ->(user) do
    joins(:thread).where(discussion_threads: {subforum_id: Subforum.for_user(user)})
  end

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

  def previous_post
    thread.posts.where(post_number: post_number - 1).first
  end

  def previous_message_id
    if post_number > 1
      previous_post.message_id
    end
  end

  def created_via_email?
    unless message_id
      raise "Post#created_via_email? only works on persisted posts"
    end

    message_id != generate_message_id
  end

  concerning :Searchable do
    included do
      # Additional indexer settings for posts to serve filtered queries.
      # We don't want them analyzed because we want them to be exact matches.
      # settings index: {number_of_shards: 1} do
      #   mappings dynamic: 'true' do
      #     indexes :author, type: :string, index: "not_analyzed"
      #     indexes :author_email, type: :string, index: "not_analyzed"
      #     indexes :thread, type: :string, index: "not_analyzed"
      #     indexes :subforum, type: :string, index: "not_analyzed"
      #   end
      # end

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

      def self.highlight_fields
        highlight_options = {
          no_match_size: 150,
          fragment_size: 150,
          number_of_fragments: 1,
          pre_tags: ["<span class='highlight'>"],
          post_tags: ["</span>"],
          encoder: 'html'
        }

        {fields: {thread_title: highlight_options, body: highlight_options}}
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
    "<thread-#{thread_id}/post-#{post_number}@community.recurse.com>"
  end

  def set_message_id
    # message_id will already be set if the post was created by email
    self.message_id ||= generate_message_id
  end

  def generate_message_id
    format_message_id(thread_id, post_number)
  end
end
