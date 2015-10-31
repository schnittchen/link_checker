require 'link_checker/control'
require 'link_checker/pool_queue'
require 'link_checker/link_report'
require 'link_checker/fetcher'
require 'link_checker/page'
require 'link_checker/uri'

module LinkChecker

class Instance
  def initialize
    @control = Control.new

    @roots = []

    @mtx = Mutex.new
    @link_reports = {} # keyed by URI

    @pool_queue = PoolQueue.new(10)
    @fetcher = Fetcher.new(@control)
  end
  attr_reader :roots, :link_reports

  def run
    virtual_root = Uri::VirtualRoot.new

    spawn_reporter_thread

    @roots.each do |root|
      root = Uri.new(root).to_absolute(virtual_root)
      handle_uri(root, virtual_root)
    end

    @pool_queue.wait_until_finished
  end

  private

  StatusReport = Struct.new(:links_count, :linkages_count, :failures_count, :skips_count, :runtime_seconds)

  def spawn_reporter_thread
    Thread.new do
      start_time = Time.now

      loop do
        sleep 10
        status_report =
          @mtx.synchronize do
            crawled_reports = @link_reports.values.reject(&:pending?)
            links_count = crawled_reports.count
            linkages_count = crawled_reports.map { |lr| lr.references.count }.reduce(0, :+)
            failures_count = crawled_reports.reject(&:status_success?).count
            skips_count = crawled_reports.count(&:skip?)
            runtime_seconds = (Time.now - start_time).round

            StatusReport.new(links_count, linkages_count, failures_count, skips_count, runtime_seconds)
          end

        @control.log_status status_report
      end
    end
  end

  # both args are absolute (except from_uri, which may be virtual root)
  def handle_uri(uri, from_uri)
    uri = uri.normalize

    new_report = nil

    @mtx.synchronize do
      unless report = @link_reports[uri.to_s]
        report = @link_reports[uri.to_s] =
          LinkReport.new(uri, skip_uri?(uri, from_uri))
        new_report = report
      end

      report.references << from_uri
    end

    if new_report
      if new_report.skip?
        @control.log_skip(new_report)
      else
        @pool_queue.push_job do
          crawl_uri(uri, new_report)
        end
      end
    end
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
    else
      @control.log_failed_report(report)
    end
  end
end

end
