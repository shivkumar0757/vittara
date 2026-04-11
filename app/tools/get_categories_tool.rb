class GetCategoriesTool < ApplicationTool
  description "List all spending/income categories for the family"
  input_schema(properties: {})

  class << self
    def call(server_context:, **_params)
      family = current_family(server_context)
      categories = family.categories.alphabetically.map do |cat|
        { id: cat.id, name: cat.name, classification: cat.classification, parent_id: cat.parent_id }
      end
      text_response(categories)
    end
  end
end
