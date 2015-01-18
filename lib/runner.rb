require_relative 'build'
require_relative 'network'

module GitlabCi
  class Runner
    attr_accessor :current_build, :thread

    def initialize(runner)
      @runner = runner
      puts "* Gitlab CI Runner #{@runner} started"
      puts '* Waiting for builds'
      loop do
        if running?
          abort_if_timeout
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

    def abort_if_timeout
      if @current_build.running? && @current_build.running_too_long?
        @current_build.timeout_abort
      end
    end

    def update_build
      return unless @current_build.completed?
      puts "#{Time.now.to_s} | Completed build #{@current_build.id}, #{@current_build.state} on runner #{@runner}."

      # Make sure we push latest build info submitted
      # before we clean build
      if push_build
        @current_build.cleanup
        @current_build = nil
      else
        # wait when ci server will be online again to submit build results
      end
    end

    def push_build
      case network.update_build(@current_build.id, @current_build.state, @current_build.trace)
      when :success
        # nothing to do here
        true
      when :aborted
        @current_build.abort
        true
      when :failure
        # nothing to do here, we simply assume this is a temporary failure communicating with the gitlab-ci server
        false
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
      @network ||= Network.new(@runner)
    end

    def run(build_data)
      @current_build = GitlabCi::Build.new(@runner, build_data)
      puts "#{Time.now.to_s} | Starting new build #{@current_build.id} with runner #{@runner}..."
      @current_build.run
      puts "#{Time.now.to_s} | Build #{@current_build.id} on runner #{@runner} started."
    end

    def collect_trace
      @current_build.trace
    end
  end
end
