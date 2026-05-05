class CreateTagTool < ApplicationTool
  VALID_COLORS = Tag::COLORS.freeze

  description "Create a new tag for the family. Tags are user-defined labels applied to transactions in addition to a category — common examples: 'Vacation', 'Reimbursable', 'Tax-Deductible', 'Side Project'. " \
              "IMPORTANT: Always confirm the tag name with the user before creating. Use get_tags first to avoid duplicates (tag names must be unique within a family). " \
              "After creating, the returned id can be passed to create_transaction or update_transaction via the tag_ids parameter."

  input_schema(
    properties: {
      name:  { type: "string", description: "Tag name e.g. 'Vacation'. Must be unique within the family." },
      color: { type: "string", description: "Hex color code. Suggested presets: #{VALID_COLORS.join(', ')}. Defaults to a random preset if omitted." }
    },
    required: %w[name]
  )

  class << self
    def call(server_context:, name:, color: nil, **_params)
      require_write_access!(server_context)
      family = current_family(server_context)

      color ||= VALID_COLORS.sample

      tag = family.tags.create!(name: name, color: color)

      text_response({
        success: true,
        id: tag.id,
        name: tag.name,
        color: tag.color
      })
    rescue ActiveRecord::RecordInvalid => e
      text_response({ success: false, errors: e.record.errors.full_messages })
    end
  end
end
