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
          push_build
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
      return unless @current_build.completed?
      puts "#{Time.now.to_s} | Completed build #{@current_build.id}, #{@current_build.state}."
      @current_build.cleanup
      @current_build = nil
    end

    def push_build
      case network.update_build(@current_build.id, @current_build.state, @current_build.trace)
      when :success
        # nothing to do here
      when :aborted
        @current_build.abort
      when :failure
        # nothing to do here, we simply assume this is a temporary failure communicating with the gitlab-ci server
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
      @current_build = GitlabCi::Build.new(build_data)
      puts "#{Time.now.to_s} | Starting new build #{@current_build.id}..."
      @current_build.run
      puts "#{Time.now.to_s} | Build #{@current_build.id} started."
    end

    def collect_trace
      @current_build.trace
    end
  end
end
