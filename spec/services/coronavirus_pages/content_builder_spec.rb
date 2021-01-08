require "rails_helper"

RSpec.describe CoronavirusPages::ContentBuilder do
  let(:coronavirus_page) { create :coronavirus_page, :landing }
  let(:fixture_path) { Rails.root.join "spec/fixtures/coronavirus_landing_page.yml" }
  let(:github_content) { YAML.safe_load(File.read(fixture_path)) }
  let(:sub_section_json) { SubSectionJsonPresenter.new(sub_section, coronavirus_page.content_id).output }
  let(:announcement_json) { AnnouncementJsonPresenter.new(announcement).output }
  let(:timeline_json) { { "heading" => timeline_entry["heading"], "paragraph" => timeline_entry["content"] } }

  subject { described_class.new(coronavirus_page) }
  before do
    stub_request(:get, Regexp.new(coronavirus_page.raw_content_url))
      .to_return(status: 200, body: github_content.to_json)
  end
  describe "#github_data" do
    it "returns github content" do
      expect(subject.github_data).to eq github_content["content"]
    end
  end

  describe "#data" do
    let!(:sub_section) { create :sub_section, coronavirus_page_id: coronavirus_page.id }
    let!(:announcement) { create :announcement, coronavirus_page: coronavirus_page }
    let!(:timeline_entry) { create :timeline_entry, coronavirus_page: coronavirus_page }
    let!(:live_stream) { create :live_stream, :without_validations }
    let(:github_livestream_data) { github_content.dig("content", "live_stream") }

    let(:live_stream_data) do
      github_livestream_data.merge(
        "video_url" => live_stream.url,
        "date" => live_stream.formatted_stream_date,
      )
    end

    let(:data) { github_content["content"].deep_dup }

    let(:hidden_search_terms) do
      [
        sub_section_json[:title],
        sub_section_json[:sub_sections].first[:list].first[:label],
        data["timeline"]["list"].first["heading"],
        MarkdownService.new.strip_markdown(data["timeline"]["list"].first["paragraph"]),
      ]
    end

    before do
      data["sections"] = [sub_section_json]
      data["live_stream"] = live_stream_data
      data["announcements"] = [announcement_json]
      data["timeline"]["list"] = [timeline_json]
      data["hidden_search_terms"] = hidden_search_terms
    end

    it "returns github and model data" do
      expect(subject.data).to eq data
    end

    context "when unreleased features are off" do
      before do
        allow(Rails.configuration).to receive(:unreleased_features).and_return(false)
      end

      it "includes the timeline data from github" do
        expect(subject.data["timeline"]["list"])
          .to eq(github_content["content"]["timeline"]["list"])
      end
    end
  end

  describe "#sub_sections_data" do
    it "returns the sub_sections" do
      expect(subject.sub_sections_data).to eq []
    end

    context "with subsections" do
      let!(:sub_section_0) { create :sub_section, position: 0, coronavirus_page: coronavirus_page }
      let!(:sub_section_1) { create :sub_section, position: 1, coronavirus_page: coronavirus_page }
      let(:sub_section_0_json) { SubSectionJsonPresenter.new(sub_section_0).output }
      let(:sub_section_1_json) { SubSectionJsonPresenter.new(sub_section_1).output }

      it "returns the sub_section JSON ordered by position" do
        expect(subject.sub_sections_data).to eq [sub_section_0_json, sub_section_1_json]
      end
    end
  end

  describe "#announcements_data" do
    context "with announcements" do
      let!(:announcement_0) { create :announcement, published_at: Time.zone.local(2020, 9, 10), coronavirus_page: coronavirus_page  }
      let!(:announcement_1) { create :announcement, published_at: Time.zone.local(2020, 9, 11), coronavirus_page: coronavirus_page  }
      let!(:announcement_0_json) { AnnouncementJsonPresenter.new(announcement_0).output }
      let!(:announcement_1_json) { AnnouncementJsonPresenter.new(announcement_1).output }

      it "returns the announcements JSON ordered by position" do
        announcement_0.position = 3
        announcement_0.save!
        expect(subject.announcements_data).to eq [announcement_1_json, announcement_0_json]
      end
    end
  end

  describe "#timeline_data" do
    let!(:timeline_entry_0) { create :timeline_entry, position: 2, coronavirus_page: coronavirus_page  }
    let!(:timeline_entry_1) { create :timeline_entry, position: 1, coronavirus_page: coronavirus_page  }

    it "returns the timeline JSON ordered by position" do
      expect(subject.timeline_data).to eq [
        { "heading" => timeline_entry_1.heading, "paragraph" => timeline_entry_1.content },
        { "heading" => timeline_entry_0.heading, "paragraph" => timeline_entry_0.content },
      ]
    end
  end

  describe "#add_live_stream" do
    let(:data) { github_content["content"] }

    it "adds livestream data from github and the database" do
      live_stream = create(:live_stream, :without_validations)

      subject.add_live_stream(data)
      expect(data["live_stream"]["video_url"]).to eq(live_stream.url)
    end

    it "only adds livestream data from github if there isn't a livestream in the database" do
      subject.add_live_stream(data)
      expect(data["live_stream"]["video_url"]).to be_nil
    end
  end

  describe "#success?" do
    it "is true if call successful" do
      expect(subject.success?).to be(true)
    end

    context "on failure" do
      before do
        stub_request(:get, Regexp.new(coronavirus_page.raw_content_url))
          .to_return(status: 400)
      end

      it "is false" do
        expect(subject.success?).to be(false)
      end
    end
  end
end
