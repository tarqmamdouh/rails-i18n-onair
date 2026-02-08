module RailsI18nOnair
  module ApplicationHelper
    def storage_mode_badge
      if RailsI18nOnair.configuration.database_mode?
        content_tag(:span, "Database", class: "badge bg-success")
      else
        content_tag(:span, "File", class: "badge bg-info")
      end
    end

    def translation_key_count(translation)
      return 0 unless translation.translation.is_a?(Hash)

      count_keys(translation.translation)
    end

    def format_locale_filename(filename)
      File.basename(filename, ".yml").upcase
    end

    def render_yaml_tree(hash, level = 0)
      return "" unless hash.is_a?(Hash)

      output = ""

      hash.each do |key, value|
        indent = "&nbsp;" * (level * 4)

        if value.is_a?(Hash)
          output << content_tag(:tr) do
            content_tag(:td, raw("#{indent}<strong>#{key}:</strong>"), colspan: 2, class: "bg-light")
          end
          output << render_yaml_tree(value, level + 1)
        else
          output << content_tag(:tr) do
            content_tag(:td, raw("#{indent}#{key}")) +
            content_tag(:td, value.to_s)
          end
        end
      end

      raw(output)
    end

    def syntax_highlight_yaml(content)
      # Basic syntax highlighting for YAML in HTML
      # This is a simple implementation; for production, consider using a proper syntax highlighter
      content
        .gsub(/^(\s*)([a-z_]+):/, '<span style="color: #61afef;">\1\2:</span>')
        .gsub(/"([^"]*)"/, '<span style="color: #98c379;">"\1"</span>')
        .gsub(/'([^']*)'/, '<span style="color: #98c379;">\'\1\'</span>')
    end

    def mode_icon
      if RailsI18nOnair.configuration.database_mode?
        content_tag(:i, "", class: "bi bi-database-fill text-success")
      else
        content_tag(:i, "", class: "bi bi-folder-fill text-info")
      end
    end

    def active_nav_class(path)
      current_page?(path) ? "active" : ""
    end

    def format_file_size(size)
      number_to_human_size(size)
    end

    def translation_count_badge(count)
      badge_class = if count.zero?
        "bg-secondary"
      elsif count < 10
        "bg-warning"
      else
        "bg-success"
      end

      content_tag(:span, pluralize(count, "translation"), class: "badge #{badge_class}")
    end

    private

    def count_keys(hash, total = 0)
      hash.each do |_key, value|
        if value.is_a?(Hash)
          total = count_keys(value, total)
        else
          total += 1
        end
      end
      total
    end
  end
end
