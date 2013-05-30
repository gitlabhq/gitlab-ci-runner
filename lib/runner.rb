require_relative 'build'

module GitlabCi
  class Runner
    attr_accessor :current_build, :token, :thread

    def initialize
      puts '* Gitlab CI Runner started'
      puts '* Waiting for builds'

      loop do
        if completed?
          submit_build
        elsif running?
          send_trace
        else
          get_build
        end

        sleep 5
      end
    end

    def completed?
      @current_build && @current_build.completed?
    end

    def running?
      @current_build
    end

    def send_trace
      puts collect_trace
    end

    def submit_build
      send_trace
      puts "Completed build #{@current_build.id}"
      puts "Submiting build #{@current_build.id} to coordinator..."
      @current_build = nil
    end

    def get_build
      build_data = get_pending_build

      if build_data
        run(build_data)
      else
        false
      end
    end

    def token
      @token ||= File.read(File.expand_path(File.join(File.dirname(__FILE__), 'support', "token")))
    end

    def get_pending_build
      # check for available build from coordinator
      # and pick a pending one
      {
        commands: ['ls -la'],
        path: '/home/git/testproject',
        ref: '3ee2b0fda79b326692135f5fb69da8c2eb557709',
        id: 657
      }
    end

    def run(build_data)
      @current_build = GitlabCi::Build.new(
        build_data[:id],
        build_data[:commands],
        build_data[:path],
        build_data[:ref],
      )

      Thread.abort_on_exception = true

      Thread.new(@current_build) do
        puts "Build #{@current_build.id} started.."

        @current_build.run
      end
    end

    def collect_trace
      @current_build.trace
    end
  end
end
