require 'faraday'

module LinkChecker

class Fetcher

  Response = Struct.new(:status, :body, :error_message, :location_header)

  def initialize(control)
    @control = control
  end

  def call(uri)
    return Response.new(nil, nil, "invalid URL") unless uri.valid?

    retry_with_backoff do |try_num|
      @control.log_retry(try_num, uri) if try_num > 1

      conn = Faraday.new(uri.to_s)
      if uri.user
        conn.basic_auth(uri.user, uri.password)
      end

      response = begin
        conn.get # connection problems occur as exceptions of the adapter
      rescue => e
        @control.log_fetch_exception_message(e.message)
        nil
      end

      if response
        return Response.new(response.status, response.body, nil, response['location'])
      end
    end

    @control.log_retry_exceeded(uri)
    Response.new(nil, nil, "retry count exceeded")
  end

  private

  def retry_with_backoff
    10.times do |i|
      yield i + 1
      sleep 2 ** i
    end
    false
  end

end

end
