module StatusHelper
  def status(text, type)
    class_name = {
      published: :success,
      draft: :info,
      archived: :default,
    }[type.to_sym] || type

    content_tag :span, text, class: "label label-#{class_name}"
  end

  def labels_for_tag(tag)
    labels = []
    labels << draft_tag if tag.draft?
    labels << dirty_tag if tag.dirty?
    labels << archived_tag if tag.archived?
    raw labels.join(" ") # rubocop:disable Rails/OutputSafety
  end

  def dirty_tag
    status "Unpublished changes", :danger
  end

  def archived_tag
    status "Archived", :default
  end

  def draft_tag
    status "draft", :draft
  end
end
