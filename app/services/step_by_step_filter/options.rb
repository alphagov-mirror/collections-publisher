module StepByStepFilter
  class Options
    def self.statuses
      options = StepByStepPage::STATUSES.map do |status|
        {
          text: status.humanize,
          value: status,
          data_attributes: {
            show: status
          },
        }
      end

      options.unshift(
        text: "All",
        data_attributes: {
          show: "all"
        },
      )

      options
    end
  end
end
