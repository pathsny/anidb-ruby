require_relative 'model'
require 'forwardable'
require 'veto'
require 'json'
require_relative '../lib/feed'


class ShowValidator
  include Veto.validator

  validates :id, :presence => true
  validates :name, :presence => true
  validates :feed, :presence => true
  validates :auto_fetch, :presence => true

  validate :show_must_be_unique, :if => :is_new?

  validate :feed_must_be_valid

  def is_new?(entity)
    entity.is_new?
  end  

  def show_must_be_unique(entity)
    errors.add(:id, "show must be unique") if entity.has_instance_in_db?
  end
  
  def feed_must_be_valid(entity)
    errors.add(:feed, "Invalid feed url") unless Feed.is_valid?(entity.feed)
  end   
end

class Show
  include Model

  attr_reader :id, :name, :feed, :auto_fetch  

  # note changing the order of marshal fields, or adding a field will require 
  # changing the model version and creating a migration
  configure_model(
    :version => 1, 
    :validator => ShowValidator,
    :marshal_fields => [:id, :name, :feed, :auto_fetch, :created_at, :updated_at]
  )

  def initialize(id, name, feed, auto_fetch)
    super()
    @id = id
    @name = name
    @feed = feed
    @auto_fetch = auto_fetch
  end

  def to_json(*a)
    {
      id: id.to_i,
      name: name,
      created_at: created_at,
      feed: feed,
      auto_fetch: auto_fetch
    }.to_json(*a)
  end
end  