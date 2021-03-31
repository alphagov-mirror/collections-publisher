require "rails_helper"

RSpec.describe Coronavirus::Announcement, type: :model do
  describe "validations" do
    let(:announcement) { build :coronavirus_announcement }

    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:url) }

    describe "url validations" do
      it { should allow_values("/path", "https://example.com").for(:url) }
      it { should_not allow_values("not a url").for(:url) }

      it "doesn't apply the URL format validation when the field is blank" do
        announcement.url = ""
        expect(announcement).not_to be_valid
        expect(announcement.errors[:url]).to eq(["can't be blank"])
      end
    end

    describe "published_on validations" do
      it "validates that published_on is a valid date" do
        announcement.published_on = { "day" => -1, "month" => 1, "year" => 2020 }

        expect(announcement).not_to be_valid
        expect(announcement.errors[:published_on]).to eq(["must be a valid date"])
      end

      it "validates that published_on was at least this century" do
        announcement.published_on = Date.new(1999, 1, 1)

        expect(announcement).not_to be_valid
        expect(announcement.errors[:published_on]).to eq(["must be this century"])
      end

      it "validates that published_on is not in the future" do
        announcement.published_on = Date.tomorrow

        expect(announcement).not_to be_valid
        expect(announcement.errors[:published_on]).to eq(["must not be in the future"])
      end
    end
  end

  describe "position" do
    it "should default to position 1 if it is the first announcement to have been added" do
      page = create(:coronavirus_page)
      expect(page.announcements.count).to eq 0

      announcement = create(:coronavirus_announcement, page: page)
      expect(announcement.position).to eq 1
    end

    it "should increment if there are existing announcements" do
      page = create(:coronavirus_page)
      create(:coronavirus_announcement, page: page)
      expect(page.announcements.count).to eq 1

      announcement = create(:coronavirus_announcement, page: page)
      expect(announcement.position).to eq 2
    end

    it "should update announcement positions when an announcement is deleted" do
      page = create(:coronavirus_page)
      create(:coronavirus_announcement, page: page)
      create(:coronavirus_announcement, page: page)
      expect(page.announcements.count).to eq 2

      original_announcement_one = page.announcements.first
      original_announcement_two = page.announcements.last
      expect(original_announcement_one.position).to eq 1
      expect(original_announcement_two.position).to eq 2

      original_announcement_one.destroy!
      page.reload
      original_announcement_two.reload

      expect(original_announcement_two.position).to eq 1
      expect(page.announcements.first).to eq original_announcement_two
      expect(page.announcements.count).to eq 1
    end
  end

  describe "#published_on=" do
    let(:announcement) { build(:coronavirus_announcement) }

    it "can accept published_on as a hash" do
      announcement.published_on = { "day" => "1", "month" => "1", "year" => "2020" }
      expect(announcement.published_on).to eq(Date.new(2020, 1, 1))
    end

    it "sets published_on to nil for an invalid date" do
      announcement.published_on = { "day" => "1", "month" => "13", "year" => "2020" }
      expect(announcement.published_on).to be_nil
    end

    it "sets published_on to nil for an empty date" do
      announcement.published_on = { "day" => "", "month" => "", "year" => "" }
      expect(announcement.published_on).to be_nil
    end

    it "can still accept published_on as a date" do
      announcement.published_on = Time.zone.today
      expect(announcement.published_on).to eq(Time.zone.today)
    end
  end
end
