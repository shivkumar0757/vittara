class UpdateTransactionTool < ApplicationTool
  description "Update an existing transaction. Only updates fields you provide. Scoped to current user's family. " \
              "tags REPLACES the full set (not append). Pass [] to remove all tags. Tags are referenced by NAME (case-insensitive). Errors with the list of available tags if any name doesn't exist; call create_tag first to add new ones."

  input_schema(
    properties: {
      entry_id: { type: "string", description: "Entry ID (UUID) to update" },
      name: { type: "string", description: "New transaction name" },
      date: { type: "string", description: "New date in YYYY-MM-DD format" },
      category_id: { type: "string", description: "New category ID (UUID)" },
      tags: { type: "array", items: { type: "string" }, description: "Replaces all tags. Pass [] to remove all. Tag NAMES (case-insensitive) — must already exist." },
      notes: { type: "string", description: "Notes or memo" }
    },
    required: %w[entry_id]
  )

  class << self
    def call(server_context:, entry_id:, name: nil, date: nil, category_id: nil, tags: nil, notes: nil, **_params)
      require_write_access!(server_context)
      family = current_family(server_context)
      entry = family.entries.find(entry_id)

      entryable_attrs = { id: entry.entryable_id, category_id: category_id }.compact_blank
      unless tags.nil?
        entryable_attrs[:tag_ids] = resolve_tag_ids!(family, tags)
      end

      update_params = {
        name: name,
        date: date ? Date.parse(date) : nil,
        notes: notes,
        entryable_attributes: entryable_attrs.size > 1 ? entryable_attrs : nil
      }.compact

      if entry.update(update_params)
        entry.sync_account_later
        text_response({ success: true, id: entry.id, name: entry.name, date: entry.date.iso8601 })
      else
        text_response({ success: false, errors: entry.errors.full_messages })
      end
    end
  end
end
