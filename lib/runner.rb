module GitlabCi
  class Runner
    def initialize
      loop do

        if running?
          send_trace
        else
          get_build
        end

        sleep 5
      end
    end

    def running?
      # check if build running
    end

    def send_trace
      # send build trace to coordinator over network
    end

    def get_build
      # check for available build from coordinator
    end
  end
end
