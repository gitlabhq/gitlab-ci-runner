require_relative 'build'
require_relative 'network'

module GitlabCi
  class Runner
    attr_accessor :current_build, :thread

    def initialize
      puts '* Gitlab CI Runner started'
      puts '* Waiting for builds'

      loop do
        if running?
          update_build
        else
          get_build
        end

        sleep 5
      end
    end

    private

    def running?
      @current_build
    end

    def update_build
      puts "Submiting build #{@current_build.id} to coordinator..."
      network.update_build(
        @current_build.id,
        @current_build.state,
        @current_build.trace
      )

      if @current_build.completed?
        puts "Completed build #{@current_build.id}"
        @current_build = nil
      end
    end

    def get_build
      build_data = network.get_build

      if build_data
        run(build_data)
      else
        false
      end
    end

    def network
      @network ||= Network.new
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
