require 'nokogiri'

module LinkChecker

class Page
  def initialize(uri, html)
    @uri = uri
    @noko = Nokogiri::HTML(html)
  end

  def uris
    [
      # TODO there's more to referencing than hrefs
      *a_hrefs
    ].map { |str|
      Uri.new(str).to_absolute(@uri)
    }
  end

  private

  def a_hrefs
    @noko.css('a[href]').map { |a| a.attr('href') }
  end
end

end
