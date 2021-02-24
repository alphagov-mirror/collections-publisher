require "rails_helper"

RSpec.describe Coronavirus::SubSectionsController do
  include CoronavirusFeatureSteps

  render_views

  let(:stub_user) { create :user, :coronovirus_editor, name: "Name Surname" }
  let(:page) { create :coronavirus_page, :of_known_type }
  let!(:sub_section) { create :coronavirus_sub_section, page: page }
  let(:title) { Faker::Lorem.sentence }
  let(:content) { "###{Faker::Lorem.sentence}" }
  let(:sub_section_params) do
    {
      title: title,
      content: content,
    }
  end
  let(:raw_content_url) { page.raw_content_url }
  let(:raw_content_url_regex) { Regexp.new(raw_content_url) }
  let(:fixture_path) { Rails.root.join "spec/fixtures/coronavirus_landing_page.yml" }
  let(:raw_content) { File.read(fixture_path) }

  describe "GET /coronavirus/:page_slug/sub_sections/new" do
    it "renders successfully" do
      get :new, params: { page_slug: page.slug }
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /coronavirus/:page_slug/sub_sections" do
    before do
      stub_request(:get, raw_content_url_regex)
        .to_return(body: raw_content)
      stub_coronavirus_publishing_api
    end
    subject do
      post :create, params: { page_slug: page.slug, sub_section: sub_section_params }
    end

    it "redirects to coronavirus page on success" do
      expect(subject).to redirect_to(coronavirus_page_path(page.slug))
    end

    it "create a new sub_section" do
      expect { subject }.to change { Coronavirus::SubSection.count }.by(1)
    end

    it "adds attributes to new sub_section" do
      subject
      sub_section = Coronavirus::SubSection.last
      expect(sub_section.title).to eq(title)
      expect(sub_section.content).to eq(content)
    end

    context "publishing api is returning a service error" do
      before do
        stub_any_publishing_api_put_content
          .to_return(status: 500)
      end
      it "successfully renders error on edit page" do
        expect(subject).to have_http_status(:success)
      end

      it "displays the expected error" do
        expect(subject.body).to include("Failed to update the draft content item. Try saving again.")
      end
    end

    context "subsection content error" do
      let(:content) { "bad_content" }

      it "doesn't save to the database" do
        expect { subject }.not_to(change { Coronavirus::SubSection.count })
      end

      it "successfully renders error on edit page" do
        expect(subject).to have_http_status(:success)
      end

      it "displays the expected error" do
        expect(subject.body).to include("Unable to parse markdown:")
      end
    end

    context "featured_links" do
      let(:featured_link) { "/#{SecureRandom.urlsafe_base64}" }

      it "stores the featured link" do
        content_id = SecureRandom.uuid
        stub_publishing_api_has_item(base_path: featured_link, content_id: content_id)
        stub_publishing_api_has_lookups(featured_link.to_s => content_id)

        content = "###{Faker::Lorem.sentence}\n[Link text](#{featured_link})"
        sub_section_params.merge!(content: content, featured_link: featured_link)

        subject
        sub_section = Coronavirus::SubSection.last
        expect(sub_section.featured_link).to eq(featured_link)
      end

      it "successfully renders error on edit page if featured link not in content" do
        sub_section_params.merge!(featured_link: featured_link)
        expect(subject).to have_http_status(:success)
      end

      it "displays the expected error if featured link not in content" do
        sub_section_params.merge!(featured_link: featured_link)
        expect(subject.body).to include("Featured link does not exist in accordion content")
      end
    end
  end

  describe "GET /coronavirus/:page_slug/sub_sections/:id/edit" do
    it "renders successfully" do
      get :edit, params: { id: sub_section, page_slug: page.slug }
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /coronavirus/:page_slug/sub_sections" do
    before do
      stub_request(:get, raw_content_url_regex)
        .to_return(body: raw_content)
      stub_coronavirus_publishing_api
    end
    let(:params) do
      {
        id: sub_section,
        page_slug: page.slug,
        sub_section: sub_section_params,
      }
    end

    subject { patch :update, params: params }

    it "redirects to coronavirus page on success" do
      expect(subject).to redirect_to(coronavirus_page_path(page.slug))
    end

    it "updates the sub_section" do
      expect { subject }.not_to(change { Coronavirus::SubSection.count })
    end

    it "changes the attributes of the subsection" do
      subject
      sub_section.reload
      expect(sub_section.title).to eq(title)
      expect(sub_section.content).to eq(content)
    end

    context "given invalid content" do
      let(:content) { "invalid content" }

      it "doesn't change the subsection" do
        expect { subject }.not_to(change { sub_section.reload.attributes })
        expect(subject.body).to include("Unable to parse markdown")
      end
    end

    context "given a featured link that is not in the content" do
      it "displays the expected error" do
        sub_section_params.merge!(featured_link: "/banana")
        expect(subject.body).to include("Featured link does not exist in accordion content")
      end
    end
  end

  describe "DELETE /coronavirus/:page_slug/sub_sections/:id" do
    before do
      stub_request(:get, raw_content_url_regex)
        .to_return(body: raw_content)
      stub_coronavirus_publishing_api
    end
    let(:params) do
      {
        id: sub_section,
        page_slug: page.slug,
      }
    end
    subject { delete :destroy, params: params }

    it "redirects to the coronavirus page on success" do
      expect(subject).to redirect_to(coronavirus_page_path(page.slug))
    end

    it "deletes the subsection" do
      expect { subject }.to change { Coronavirus::SubSection.count }.by(-1)
    end

    it "doesn't delete the subsection if draft_updater fails" do
      stub_publishing_api_isnt_available

      expect { subject }.to_not(change { page.reload.sub_sections.to_a })
    end
  end
end
