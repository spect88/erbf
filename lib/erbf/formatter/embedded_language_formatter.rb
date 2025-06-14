# frozen_string_literal: true

require "open3"

class Erbf::Formatter::EmbeddedLanguageFormatter
  def initialize(config)
    @config = config
  end

  def supported?(type)
    !find(type).nil?
  end

  def format(type, content, line_length)
    formatter = find(type)
    return content.chomp if formatter.nil?

    command = sprintf(formatter[:command], line_length: line_length)

    logger.debug(self.class.to_s) { "Formatting #{type}: #{command}" }
    stdout, stderr, status = Open3.capture3({}, command, { stdin_data: content })

    if status.exitstatus != 0
      logger.error(self.class.to_s) { "[#{command}] exit status: #{status.exitstatus}" }
      logger.warn(self.class.to_s) { "[#{command}] stderr output:\n#{stderr}" } unless stderr.empty?
      logger.debug(self.class.to_s) { "[#{command}] input was:\n#{content}" }
    end

    status.exitstatus.zero? ? stdout.chomp : content.chomp
  end

  private

  def find(type)
    @config.embedded.find { |e| e[:types].include?(type) }
  end

  def logger
    @config.logger
  end
end
