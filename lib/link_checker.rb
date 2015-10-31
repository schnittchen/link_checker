require 'link_checker/instance'

module LinkChecker
  def self.new(*args)
    Instance.new(*args)
  end
end
