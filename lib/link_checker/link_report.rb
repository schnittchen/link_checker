module LinkChecker

class LinkReport
  def initialize(uri, skip)
    @uri = uri
    @references = []
    @status = nil
    @skip = skip
  end

  attr_reader :uri, :references
  attr_accessor :status
  attr_accessor :error_message

  def status_success?
    status == 200
  end

  def status_redirect?
    [301, 302, 303, 307].include?(status)
  end

  def failed?
    crawled? && !(status_success? || status_redirect?)
  end

  def pending?
    !skip? && !crawled?
  end

  def skip?
    @skip
  end

  def crawled?
    !!(status || error_message)
  end
end

end
