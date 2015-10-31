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
    @str
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

  def to_absolute(from_uri) # from_uri may be nil if already absolute
    if from_uri
      from_uri = from_uri.stdlib_uri
      raise ArgumentError unless from_uri # given from_uri was invalid
      raise ArgumentError unless from_uri.absolute?
    end

    if stdlib_uri = stdlib_uri()
      if stdlib_uri.absolute? # has scheme
        self # already absolute
      else
        raise ArgumentError unless from_uri

        new_uri = from_uri.clone
        path = Pathname(from_uri.path)
        new_uri.path = path.join(Pathname(stdlib_uri.path)).to_s
        self.class.new(new_uri.to_s)
      end
    else
      self # equally invalid
    end
  end

  def stdlib_uri
    return @stdlib_uri if defined?(@stdlib_uri)

    @stdlib_uri = URI(@str) rescue nil
  end
end

end
