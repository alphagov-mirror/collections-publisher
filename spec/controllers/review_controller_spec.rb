require 'rails_helper'

RSpec.describe ReviewController do
  describe "#submit_for_2i" do
    let(:step_by_step_page) { create(:draft_step_by_step_page) }

    before do
      allow(Services.publishing_api).to receive(:lookup_content_id)
    end

    describe "GET submit for 2i page" do
      it "can only be accessed by users with GDS editor and Unreleased feature permissions" do
        stub_user.permissions = ["signin", "GDS Editor", "Unreleased feature"]
        get :submit_for_2i, params: { step_by_step_page_id: step_by_step_page.id }

        expect(response.status).to eq(200)
      end

      it "cannot be accessed by users with only GDS editor permissions" do
        stub_user.permissions << "GDS Editor"
        get :submit_for_2i, params: { step_by_step_page_id: step_by_step_page.id }

        expect(response.status).to eq(403)
      end

      it "cannot be accessed by users with

       neither GDS editor and Unreleased feature permissions" do
        stub_user.permissions = %w(signin)
        get :submit_for_2i, params: { step_by_step_page_id: step_by_step_page.id }

        expect(response.status).to eq(403)
      end
    end

    describe "POST submit for 2i" do
      before do
        stub_user.permissions = ["signin", "GDS Editor", "Unreleased feature"]
        stub_user.name = "Firstname Lastname"
      end

      it "sets status to submit_for_2i" do
        post :submit_for_2i, params: { step_by_step_page_id: step_by_step_page.id }

        step_by_step_page.reload

        expect(step_by_step_page.status).to eq("submitted_for_2i")
        expect(step_by_step_page.review_requester).to eq(stub_user.uid)
      end

      describe "internal change notes" do
        it "creates an internal change note" do
          expected_change_note = "Submitted for 2i by Firstname Lastname"

          post :submit_for_2i, params: { step_by_step_page_id: step_by_step_page.id }
          step_by_step_page.reload

          expect(step_by_step_page.internal_change_notes.first.description).to eq expected_change_note
        end

        it "records the additional comments in the internal change note" do
          additional_comments = "additional comments for reviewer"

          post :submit_for_2i, params: {
            step_by_step_page_id: step_by_step_page.id,
            additional_comments: additional_comments
          }

          expect(step_by_step_page.internal_change_notes.first.description).to include(additional_comments)
        end
      end
    end
  end
end
