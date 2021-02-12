module Coronavirus
  class ReorderTimelineEntriesController < ApplicationController
    before_action :require_coronavirus_editor_permissions!
    layout "admin_layout"

    def index
      page
    end

    def update
      success = true
      reordered_timeline_entries = params[:timeline_entry_order_save]

      TimelineEntry.transaction do
        reordered_timeline_entries.each do |id, position|
          timeline_entry = page.timeline_entries.find(id)
          timeline_entry.update_column(:position, position)
        end

        unless draft_updater.send
          success = false
          raise ActiveRecord::Rollback
        end
      end

      if success
        message = I18n.t("coronavirus.pages.timeline_entries.reorder.success")
        redirect_to coronavirus_page_path(page.slug), notice: message
      else
        message = I18n.t("coronavirus.pages.timeline_entries.reorder.error", error: draft_updater.errors.to_sentence)
        redirect_to reorder_coronavirus_page_timeline_entries_path(page.slug), alert: message
      end
    end

  private

    def page
      @page ||= Page.find_by!(slug: params[:page_slug])
    end

    def draft_updater
      @draft_updater ||= Pages::DraftUpdater.new(page)
    end
  end
end
