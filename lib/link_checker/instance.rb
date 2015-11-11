require 'link_checker/control'
require 'link_checker/pool_queue'
require 'link_checker/link_report'
require 'link_checker/fetcher'
require 'link_checker/page'
require 'link_checker/uri'
require 'link_checker/reference'
require 'link_checker/csv_exporter'

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

  def authenticate(username, password)
    @control.authentication = Control::Authentication.new(username, password)
  end

  def run
    virtual_root = Reference.root

    start_time = Time.now
    spawn_reporter_thread start_time

    @roots.each do |root|
      uri = Uri.new(root)
      if uri.absolute?
        handle_uri(uri, virtual_root, 0)
      else
        @mtx.synchronize do
          unless @link_reports.key?(uri.to_s)
            report = LinkReport.new(uri, false)
            report.error_message = "invalid root (must be absolute)"
            report.references << virtual_root
            @link_reports[uri.to_s] = report
          end
        end
      end
    end

    @pool_queue.wait_until_finished
    @control.log_finished build_status_report(start_time)

    exporter = CsvExporter.new(@link_reports.values, 'link_checker_export', with_references: true)
    exporter.call
  end

  def logger
    @control.logger
  end

  def set_logger(logger)
    @control.set_logger logger
  end

  private

  StatusReport = Struct.new(:links_count, :linkages_count, :failures_count, :skips_count, :queue_length, :runtime_seconds)

  def spawn_reporter_thread(start_time)
    Thread.new do
      loop do
        sleep 10
        @control.log_status build_status_report(start_time)
      end
    end
  end

  def build_status_report(start_time)
    @mtx.synchronize do
      reports = @link_reports.values

      links_count = reports.count
      linkages_count = reports.map { |lr| lr.references.count }.reduce(0, :+)
      failures_count = reports.count(&:failed?)
      skips_count = reports.count(&:skip?)
      queue_length = @pool_queue.length
      runtime_seconds = (Time.now - start_time).round

      StatusReport.new(links_count, linkages_count, failures_count, skips_count, queue_length, runtime_seconds)
    end
  end

  # both args are absolute (except from_uri, which may be virtual root)
  def handle_uri(uri, reference, redirect_count)
    uri = uri.normalize

    new_report = nil

    @mtx.synchronize do
      unless report = @link_reports[uri.to_s]
        report = @link_reports[uri.to_s] =
          LinkReport.new(uri, skip_uri?(uri, reference))
        new_report = report
      end

      report.references << reference
    end

    if new_report
      if new_report.skip?
        @control.log_skip(new_report)
      elsif redirect_count > 2 # TODO hard-coded
        new_report.error_message = "redirect limit exceeded"
      else
        @pool_queue.push_job do
          crawl_uri(uri, new_report, redirect_count)
        end
      end
    end
  end

  def skip_uri?(uri, reference)
    return false if reference.root?
    return false if !uri.valid?

    !uri.same_host_and_scheme?(reference.uri)
  end

  def crawl_uri(uri, report, redirect_count)
    response = @fetcher.call(uri)
    report.status = response.status
    report.error_message = response.error_message

    if report.status_success?
      page = Page.new(uri, response.body)
      page.uris.each do |new_uri|
        reference = Reference.a_href(uri)
        handle_uri(new_uri, reference, 0)
      end
    elsif report.status_redirect?
      new_uri = uri.merge(response.location_header)
      reference = Reference.redirect(uri, response.status)
      handle_uri(new_uri, reference, redirect_count + 1)
    else
      @control.log_failed_report(report)
    end
  end
end

end
