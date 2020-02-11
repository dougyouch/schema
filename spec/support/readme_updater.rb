# frozen_string_literal: true

# Updates README.md
class ReadmeUpdater
  def initialize(readme_file = 'README.md')
    @readme_file = readme_file
  end

  def update_code_snippet(file, language)
    content = File.read(@readme_file)
    section_start = "###### #{file}\n```#{language}\n"
    section_end = "```\n"

    regex = Regexp.new(Regexp.escape(section_start) + '.*?' + Regexp.escape(section_end), Regexp::MULTILINE)
    content.sub!(regex, section_start + File.read(file) + section_end)
    File.open(@readme_file, 'wb') { |f| f.write content }
  end
end
