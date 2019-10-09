module ApplicationHelper
  def website_url(base_path)
    Plek.new.website_root + base_path
  end

  def content_tagger_url
    Plek.new.external_url_for("content-tagger")
  end

  def draft_govuk_url(path)
    Plek.find("draft-origin", external: true) + path
  end

  def step_by_step_preview_url(step_by_step_page)
    token = JWT.encode({ "sub" => step_by_step_page.auth_bypass_id }, ENV["JWT_AUTH_SECRET"], "HS256")
    "#{draft_govuk_url("/#{step_by_step_page.slug}")}?token=#{token}"
  end

  def published_url(slug)
    "#{Plek.new.website_root}/#{slug}"
  end

  def markdown_to_html(markdown)
    raw(Kramdown::Document.new(markdown).to_html)
  end

  def render_markdown(content)
    render "govuk_publishing_components/components/govspeak" do
      markdown_to_html(content)
    end
  end
end
