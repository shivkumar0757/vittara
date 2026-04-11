module McpToolTestHelper
  # Call an MCP tool and unwrap the response to parsed data.
  # Tools return MCP::Tool::Response; this extracts the JSON text content
  # back to a Ruby Hash or Array so tests can assert business logic directly.
  def call_tool(tool_class, **args)
    response = tool_class.call(**args)
    ApplicationTool.unwrap(response)
  end
end
