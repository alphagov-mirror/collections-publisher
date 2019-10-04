module StepByStepFilter
  class Options
    def self.statuses(selected = nil)
      statuses = StepByStepPage::STATUSES.map do |status|
        {
          text: I18n.t!("step_by_step_page.statuses.#{status}"),
          value: status,
          data_attributes: {
            show: status,
          },
          selected: selected.present? && selected == status,
        }
      end

      statuses.unshift(
        text: "All",
        data_attributes: {
          show: "all",
        },
        selected: selected.blank?,
      )
    end
  end
end
