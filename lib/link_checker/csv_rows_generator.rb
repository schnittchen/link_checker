module LinkChecker

class CsvRowsGenerator
  def initialize(options = {})
    @options = options
    @rows_count = 0
  end

  def header_row
    if with_references?
      ["URI", "status", "HTTP status", "error message", "reference URI", "reference count"]
    else
      ["URI", "status", "HTTP status", "error message"]
    end
  end

  def report_rows(link_report)
    string_status =
      if link_report.failed?
        'failed'
      elsif link_report.skip?
        'skipped'
      else
        'ok'
      end

    report_row = [
      link_report.uri.to_s,
      string_status,
      link_report.status,
      link_report.error_message
    ]

    if with_references?
      link_report
        .references
        .map(&:to_s)
        .each_with_object({}) { |uri_str, hash|
          hash[uri_str] ||= 0
          hash[uri_str] += 1
        }.map do |uri_str, count|
          [*report_row, uri_str, count]
        end
    else
      report_row
    end
  end

  def with_references?
    !!@options[:with_references]
  end
end

end
