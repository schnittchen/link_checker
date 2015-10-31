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
      @logger.warn "Try ##{try_num} for #{uri}"
    end
  end

  def log_retry_exceeded(uri)
    @mtx.synchronize do
      @logger.error "Retry count exceeded, giving up on #{uri}"
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
      @logger.error "#{details.join(' ')} for #{link_report.uri}"
    end
  end
end

end
