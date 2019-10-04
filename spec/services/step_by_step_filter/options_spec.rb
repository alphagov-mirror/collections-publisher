require "rails_helper"

RSpec.describe StepByStepFilter::Options do
  describe ".statuses" do
    it "returns a list of status options with an empty all option" do
      statuses = described_class.statuses.map { |s| s[:value] }
      expect(statuses).to match [nil] + StepByStepPage::STATUSES
    end

    it "defaults to all option selected" do
      expect(described_class.statuses)
        .to include(text: "All",
                    data_attributes: { show: "all" },
                    selected: true)
    end

    it "returns filter options with the selected status" do
      expect(described_class.statuses("scheduled"))
        .to include(text: "Scheduled",
                    value: "scheduled",
                    data_attributes: { show: "scheduled" },
                    selected: true)
    end
  end
end
