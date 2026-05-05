class GetTagsTool < ApplicationTool
  description "List all tags for the family. Tags are user-defined labels (e.g. 'Vacation', 'Reimbursable', 'Tax-Deductible') that can be applied to transactions in addition to a category. Returns id, name, color (hex). Use this to find existing tag UUIDs before passing them to create_transaction or update_transaction via the tag_ids parameter."

  input_schema(properties: {})

  class << self
    def call(server_context:, **_params)
      family = current_family(server_context)
      tags = family.tags.alphabetically.map do |tag|
        { id: tag.id, name: tag.name, color: tag.color }
      end
      text_response(tags)
    end
  end
end
