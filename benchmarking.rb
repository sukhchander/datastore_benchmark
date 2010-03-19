# benchmarking helpers, etc...

module Benchmarking
    def elapsed(&block)
      timer = Time.now
      block.call
      Time.now - timer
    end
end
