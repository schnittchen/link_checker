require 'thread'
require 'logger'

module LinkChecker

class Control
  def initialize
    @mtx = Mutex.new
    @logger = Logger.new($stdout)
  end

  def set_logger(logger)
    @logger = logger
  end

  def log_retry(try_num, uri)
    @mtx.synchronize do
      @logger.warn "Try ##{try_num} for #{inspect_uri(uri)}"
    end
  end

  def log_retry_exceeded(uri)
    @mtx.synchronize do
      @logger.error "Retry count exceeded, giving up on #{inspect_uri(uri)}"
    end
  end

  def log_fetch_exception_message(message)
    @mtx.synchronize do
      @logger.error message
    end
  end

  def log_failed_report(link_report)
    @mtx.synchronize do
      details = [
        ("HTTP status #{link_report.status}" if link_report.status),
        link_report.error_message
      ].compact
      @logger.error "#{details.join(' ')} for #{inspect_uri(link_report.uri)}"
    end
  end

  def log_skip(link_report)
    @mtx.synchronize do
      @logger.info "Skipping #{link_report.uri}"
    end
  end

  def log_status(status_report)
    message = [
      "#{status_report.links_count} links",
      "#{status_report.linkages_count} linkages",
      "#{status_report.failures_count} failures",
      "#{status_report.skips_count} skipped"
    ].join(', ') + ". Running #{status_report.runtime_seconds}s"
    @logger.info message
  end

  private

  def inspect_uri(uri)
    uri.to_s.inspect
  end
end

end
