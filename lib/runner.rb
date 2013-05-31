require_relative 'build'
require_relative 'network'

module GitlabCi
  class Runner
    attr_accessor :current_build, :thread

    def initialize
      puts '* Gitlab CI Runner started'
      puts '* Waiting for builds'

      loop do
        if completed? || running?
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

    def completed?
      @current_build && @current_build.completed?
    end

    def update_build
      if @current_build.completed?
        if push_build
          puts "#{Time.now.to_s} | Completed build #{@current_build.id}"
          @current_build = nil
        end
      else
        push_build
      end
    end

    def push_build
      network.update_build(
        @current_build.id,
        @current_build.state,
        @current_build.trace
      )
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
      @current_build = GitlabCi::Build.new(build_data)

      Thread.abort_on_exception = true

      Thread.new(@current_build) do
        puts "#{Time.now.to_s} | Build #{@current_build.id} started.."

        @current_build.run
      end
    end

    def collect_trace
      @current_build.trace
    end
  end
end
