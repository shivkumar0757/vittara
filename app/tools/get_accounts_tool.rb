class GetAccountsTool < ApplicationTool
  description "List all visible accounts with name, type, subtype, balance, currency, classification (asset/liability)"
  arguments { }

  def call
    current_family.accounts.visible.alphabetically.map do |account|
      {
        id: account.id,
        name: account.name,
        type: account.accountable_type,
        subtype: account.accountable.try(:account_type),
        balance: account.balance,
        currency: account.currency,
        classification: account.classification
      }
    end
  end
end
