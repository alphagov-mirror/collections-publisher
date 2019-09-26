class StepByStepPagesController < ApplicationController
  include PublishingApiHelper
  include TimeOptionsHelper
  layout "admin_layout"

  before_action :require_gds_editor_permissions!
  before_action :set_step_by_step_page, only: %i[show edit update destroy]
  before_action :require_to_be_2i_approved, only: %i[publish schedule]

  def index
    @step_by_step_pages = StepByStepFilter::Results.new(filter_params).call
  end

  def new
    @step_by_step_page = StepByStepPage.new
  end

  def show
    @step_by_step_page_presenter = StepByStepPagePresenter.new(@step_by_step_page)
  end

  def reorder
    set_current_page_as_step_by_step
    if request.post? && params.key?(:step_order_save)
      reordered_steps = JSON.parse(params[:step_order_save])
      reordered_steps.each do |step_data|
        step = @step_by_step_page.steps.find(step_data["id"])
        step.update_attribute(:position, step_data["position"])
      end
      update_downstream
      redirect_to @step_by_step_page, notice: "Steps were successfully reordered."
    end
  end

  def edit; end

  def create
    create_params = step_by_step_page_params.merge(status: "draft")
    @step_by_step_page = StepByStepPage.new(create_params)
    if @step_by_step_page.save
      update_downstream
      redirect_to @step_by_step_page, notice: "Step by step page was successfully created."
    else
      render :new
    end
  end

  def update
    if @step_by_step_page.update(step_by_step_page_params)
      update_downstream
      redirect_to step_by_step_page_path, notice: "Step by step page was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    if @step_by_step_page.destroy
      discard_draft
      redirect_to step_by_step_pages_path, notice: "Step by step page was successfully deleted."
    else
      render :edit
    end
  end

  def publish
    set_current_page_as_step_by_step
    if request.post?
      @publish_intent = PublishIntent.new(publish_intent_params)
      if @publish_intent.valid?
        note_description = publish_note_description
        publish_page(@publish_intent)
        generate_internal_change_note(note_description)
        set_change_note_version
        redirect_to @step_by_step_page, notice: "'#{@step_by_step_page.title}' has been published."
      end
    end
  end

  def schedule
    set_current_page_as_step_by_step
  end

  def schedule_datetime
    set_current_page_as_step_by_step
    if params[:schedule]
      date_params = params[:schedule][:date].permit(:year, :month, :day).to_h.symbolize_keys
      time_param = params[:schedule][:time]
      @schedule_placeholder = default_datetime_placeholder(date_params.merge(time: time_param))
      @parser = DatetimeParser.new(date: date_params, time: time_param)
      scheduled_at = @parser.parse
      if @parser.issues.any?
        @parser.issues.each do |issue|
          @step_by_step_page.errors.add :base, issue.values.first
        end
        render :schedule_datetime
      elsif @step_by_step_page.update_attributes(scheduled_at: scheduled_at)
        schedule_to_publish(session[:update_type], session[:public_change_note])
        note_description = "Scheduled by #{current_user.name} for publishing at #{format_full_date_and_time(scheduled_at)}"
        note_description << " with change note: #{session[:public_change_note]}" if session[:public_change_note].present?
        generate_internal_change_note(note_description)
        set_change_note_version
        redirect_to @step_by_step_page, notice: "'#{@step_by_step_page.title}' has been scheduled to publish."
      end
    else
      @schedule_placeholder = default_datetime_placeholder
      session[:update_type] = params[:update_type]
      session[:public_change_note] = params[:change_note]
    end
  end

  def unpublish
    set_current_page_as_step_by_step
    if request.post?
      redirect_url = params.delete("redirect_url")
      if StepByStepPage.validate_redirect(redirect_url)
        unpublish_page(redirect_url)
        redirect_to @step_by_step_page, notice: "Step by step page was successfully unpublished."
      else
        flash[:alert] = "Redirect path is invalid. Step by step page has not been unpublished."
      end
    end
  end

  def unschedule
    set_current_page_as_step_by_step
    @step_by_step_page.update(scheduled_at: nil)
    unschedule_publishing
    note_description = "Publishing was unscheduled by #{current_user.name}."
    generate_internal_change_note(note_description)
    set_change_note_version
    redirect_to @step_by_step_page, notice: "Publishing of '#{@step_by_step_page.title}' has been unscheduled."
  end

  def revert
    set_current_page_as_step_by_step
    if request.post?
      discard_draft
      revert_page
      redirect_to @step_by_step_page, notice: "Draft successfully discarded."
    else
      render :edit
    end
  end

  def check_links
    set_current_page_as_step_by_step
    @step_by_step_page.steps.each(&:request_broken_links)
    redirect_to @step_by_step_page, notice: "Links are currently being checked. Please refresh the page to check progress. When all links have been checked, you'll see a message below each step."
  end

  def internal_change_notes
    set_current_page_as_step_by_step
    @internal_change_note = InternalChangeNote.new
  end

  helper_method :issues_for
  def issues_for(namespace)
    return if @parser.nil?

    @parser.issues_for(namespace).map { |error| { text: error } }
  end

