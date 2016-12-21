require 'pathname'

$: << Pathname(__FILE__).dirname.join('lib')

require 'link_checker'

checker = LinkChecker.new
checker.authenticate "staging", "google4friends"
checker.start_urls << "http://staging.ausbildung.de"
checker.logger.level = Logger::WARN

Thread.abort_on_exception = true


require 'pry'

checker.run

