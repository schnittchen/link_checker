require 'faraday'

module LinkChecker

class Fetcher

  Response = Struct.new(:status, :body)

  def call(uri)
    10.times do |i|

      if i > 0
        puts "try #{i+1} for #{uri}"
      end

      response = begin
        Faraday.get(uri) # connection problems occur as exceptions of the adapter
      rescue => e
        puts e.message
        nil
      end

      if response
        return Response.new(response.status, response.body)
      else
        sleep 2 ** i
      end
    end

    Response.new(0, "retry count exceeded")
  end

end

end
