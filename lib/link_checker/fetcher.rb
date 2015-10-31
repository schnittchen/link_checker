require 'faraday'

module LinkChecker

class Fetcher

  Response = Struct.new(:status, :body, :error_message)

  def call(uri)
    return Response.new(nil, nil, "invalid URL") unless uri.valid?

    retry_with_backoff do |try_num|
      if try_num > 1
        puts "try #{try_num} for #{uri}"
      end

      puts uri.to_s

      conn = Faraday.new(uri.to_s)

      response = begin
        conn.get # connection problems occur as exceptions of the adapter
      rescue => e
        puts e.message
        nil
      end

      if response
        return Response.new(response.status, response.body)
      end
    end

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
