require 'link_checker/pool_queue'
require 'link_checker/link_report'
require 'link_checker/fetcher'
require 'link_checker/page'
require 'link_checker/uri'

module LinkChecker

class Instance
  def initialize
    @roots = []

    @mtx = Mutex.new
    @link_reports = {} # keyed by URI

    @pool_queue = PoolQueue.new(10)
    @fetcher = Fetcher.new
  end
  attr_reader :roots, :link_reports

  def run
    virtual_root = Uri::VirtualRoot.new

    @roots.each do |root|
      root = Uri.new(root).to_absolute(virtual_root)
      handle_uri(root, virtual_root)
    end

    @pool_queue.wait_until_finished
  end

  private

  # both args are absolute (except from_uri, which may be virtual root)
  def handle_uri(uri, from_uri)
    uri = uri.normalize
    return if skip_uri?(uri, from_uri)

    report =
      @mtx.synchronize do
        report =
          @link_reports[uri.to_s] ||=
            LinkReport.new(uri, skip_uri?(uri, from_uri))

        report.references << from_uri
        report
      end

    @pool_queue.push_job do
      crawl_uri(uri, report)
    end unless report.skip?
  end

  def skip_uri?(uri, from_uri)
    return false if from_uri.virtual_root?
    return false if !uri.valid?

    !uri.same_host_and_scheme?(from_uri)
  end

  def crawl_uri(uri, report)
    response = @fetcher.call(uri)
    report.status = response.status
    report.error_message = response.error_message

    if report.status_success?
      page = Page.new(uri, response.body)
      page.uris.each do |new_uri|
        handle_uri(new_uri, uri)
      end
    end
  end
end

end
