require "fast_mcp"

FastMcp.mount_in_rails(
  Rails.application,
  name: "vittara",
  version: "1.0.0",
  path_prefix: "/mcp"
) do |server|
  Rails.application.config.after_initialize do
    server.register_tools(
      # Phase 1B — Read Tools (registered as they are built)
      # GetFinancialOverviewTool,
      # GetAccountsTool,
      # GetNetWorthTool,
      # GetTransactionsTool,
      # GetCategoriesTool,
    )
  end
end
