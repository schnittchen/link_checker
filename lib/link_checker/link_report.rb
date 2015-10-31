module LinkChecker

class LinkReport
  def initialize(uri, skip)
    @uri = uri
    @references = []
    @status = nil
    @skip = skip
  end

  attr_reader :references
  attr_accessor :status
  attr_accessor :error_message

  def status_success?
    @status == 200
  end

  def skip?
    @skip
  end
end

end
