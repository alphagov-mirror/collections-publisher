require "rails_helper"

RSpec.describe Coronavirus::SubSection do
  let(:sub_section) { create :coronavirus_sub_section }

  describe "validations" do
    it "should belong to a page" do
      should validate_presence_of(:page)
    end

    it "fails if page does not exist" do
      sub_section.page = nil

      expect(sub_section).not_to be_valid
    end

    it "is created with valid attributes" do
      expect(sub_section).to be_valid
      expect(sub_section.save).to eql true
      expect(sub_section).to be_persisted
    end

    it "requires a title" do
      sub_section.title = ""

      expect(sub_section).not_to be_valid
      expect(sub_section.errors).to have_key(:title)
    end

    it "requires content" do
      sub_section.content = ""

      expect(sub_section).not_to be_valid
      expect(sub_section.errors).to have_key(:content)
    end

    describe "action link fields" do
      it "validates if none of the action link fields are filled in" do
        sub_section.action_link_url = ""
        sub_section.action_link_content = nil
        sub_section.action_link_summary = ""

        expect(sub_section).to be_valid
      end

      it "validates if all of the action link fields are filled in" do
        sub_section.action_link_url = "/bananas"
        sub_section.action_link_content = "Bananas"
        sub_section.action_link_summary = "Bananas"

        expect(sub_section).to be_valid
      end

      it "fails if not all of the action link fields are filled in" do
        sub_section.action_link_url = "/bananas"
        sub_section.action_link_content = ""
        sub_section.action_link_summary = nil

        expect(sub_section).not_to be_valid
        expect(sub_section.errors).to have_key(:action_link_content)
        expect(sub_section.errors).to have_key(:action_link_summary)
      end

      it "validates if under 255 characters long" do
        string = Faker::Lorem.characters(number: 255)

        sub_section.action_link_url = "/#{Faker::Lorem.characters(number: 254)}"
        sub_section.action_link_content = string
        sub_section.action_link_summary = string

        expect(sub_section).to be_valid
      end

      it "fails if over 255 characters long" do
        string = Faker::Lorem.characters(number: 256)

        sub_section.action_link_url = "/#{Faker::Lorem.characters(number: 255)}"
        sub_section.action_link_content = string
        sub_section.action_link_summary = string

        expect(sub_section).not_to be_valid
      end
    end
  end

  describe "#action_link_present?" do
    it "should be present if all action link fields are populated" do
      sub_section.action_link_url = "/bananas"
      sub_section.action_link_content = "Bananas"
      sub_section.action_link_summary = "Bananas"

      expect(sub_section.action_link_present?).to be(true)
    end

    it "should not be present if not all action link fields are populated" do
      sub_section.action_link_url = "/bananas"
      sub_section.action_link_content = nil
      sub_section.action_link_summary = ""

      expect(sub_section.action_link_present?).to be(false)
    end
  end

  describe "#action_link_blank?" do
    it "should be blank if all action link fields are empty" do
      sub_section.action_link_url = nil
      sub_section.action_link_content = ""
      sub_section.action_link_summary = nil

      expect(sub_section.action_link_blank?).to be(true)
    end

    it "should not be blank if not all action link fields are empty" do
      sub_section.action_link_url = "/bananas"
      sub_section.action_link_content = nil
      sub_section.action_link_summary = ""

      expect(sub_section.action_link_blank?).to be(false)
    end
  end
end
