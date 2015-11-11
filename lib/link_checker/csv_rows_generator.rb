module LinkChecker

class CsvRowsGenerator
  def initialize(options = {})
    @options = options
    @rows_count = 0
  end

  def header_row
    if with_references?
      ["URI", "status", "HTTP status", "error message", "ref URI", "ref info", "ref count"]
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
      elsif link_report.status_redirect?
        'followed'
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
        .group_by(&:group_key)
        .map { |_, references| [references.first, references.count] }
        .to_h
        .map do |reference, count|
          [*report_row, reference.uri.to_s, reference.info, count]
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
