module LinkChecker

class Reference
  def self.root
    @root ||= new(nil, "root")
  end

  def self.a_href(uri)
    new(uri, "href")
  end

  def self.redirect(uri, http_status)
    new(uri, http_status.to_s)
  end

  attr_reader :uri, :info

  def group_key
    "#{uri} #{info}"
  end

  def root?
    info == "root"
  end

  private

  def initialize(uri, info)
    @uri = uri
    @info = info
  end
end

end

