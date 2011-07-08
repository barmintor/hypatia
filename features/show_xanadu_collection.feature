Feature: Xanadu Collection Object Show View 
  I want to ensure Xanadu Collection objects display correctly in the show view

  Scenario: Xanadu collection object descMetadata - collection related
    When I am on the document page for id "hypatia:fixture_xanadu_collection"
    Then I should see "Keith Henson. Papers relating to Project Xanadu, XOC and Eric Drexler"
    And I should see "Videorecordings"
    And I should see "1977-1997"
    And I should see "6.0 Linear feet"
    And I should see "The collection includes files from XOC, VHS tapes, and Drexler drafts and galley proofs."
    And I should see "Keith Henson's Papers relating to Project Xanadu, XOC, and Eric Drexler. M1292. Dept. of Special Collections, Stanford University Libraries, Stanford, Calif."
    And I should see "Electronic publishing."
    And I should see "Word processing."
    And I should see "M1292"

  Scenario: Xanadu collection object descMetadata - repository related
    When I am on the document page for id "hypatia:fixture_xanadu_collection"
    Then I should see "Repository"
    And I should see "Stanford University. Department of Special Collections and University Archives"
    And I should see "Publication Rights"
    And I should see "Property rights reside with the repository."
    And I should see "Access Notes"
    And I should see "The Media materials require at least two weeks advance notice"

  Scenario: Xanadu collection object descMetadata - creator related
    When I am on the document page for id "hypatia:fixture_xanadu_collection"
    Then I should see "Creator"
    And I should see "Henson, Keith"
    And I should see "Biography"
    And I should see "Keith Henson and his wife Arel Lucas founded XOC (Xanadu Operating Company)."


  Scenario: Xanadu collection object technical information (from Fedora, not EAD)
    When I am on the document page for id "hypatia:fixture_xanadu_collection" 
    # repository object ID
    Then I should see "hypatia:fixture_xanadu_collection"
    # identityMetadata
    And I should see "DOR"
    And I should see "collection"
    And I should see "set"
    And I should see "druid:gb021jg8190"
    And I should see "Label"
    And I should see "Xanadu papers"
    And I should see "Hypatia ID"
    And I should see "M1292"
    And I should see "UUID"
    And I should see "a78e70c8-bb8b-f4e9-63ba-226f60a17c58"
    And I should see "Admin Policy"
    And I should see "druid:hv992ry2431"
    And I should see "Project : Xanadu"


  Scenario: Xanadu collection object contained items
    When I am on the document page for id "hypatia:fixture_xanadu_collection" 
    Then outcome
