class CreateCategoryTool < ApplicationTool
  VALID_COLORS = Category::COLORS.freeze
  VALID_ICONS  = Category.icon_codes.freeze

  description "Create a new spending or income category for the family. " \
              "Use get_categories to check existing categories first."

  arguments do
    required(:name).filled(:string).description("Category name e.g. 'Groceries'")
    optional(:classification).filled(:string).description("'expense' (default) or 'income'")
    optional(:color).filled(:string).description("Hex color. Valid values: #{VALID_COLORS.join(', ')}")
    optional(:lucide_icon).filled(:string).description("Icon name. Valid values: #{VALID_ICONS.join(', ')}")
    optional(:parent_id).filled(:string).description("UUID of a parent category — makes this a subcategory. Must share the same classification as the parent.")
  end

  def call(name:, classification: "expense", color: nil, lucide_icon: nil, parent_id: nil)
    require_write_access!

    color       ||= VALID_COLORS.first
    lucide_icon ||= "shapes"

    category = current_family.categories.create!(
      name: name,
      classification: classification,
      color: color,
      lucide_icon: lucide_icon,
      parent_id: parent_id
    )

    {
      success: true,
      id: category.id,
      name: category.name,
      classification: category.classification,
      color: category.color,
      lucide_icon: category.lucide_icon,
      parent_id: category.parent_id
    }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end
end
