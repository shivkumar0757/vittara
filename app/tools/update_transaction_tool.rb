class UpdateTransactionTool < ApplicationTool
  description "Update an existing transaction. Only updates fields you provide. Scoped to current user's family."

  arguments do
    required(:entry_id).filled(:string).description("Entry ID (UUID) to update")
    optional(:name).filled(:string).description("New transaction name")
    optional(:date).filled(:string).description("New date in YYYY-MM-DD format")
    optional(:category_id).filled(:string).description("New category ID (UUID)")
    optional(:notes).filled(:string).description("Notes or memo")
  end

  def call(entry_id:, name: nil, date: nil, category_id: nil, notes: nil)
    require_write_access!
    entry = current_family.entries.find(entry_id)

    update_params = {
      name: name,
      date: date ? Date.parse(date) : nil,
      notes: notes,
      entryable_attributes: { id: entry.entryable_id, category_id: category_id }.compact_blank
    }.compact

    if entry.update(update_params)
      entry.sync_account_later
      { success: true, id: entry.id, name: entry.name, date: entry.date.iso8601 }
    else
      { success: false, errors: entry.errors.full_messages }
    end
  end
end
