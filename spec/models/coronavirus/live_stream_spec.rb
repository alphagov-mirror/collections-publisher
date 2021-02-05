require "rails_helper"

RSpec.describe Coronavirus::LiveStream do
  describe "validations" do
    let(:bad_url) { "www.youtbe.co.uk/123" }
    let(:good_url) { "https://www.youtube.com/123" }
    before do
      stub_request(:get, bad_url).to_return(status: 404)
      stub_request(:get, good_url)
    end

    it "is invalid without a url" do
      expect(build(:live_stream, url: nil)).not_to be_valid
    end

    it "it requires a valid url" do
      expect(build(:live_stream, url: bad_url)).not_to be_valid
      expect(build(:live_stream, url: good_url)).to be_valid
    end
  end
end
