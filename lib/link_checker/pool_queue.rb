require 'thread'

module LinkChecker

class PoolQueue
  def initialize(pool_size)
    @pool_size = pool_size
    @queue = Queue.new

    @mtx = Mutex.new
    @cond = ConditionVariable.new

    @workers = (1..pool_size).map {
      Thread.new(&method(:thread_body))
    }
  end

  def push_job(callable = nil, &block)
    callable ||= block
    @queue << callable
  end

  def length
    @queue.length
  end

  def finished?
    @queue.empty? && @queue.num_waiting == @pool_size
  end

  def wait_until_finished
    @mtx.synchronize do
      while !finished?
        @cond.wait(@mtx)
      end
    end
  end

  private

  def thread_body
    while job = fetch_job
      job.call
    end
  end

  def fetch_job
    @cond.signal if @queue.empty?
    @queue.pop
  end
end

end

