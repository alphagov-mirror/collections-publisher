require "rails_helper"

RSpec.feature "Tagging browse pages with topics" do
  include CommonFeatureSteps

  before do
    given_I_am_a_GDS_editor
    stub_all_panopticon_tag_calls
    stub_any_publishing_api_call
    publishing_api_has_no_linked_items
  end

  scenario "User visits parent browse page" do
    given_there_is_a_parent_browse_page
    when_I_visit_that_browse_page
    then_there_is_no_way_to_tag_the_page
  end

  scenario "Tagging a browse page" do
    given_there_is_a_browse_page
    and_there_are_topics_to_tag_to
    when_I_visit_that_browse_page
    and_I_add_a_new_tag_and_submit
    and_I_go_back_to_the_edit_page
    then_I_my_browse_page_is_selected
  end

  def given_there_is_a_parent_browse_page
    @page = create(:mainstream_browse_page)
  end

  def given_there_is_a_browse_page
    parent = create(:mainstream_browse_page)
    @page = create(:mainstream_browse_page, parent: parent)
  end

  def when_I_visit_that_browse_page
    visit edit_mainstream_browse_page_path(@page)
  end

  def and_there_are_topics_to_tag_to
    create(:topic, title: "Alpha")
    create(:topic, title: "Bravo")
  end

  def then_there_is_no_way_to_tag_the_page
    within "form" do
      expect(page).to_not have_selector("#mainstream_browse_page_topics")
    end
  end

  def and_I_add_a_new_tag_and_submit
    within "form" do
      select "Alpha", from: "mainstream_browse_page_topics"
      click_on "Save"
    end

    expect(page).to have_content("Alpha")
  end

  def and_I_go_back_to_the_edit_page
    click_link "Edit page"
  end

  def then_I_my_browse_page_is_selected
    expect(page).to have_select("mainstream_browse_page_topics",
      selected: ["Alpha"])
  end
end