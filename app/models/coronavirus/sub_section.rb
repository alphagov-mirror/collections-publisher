class Coronavirus::SubSection < ApplicationRecord
  belongs_to :page, foreign_key: "coronavirus_page_id"
  validates :title, :content, presence: true
  validates :page, presence: true

  validate :featured_link_must_be_in_content

  def featured_link_must_be_in_content
    if featured_link.present? && !content.include?(featured_link)
      errors.add(:featured_link, "does not exist in accordion content")
    end
  end
end
