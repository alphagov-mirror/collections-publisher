require "rails_helper"

RSpec.describe CoronavirusPagePresenter do
  include GovukContentSchemaTestHelpers

  let(:content) {
    {
      "title" => "coronavirus",
      "meta_description" => "details about the coronavirus response",
      "sections" => "some sections",
    }
  }

  let(:landing_page_path) { "/coronavirus" }

  subject { described_class.new(content, landing_page_path) }

  it "presents the payload correctly" do
    url = "https://www.youtube.com/123"
    stub_request(:get, url)

    LiveStream.create(url: url)
    date = subject.todays_date
    presented = subject.payload

    expect(presented).to be_valid_against_schema("coronavirus_landing_page")
    expect(presented).to eq(
      {
        "base_path" => landing_page_path,
        "title" => "coronavirus",
        "description" => "details about the coronavirus response",
        "document_type" => "coronavirus_landing_page",
        "schema_name" => "coronavirus_landing_page",
        "details" => {
          "sections" => "some sections",
          "live_stream" => {
            "video_url" => LiveStream.last.url,
            "date" => date,
},
        },
        "links" => {},
        "locale" => "en",
        "rendering_app" => "collections",
        "publishing_app" => "collections-publisher",
        "routes" => [
          { "path" => landing_page_path, "type" => "exact" },
        ],
        "update_type" => "minor",
      },
    )
  end
end
