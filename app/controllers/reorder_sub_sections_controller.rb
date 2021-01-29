class ReorderSubSectionsController < ApplicationController
  before_action :require_coronavirus_editor_permissions!
  layout "admin_layout"

  def index
    coronavirus_page
  end

  def update
    success = true
    current_positions

    SubSection.transaction do
      set_positions(submitted_positions)

      unless draft_updater.send
        success = false
        raise ActiveRecord::Rollback
      end
    end

    if success
      message = "Sections were successfully reordered."
      redirect_to coronavirus_page_path(coronavirus_page.slug), notice: message
    else
      message = "Sorry! Sections have not been reordered: #{draft_updater.errors.to_sentence}."
      redirect_to reorder_coronavirus_page_sub_sections_path(coronavirus_page.slug), alert: message
    end
  end

private

  def coronavirus_page
    @coronavirus_page ||= CoronavirusPage.find_by!(slug: params[:coronavirus_page_slug])
  end

  def current_positions
    @current_positions ||= coronavirus_page.sub_sections.map do |sub_section|
      { "id" => sub_section.id, "position" => sub_section.position }
    end
  end

  def submitted_positions
    JSON.parse(params[:section_order_save])
  end

  def set_positions(positions)
    positions.each do |sub_section|
      SubSection.find(sub_section["id"]).update_column(:position, sub_section["position"])
    end
  end

  def draft_updater
    @draft_updater ||= CoronavirusPages::DraftUpdater.new(coronavirus_page)
  end

  def page_configs
    CoronavirusPages::Configuration.all_pages
  end
end
