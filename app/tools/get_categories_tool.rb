class GetCategoriesTool < ApplicationTool
  description "List all spending/income categories for the family"
  arguments { }

  def call
    current_family.categories.alphabetically.map do |cat|
      { id: cat.id, name: cat.name, classification: cat.classification, parent_id: cat.parent_id }
    end
  end
end
