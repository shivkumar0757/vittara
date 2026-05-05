class UpdateTransactionTool < ApplicationTool
  description "Update an existing transaction. Only updates fields you provide. Scoped to current user's family. " \
              "tag_ids REPLACES the full set of tags (it's not append). Pass [] to remove all tags. Use get_tags to look up UUIDs — do NOT pass tag names."

  input_schema(
    properties: {
      entry_id: { type: "string", description: "Entry ID (UUID) to update" },
      name: { type: "string", description: "New transaction name" },
      date: { type: "string", description: "New date in YYYY-MM-DD format" },
      category_id: { type: "string", description: "New category ID (UUID)" },
      tag_ids: { type: "array", items: { type: "string" }, description: "Replaces all tags on this transaction. Pass [] to remove all. Tag UUIDs only — use get_tags to look up." },
      notes: { type: "string", description: "Notes or memo" }
    },
    required: %w[entry_id]
  )

  class << self
    def call(server_context:, entry_id:, name: nil, date: nil, category_id: nil, tag_ids: nil, notes: nil, **_params)
      require_write_access!(server_context)
      family = current_family(server_context)
      entry = family.entries.find(entry_id)

      entryable_attrs = { id: entry.entryable_id, category_id: category_id }.compact_blank
      entryable_attrs[:tag_ids] = tag_ids unless tag_ids.nil?

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
