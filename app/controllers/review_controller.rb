class ReviewController < ApplicationController
  layout 'admin_layout'

  before_action :require_gds_editor_permissions!
  before_action :require_unreleased_feature_permissions!
  before_action :require_2i_reviewer_permissions!, only: %i(approve_2i_review claim_2i_review)
  before_action :set_step_by_step_page

  def approve_2i_review
    status = "2i_approved"

    if @step_by_step_page.update(
      review_requester_id: nil,
      reviewer_id: nil,
      status: status
    )
      generate_change_note(status)

      redirect_to step_by_step_page_path(@step_by_step_page.id), notice: "Step by step page was successfully 2i_approved."
    end
  end

  def claim_2i_review
    status = "in_review"

    if @step_by_step_page.update(
      reviewer_id: current_user.uid,
      status: status
    )
      generate_change_note(status)

      redirect_to step_by_step_page_path(@step_by_step_page.id), notice: "Step by step page was successfully claimed for review."
    end
  end

  def submit_for_2i
    if request.post?
      status = "submitted_for_2i"

      if @step_by_step_page.update(
        review_requester_id: current_user.uid,
        status: status
      )
        generate_change_note(status, params[:additional_comments])

        redirect_to step_by_step_page_path(@step_by_step_page.id), notice: "Step by step page was successfully #{status.humanize.downcase}."
      else
        render :submit_for_2i
      end
    end
  end

private

  def generate_change_note(status, change_note = nil)
    description = "#{status.humanize} by #{current_user.name}"
    description << "\n\n#{change_note}" if change_note.present?

    @step_by_step_page.internal_change_notes.create(
      author: current_user.name,
      description: description
    )
  end

  def set_step_by_step_page
    @step_by_step_page = StepByStepPage.find(params[:step_by_step_page_id])
  end
end
