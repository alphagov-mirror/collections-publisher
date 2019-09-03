class StepByStepPagePresenter
  include TimeOptionsHelper
  attr_reader :step_by_step_page

  def initialize(step_by_step_page)
    @step_by_step_page = step_by_step_page
  end

  def summary_metadata
    items = {
      "Status" => step_by_step_page.status.humanize,
      "Last saved" => last_saved,
      "Created" => format_full_date_and_time(step_by_step_page.created_at),
    }

    if step_by_step_page.links_checked?
      items.merge!(
        "Links checked" => format_full_date_and_time(step_by_step_page.links_last_checked_date)
      )
    end
    items
  end

  def last_saved
    last_saved_time = format_full_date_and_time(step_by_step_page.updated_at)
    return "#{last_saved_time} by #{step_by_step_page.assigned_to}" if assigned?

    last_saved_time
  end

  def assigned?
    step_by_step_page.assigned_to.present?
  end
end