private

  def discard_draft
    @step_by_step_page.discard_notes
    StepNavPublisher.discard_draft(@step_by_step_page)
  rescue GdsApi::HTTPNotFound
    Rails.logger.info "Discarding #{@step_by_step_page.content_id} failed"
  end

  def update_downstream
    StepByStepDraftUpdateWorker.perform_async(@step_by_step_page.id, current_user.name)
  end

  def publish_intent_params
    @step_by_step_page.has_been_published? ? params : { update_type: "minor" }
  end

  def publish_page(publish_intent)
    StepNavPublisher.update(@step_by_step_page, publish_intent)
    StepNavPublisher.publish(@step_by_step_page)
    @step_by_step_page.mark_as_published
  end

  def schedule_to_publish(update_type, change_note)
    publish_intent = PublishIntent.new(update_type: update_type, change_note: change_note)
    StepNavPublisher.schedule_for_publishing(@step_by_step_page)
    StepNavPublisher.update(@step_by_step_page, publish_intent)
    @step_by_step_page.mark_as_scheduled
  end

  def unpublish_page(redirect_url)
    begin
      StepNavPublisher.unpublish(@step_by_step_page, redirect_url)
    rescue GdsApi::HTTPNotFound
      Rails.logger.info "Unpublishing #{@step_by_step_page.content_id} failed"
    end
    @step_by_step_page.mark_as_unpublished
  end

  def unschedule_publishing
    StepNavPublisher.cancel_scheduling(@step_by_step_page)
    @step_by_step_page.mark_as_unscheduled
  end

  def revert_page
    published_version = latest_edition_number(@step_by_step_page.content_id, publication_state: "published")
    payload = Services.publishing_api.get_content(@step_by_step_page.content_id, version: published_version).to_hash

    StepByStepPageReverter.new(@step_by_step_page, payload).repopulate_from_publishing_api
  end

  def publish_note_description
    return "First published by #{current_user.name}" unless @step_by_step_page.has_been_published?

    custom_note = " with change note: #{@publish_intent.change_note}" unless @publish_intent.change_note.empty?
    "Published by #{current_user.name}#{custom_note}"
  end

  def generate_internal_change_note(note_description)
    change_note = @step_by_step_page.internal_change_notes.new(
      author: current_user.name,
      description: note_description,
    )
    change_note.save!
  end

  def set_change_note_version
    change_notes = @step_by_step_page.internal_change_notes.where(edition_number: nil)
    change_notes.update_all(edition_number: latest_edition_number(@step_by_step_page.content_id))
  end

  def set_step_by_step_page
    @step_by_step_page = StepByStepPage.find(params[:id])
  end

  def step_by_step_page_params
    params.require(:step_by_step_page).permit(:title, :slug, :introduction, :description)
  end

  def filter_params
    params.permit(:title_or_url, :status, :order_by)
  end

  def set_current_page_as_step_by_step
    @step_by_step_page = StepByStepPage.find(params[:step_by_step_page_id])
  end

  def require_to_be_2i_approved
    set_current_page_as_step_by_step
    unless @step_by_step_page.approved_2i?
      redirect_to @step_by_step_page, notice: "Step by step must be 2i approved before you can perform this action."
    end
  end
end
