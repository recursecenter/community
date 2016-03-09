require 'open-uri'
require 'json'
require 'set'

class AccountImporter
  class ImportError < StandardError; end

  def self.import_all
    open("#{HackerSchool.site}/api/v1/people?secret_token=#{HackerSchool.secret_token}") do |f|
      JSON.parse(f.read).each do |user_data|
        new(user_data).import
      end
    end
  end

  attr_reader :user, :user_data
  private :user, :user_data

  def initialize(user_data)
    @user_data = user_data
    @user = User.where(hacker_school_id: user_data["id"]).first_or_initialize
  end

  def import
    return if user.deactivated?

    User.transaction do
      set_or_update_user_data
      autosubscribe_to_subforums
    end

    user
  end

  private

  def set_or_update_user_data
    user.hacker_school_id = user_data["id"]
    user.first_name = user_data["first_name"]
    user.last_name = user_data["last_name"]
    user.email = user_data["email"]
    user.avatar_url = user_data["image"] if user_data["has_photo"]
    user.batch_name = user_data["community_affiliation"]
    user.groups = get_groups
    user.roles = get_roles

    # The welcome message doesn't make sense for RC start participants. Hide it.
    if rc_start_participant?
      user.last_read_welcome_message_at = Time.zone.now
    end

    user.save!
  end

  def autosubscribe_to_subforums
    names = autosubscribe_subforum_names

    subforums = Subforum.where(name: names)

    # Use subforums.length to force the query for the actual data instead of
    # the count so we don't trigger a second query when we call subforums.each
    unless subforums.length == names.size
      raise ImportError, "Got a different number of subforums (#{subforums.length}) than we had subforum names (#{names.size})."
    end

    subforums.each do |subforum|
      user.subscribe_to_unless_existing(subforum, "You are receiving emails because you were auto-subscribed when your account was created.")
    end
  end

  def get_groups
    groups = [Group.everyone]

    if user_data["batch"]
      groups += [Group.for_batch_api_data(user_data["batch"])]
    end

    if rc_start_participant?
      groups += [Group.rc_start]
    end

    if currently_at_hacker_school? || faculty?
      groups += [Group.current_hacker_schoolers]
    end

    if faculty?
      groups += [Group.faculty]
    end

    groups
  end

  def get_roles
    roles = user.roles.to_set

    if !rc_start_participant?
      roles << Role.pre_batch
    end

    if rc_start_participant? || full_hacker_schooler?
      roles << Role.rc_start
    end

    roles << Role.full_hacker_schooler if full_hacker_schooler?

    if faculty?
      roles |= [Role.pre_batch, Role.rc_start, Role.full_hacker_schooler, Role.admin]
    end

    roles.to_a
  end

  def autosubscribe_subforum_names
    names = []

    # currently_at_hacker_school? includes residents. hacker_schooler? does not.
    names += ["Welcome", "Housing"] if hacker_schooler? && batch_in_the_future?
    names += ["New York", "455 Broadway"] if currently_at_hacker_school?
    names += ["General"] if currently_at_hacker_school? && should_subscribe_to_general?

    names
  end

  GENERAL_SUBFORUM_SUBSCRIPTION_CUTOFF = Date.parse("December 3, 2015")

  def should_subscribe_to_general?
    user.created_at >= GENERAL_SUBFORUM_SUBSCRIPTION_CUTOFF
  end

  def batch_in_the_future?
    !full_hacker_schooler?
  end

  def full_hacker_schooler?
    user_data["batch"] && (Date.parse(user_data["batch"]["start_date"]) - 1.day).past?
  end

  def rc_start_participant?
    user_data["is_rc_start_participant"]
  end

  def faculty?
    user_data["is_faculty"]
  end

  def hacker_schooler?
    user_data["is_hacker_schooler"]
  end

  def currently_at_hacker_school?
    user_data["currently_at_hacker_school"]
  end
end
