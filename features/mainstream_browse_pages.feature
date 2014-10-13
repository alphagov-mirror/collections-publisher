Feature: Mainstream browse pages

  @mock-panopticon
  Scenario: Creating a page
    When I fill out the details for a new mainstream browse page
    Then the page should be created
    And the page should have been created in Panopticon

  @mock-panopticon
  Scenario: Updating a page
    Given a mainstream browse page exists
    When I make a change to the mainstream browse page
    Then the page should be updated
    And the page should have been updated in Panopticon
