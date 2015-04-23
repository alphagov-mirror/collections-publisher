# == Schema Information
#
# Table name: lists
#
#  id       :integer          not null, primary key
#  name     :string(255)
#  index    :integer          default(0), not null
#  dirty    :boolean          default(TRUE), not null
#  topic_id :integer
#
# Indexes
#
#  index_lists_on_topic_id  (topic_id)
#

class List < ActiveRecord::Base
  has_many :list_items, dependent: :destroy
  belongs_to :topic

  scope :ordered, -> { order(:index) }

  def tagged_list_items
    @tagged_list_items ||= list_items.order(:index).select {|c| tagged_api_urls.include?(c.api_url) }
  end

  def untagged_list_items
    @tagged_list_items ||= list_items - tagged_list_items
  end

  def mark_as_published
    self.dirty = false
  end

  def mark_as_published!
    mark_as_published
    save
  end

private

  def tagged_api_urls
    @tagged_api_urls ||= topic.list_items_from_contentapi.map(&:api_url)
  end
end
