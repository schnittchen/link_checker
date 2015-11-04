require 'uri'

module LinkChecker

class Uri
  class VirtualRoot
    def to_s
      "starting point"
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

    def merge(uri_string)
      Uri.new(uri_string)
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
      if stdlib_uri.query || stdlib_uri.fragment
        stdlib_uri = stdlib_uri.clone
        stdlib_uri.query = nil
        stdlib_uri.fragment = nil
        self.class.new(stdlib_uri.to_s)
      else
        self
      end
    else
      self
    end
  end

  def merge(uri_string)
    raise ArgumentError unless valid?

    # Garbage in, garbage out: if uri_string is not a valid URI, we cannot
    # merge. Best thing we can do is to return the other, invalid Uri
    mergee_uri = self.class.new(uri_string)
    return mergee_uri unless mergee_uri.valid?

    mergee_uri = mergee_uri.stdlib_uri
    mergee_fragment = mergee_uri.fragment
    mergee_uri.fragment = nil

    # see https://github.com/lostisland/faraday_middleware/blob/9a49b369c39cbef5525f4fda7e01cf8f5eb09e24/lib/faraday_middleware/response/follow_redirects.rb#L120,
    # where this is more than inspired from. Does not respect fragments, so they are channeled around this.
    uri_unsafe = /[^\-_.!~*'()a-zA-Z\d;\/?:@&=+$,\[\]%]/
    uri_string = mergee_uri.to_s.gsub(uri_unsafe) { |match|
      '%' + match.unpack('H2' * match.bytesize).join('%').upcase
    }

    mergee_uri = URI(uri_string)
    mergee_uri.fragment = mergee_fragment

    self.class.new(stdlib_uri.merge(mergee_uri.to_s).to_s)
  end

  def absolute?
    raise ArgumentError unless valid?

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
