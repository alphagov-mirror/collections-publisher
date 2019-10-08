require "rails_helper"

RSpec.feature "Contextual action buttons for step by step pages" do
  include CommonFeatureSteps
  include NavigationSteps
  include StepNavSteps

  before do
    given_I_am_a_GDS_editor
    given_I_can_access_unreleased_features
    setup_publishing_api
  end

  context "Step by step is in draft" do
    scenario "show the relevant actions to the step by step author" do
      given_there_is_a_step_by_step_page_with_a_link_report
      when_I_visit_the_step_by_step_page
      then_the_primary_action_should_be "Submit for 2i review"
      and_the_secondary_action_should_be "Preview"
      and_there_should_be_tertiary_actions_to %w(Delete)
    end
  end

  context "Step by step has been submitted for 2i" do
    background do
      given_there_is_a_step_by_step_that_has_been_submitted_for_2i
    end

    scenario "show the relevant actions to the step by step author" do
      and_I_am_the_step_by_step_author
      when_I_visit_the_step_by_step_page
      then_there_should_be_no_primary_action
      and_the_secondary_action_should_be "Preview"
      and_there_should_be_tertiary_actions_to %w(Delete)
    end

    scenario "show the relevant actions to the step by step 2i reviewer" do
      and_I_am_the_reviewer
      when_I_visit_the_step_by_step_page
      then_the_primary_action_should_be "Claim for 2i review"
      and_the_secondary_action_should_be "Preview"
      and_there_should_be_tertiary_actions_to %w(Delete)
    end
  end

  context "Step by step has been claimed for 2i" do
    background do
      given_there_is_a_step_by_step_that_has_been_claimed_for_2i
    end

    scenario "show the relevant actions to the step by step author" do
      and_I_am_the_step_by_step_author
      when_I_visit_the_step_by_step_page
      then_there_should_be_no_primary_action
      and_the_secondary_action_should_be "Preview"
      and_there_should_be_tertiary_actions_to %w(Delete)
    end

    scenario "show the relevant actions to the step by step 2i reviewer" do
      and_I_am_the_reviewer
      when_I_visit_the_step_by_step_page
      then_the_primary_action_should_be "Approve"
      and_the_secondary_actions_should_be ["Request changes", "Preview"]
      and_there_should_be_tertiary_actions_to %w(Delete)
    end
  end

  context "Step by step has been 2i approved" do
    scenario "show the relevant actions to the step by step author" do
      given_there_is_a_step_by_step_that_has_been_2i_approved
      when_I_visit_the_step_by_step_page
      then_the_primary_action_should_be "Publish"
      and_the_secondary_action_should_be "Preview"
      and_there_should_be_tertiary_actions_to %w(Schedule Delete)
    end
  end

  context "Step by step has been scheduled" do
    scenario "show the relevant actions to the step by step author" do
      given_there_is_a_scheduled_step_by_step_page
      when_I_visit_the_step_by_step_page
      then_there_should_be_no_primary_action
      and_the_secondary_action_should_be "Preview"
      and_there_should_be_tertiary_actions_to %w(Unschedule)
    end
  end

  def then_the_primary_action_should_be(action_text)
    expect(page).to have_css(primary_action_selector, count: 1)
    expect(page).to have_css(primary_action_selector, text: action_text), "Couldn't find '#{action_text}' as a primary action in: \n #{action_html}"
  end

  def then_there_should_be_no_primary_action
    expect(page).not_to have_css(primary_action_selector)
  end

  def and_the_secondary_action_should_be(action_text)
    expect(page).to have_css(secondary_action_selector, count: 1)
    assert_secondary_action_exists(action_text)
  end

  def and_the_secondary_actions_should_be(actions)
    expect(page).to have_css(secondary_action_selector, count: actions.count)
    actions.each do |action_text|
      assert_secondary_action_exists(action_text)
    end
  end

  def assert_secondary_action_exists(action_text)
    expect(page).to have_css(secondary_action_selector, text: action_text), "Couldn't find '#{action_text}' as a secondary action in: \n #{action_html}"
  end

  def and_there_should_be_tertiary_actions_to(actions)
    expect(page).to have_css(tertiary_action_selector, count: actions.count)
    actions.each do |action_text|
      expect(page).to have_css(tertiary_action_selector, text: action_text), "Couldn't find '#{action_text}' as a tertiary action in: \n #{action_html}"
    end
  end

  def primary_action_selector
    ".app-side__actions .gem-c-button:not(.gem-c-button--secondary)"
  end

  def secondary_action_selector
    ".app-side__actions .gem-c-button--secondary"
  end

  def tertiary_action_selector
    ".app-side__actions .govuk-link"
  end

  def action_html
    find(".app-side__actions").native.inner_html.strip
  end
end
