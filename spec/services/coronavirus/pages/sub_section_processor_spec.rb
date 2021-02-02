require "rails_helper"

RSpec.describe Coronavirus::Pages::SubSectionProcessor do
  let(:title) { Faker::Lorem.sentence }
  let(:label) { Faker::Lorem.sentence }
  let(:url) { "/#{File.join(Faker::Lorem.words)}" }
  let(:label_1) { Faker::Lorem.sentence }
  let(:url_1) { "/#{File.join(Faker::Lorem.words)}?priority-taxon=774cee22-d896-44c1-a611-e3109cce8eae" }
  let(:data) do
    [
      {
        "title" => title,
        "list" => [
          {
            "label" => label,
            "url" => url,
            "featured_link" => true,
            "description" => Faker::Lorem.sentence,
          },
          {
            "label" => label_1,
            "url" => url_1,
          },
        ],
      },
    ]
  end

  describe ".call" do
    subject { described_class.call(data) }
    let(:lines) { subject[:content].split("\n") }

    it "creates the correct number of lines" do
      # 3 = 1 title plus 2 links
      expect(lines.count).to eq 3
    end

    it "has title as the first line" do
      expect(lines.first).to eq "####{title}"
    end

    it "has the first link as the second line" do
      expect(lines.second).to eq "[#{label}](#{url})"
    end

    it "removes any priority-taxons query parameters from the url" do
      expect(lines.third).to eq "[#{label_1}](#{url_1.gsub('?priority-taxon=774cee22-d896-44c1-a611-e3109cce8eae', '')})"
    end

    it "returns the featured link" do
      expect(subject[:featured_link]).to eq(url)
    end

    context "with blank title" do
      let(:title) { "" }

      it "has the first link as its first line" do
        expect(lines.first).to eq "[#{label}](#{url})"
      end
    end
  end
end
