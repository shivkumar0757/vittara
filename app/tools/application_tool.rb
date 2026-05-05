class ApplicationTool < MCP::Tool
  # Unwrap MCP::Tool::Response back to parsed data (for tests)
  def self.unwrap(response)
    JSON.parse(response.to_h[:content].first[:text], symbolize_names: true)
  end

  class << self
    private

      def current_family(server_context)
        family = server_context[:family]
        raise StandardError, "Unauthorized — invalid or missing MCP token" unless family
        family
      end

      def require_write_access!(server_context)
        unless server_context[:mcp_auth]&.write?
          raise StandardError, "Write access requires read_write scope"
        end
      end

      def text_response(data)
        MCP::Tool::Response.new([ { type: "text", text: data.to_json } ])
      end

      # Resolve tag names (case-insensitive) to UUIDs. Raises with a helpful
      # message if any name doesn't exist — does NOT auto-create.
      def resolve_tag_ids!(family, names)
        return nil if names.nil?
        return [] if names.empty?

        lookup = family.tags.index_by { |t| t.name.downcase }
        missing = names.reject { |n| lookup.key?(n.downcase) }
        if missing.any?
          available = family.tags.alphabetically.pluck(:name).join(", ")
          raise ArgumentError,
            "Tag(s) not found: #{missing.join(', ')}. Available: #{available.presence || '(none)'}. Use create_tag to add new tags."
        end
        names.map { |n| lookup[n.downcase].id }
      end
  end
end
