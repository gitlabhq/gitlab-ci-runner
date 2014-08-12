require_relative 'build'
require_relative 'network'
require_relative 'workers'

module GitlabCi
  class Runner
    attr_accessor :current_build, :thread

    def initialize
      puts '* Gitlab CI Runner started'
      puts '* Waiting for builds'
      loop do
        check_workers
        check_for_new_builds if workers.count < config.workers
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

    def check_workers
      workers.pids.dup.each do |worker, build_data|
        begin
          if Process.waitpid(worker, Process::WNOHANG)
            workers.remove_worker(worker)
            puts "#{Time.now.to_s} | Worker finished [pid:#{worker}, running:#{workers.count}]"
          end
        rescue
          if config.restart_job_on_die
            start_build(build_data)
          else
            return unless update_died_build(build_data[:id])
          end
          puts "#{Time.now.to_s} | Worker died [pid:#{worker}, running:#{workers.count}]"
          workers.remove_worker(worker)
        end
      end
    end
    def update_died_build(id)
      return unless id
      case network.update_build(id, :failed, "Worker died")
        when :success
          true
        when :aborted
          true
        when :failure
          false
      end
    end


    def run_build(build_data)
      run(build_data)
      loop do
        if running?
          abort_if_timeout
          push_build
          update_build
          sleep 3
        else
          break
        end
      end
    end

    def start_build(build_data)
      build_data[:runner_id] = workers.next_runner_id
      new_worker = fork do
        run_build(build_data)
      end
      workers.add_worker(new_worker, build_data)
      puts "#{Time.now.to_s} | New worker created [pid:#{new_worker}, running:#{workers.count}]"
    end

    def check_for_new_builds
      get_build do |build_data|
        start_build(build_data)
      end
    end

    def update_build
      return unless @current_build.completed?
      puts "#{Time.now.to_s} | Completed build #{@current_build.id}, #{@current_build.state}."

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

    def get_build(&block)
      raise 'block must be specified' unless block_given?
      build_data = network.get_build
      block.call(build_data) if build_data
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
      @current_build.collect_trace
    end

    def config
      @config ||= Config.new
    end

    def workers
      @workers ||= Workers.new
    end
  end
end
