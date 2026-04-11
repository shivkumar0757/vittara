class CreateCategoryTool < ApplicationTool
  VALID_COLORS = Category::COLORS.freeze
  VALID_ICONS  = Category.icon_codes.freeze

  description "Create a new spending or income category for the family. " \
              "Use get_categories to check existing categories first."

  input_schema(
    properties: {
      name: { type: "string", description: "Category name e.g. 'Groceries'" },
      classification: { type: "string", description: "'expense' (default) or 'income'" },
      color: { type: "string", description: "Hex color code. Suggested presets: #{VALID_COLORS.join(', ')}. Any valid hex color is accepted." },
      lucide_icon: { type: "string", description: "Icon name. Valid values: #{VALID_ICONS.join(', ')}" },
      parent_id: { type: "string", description: "UUID of a parent category — makes this a subcategory. Must share the same classification as the parent." }
    },
    required: %w[name]
  )

  class << self
    def call(server_context:, name:, classification: "expense", color: nil, lucide_icon: nil, parent_id: nil, **_params)
      require_write_access!(server_context)
      family = current_family(server_context)

      color       ||= VALID_COLORS.first
      lucide_icon ||= "shapes"

      category = family.categories.create!(
        name: name,
        classification: classification,
        color: color,
        lucide_icon: lucide_icon,
        parent_id: parent_id
      )

      text_response({
        success: true,
        id: category.id,
        name: category.name,
        classification: category.classification,
        color: category.color,
        lucide_icon: category.lucide_icon,
        parent_id: category.parent_id
      })
    rescue ActiveRecord::RecordInvalid => e
      text_response({ success: false, errors: e.record.errors.full_messages })
    end
  end
end
