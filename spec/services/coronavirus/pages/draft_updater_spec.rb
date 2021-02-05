require "rails_helper"

RSpec.describe Coronavirus::Pages::DraftUpdater do
  include CoronavirusFeatureSteps

  let(:page) { create :coronavirus_page }
  let(:content_builder) { Coronavirus::Pages::ContentBuilder.new(page) }
  let(:payload) { Coronavirus::PagePresenter.new(content_builder.data, page.base_path).payload }
  let(:github_fixture_path) { Rails.root.join "spec/fixtures/coronavirus_landing_page.yml" }
  let(:github_content) { YAML.safe_load(File.read(github_fixture_path)) }

  subject { described_class.new(page) }

  before do
    stub_coronavirus_publishing_api
    stub_request(:get, Regexp.new(page.raw_content_url))
      .to_return(status: 200, body: github_content.to_json)
  end

  it "#payload" do
    expect(subject.payload).to eq payload
  end
end
