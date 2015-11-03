require 'link_checker/csv_rows_generator'

require 'csv'
require 'pathname'

module LinkChecker

class CsvExporter
  def initialize(link_reports, basename_path, options = {})
    @link_reports = link_reports
    @basename_path = Pathname(basename_path)

    @rows_generator = CsvRowsGenerator.new(options)
    @files_count = 0
  end

  def call
    open_csv

    rows_written = 0

    @link_reports.each do |link_report|
      rows = @rows_generator.report_rows(link_report)

      if rows_written + rows.length > 1_000_000 # sheets have a max rows count which is roughly more than that
        @csv.close
        open_csv
        rows_written = 0
      end

      rows.each do |row|
        @csv << row
      end
      rows_written += rows.length
    end
  end

  private

  def open_csv
    @files_count += 1

    file_number_segment =
      if @files_count == 1
        ''
      else
        @files_count
      end

    path = @basename_path.dirname
      .join("#{@basename_path.basename}#{file_number_segment}.csv")

    @csv = CSV.open(path, 'w')
    @csv << @rows_generator.header_row
  end
end

end
