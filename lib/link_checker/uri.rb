require 'uri'
require 'pathname'

module LinkChecker

class Uri
  class VirtualRoot
    def to_s
      raise ArgumentError
    end

    def virtual_root?
      true
    end

    def valid?
      false
    end

    def user
      nil
    end

    def password
      nil
    end

    def same_host_and_scheme?(*)
      raise ArgumentError
    end

    def normalize
      self
    end

    def to_absolute(*)
      raise ArgumentError
    end

    def stdlib_uri
      raise ArgumentError
    end
  end

  def initialize(str)
    @str = str
  end

  def virtual_root?
    false
  end

  def to_s
    @str
  end

  def valid?
    !!stdlib_uri
  end

  def user
    stdlib_uri.user if valid?
  end

  def password
    stdlib_uri.password if valid?
  end

  def same_host_and_scheme?(uri)
    raise ArgumentError unless valid?
    raise ArgumentError unless uri.valid?
    stdlib_uri.scheme == uri.stdlib_uri.scheme &&
      stdlib_uri.host == uri.stdlib_uri.host
  end

  def normalize
    if stdlib_uri = stdlib_uri()
      if stdlib_uri.query
        stdlib_uri = stdlib_uri.clone
        stdlib_uri.query = nil
        self.class.new(stdlib_uri.to_s)
      else
        self
      end
    else
      self
    end
  end

  def to_absolute(from_uri)
    return self unless valid?
    return self if absolute?

    raise ArgumentError unless from_uri.valid?
    raise ArgumentError unless from_uri.absolute?

    new_uri = from_uri.stdlib_uri.clone
    path = Pathname(new_uri.path)
    new_uri.path = path.join(Pathname(stdlib_uri.path)).to_s
    self.class.new(new_uri.to_s)
  end

  def absolute?
    raise ArgumentError unless valid?

    if stdlib_uri.absolute?
      binding.pry if stdlib_uri.path && !stdlib_uri.path.start_with?('/')
    end

    # since stdlib uris have all been normalized, their path
    # is either nil (in which case it is probably a URI::Generic which we cannot handle)
    # or starts with "/". Hence, is suffices to check for presence of a scheme
    stdlib_uri.absolute?
  end

  def stdlib_uri
    return @stdlib_uri if defined?(@stdlib_uri)

    @stdlib_uri = URI(@str).normalize rescue nil
  end
end

end
