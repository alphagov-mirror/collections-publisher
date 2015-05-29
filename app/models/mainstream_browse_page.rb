# == Schema Information
#
# Table name: tags
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  slug        :string(255)      not null
#  title       :string(255)      not null
#  description :string(255)
#  parent_id   :integer
#  created_at  :datetime
#  updated_at  :datetime
#  content_id  :string(255)      not null
#  state       :string(255)      not null
#  dirty       :boolean          default(FALSE), not null
#  beta        :boolean          default(FALSE)
#
# Indexes
#
#  index_tags_on_content_id          (content_id) UNIQUE
#  index_tags_on_slug_and_parent_id  (slug,parent_id) UNIQUE
#  tags_parent_id_fk                 (parent_id)
#

class MainstreamBrowsePage < Tag
  has_many :topics, through: :tag_associations, source: :to_tag

  validate :parents_cannot_have_topics_associated

  def base_path
    "/browse#{super}"
  end

  def tag_type
    'section'
  end

private

  def parents_cannot_have_topics_associated
    if !parent.present? and topics.any?
      errors.add(:topics, "top-level mainstream browse pages cannot have topics assigned to them")
    end
  end
end
