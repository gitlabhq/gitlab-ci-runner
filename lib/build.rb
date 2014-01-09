require_relative 'encode'
require_relative 'config'

require 'childprocess'
require 'tempfile'
require 'fileutils'
require 'bundler'

module GitlabCi
  class Build
    TIMEOUT = 7200

    attr_accessor :id, :commands, :ref, :tmp_file_path, :output, :state, :before_sha

    def initialize(data)
      @commands = data[:commands].to_a
      @ref = data[:ref]
      @ref_name = data[:ref_name]
      @id = data[:id]
      @project_id = data[:project_id]
      @repo_url = data[:repo_url]
      @state = :waiting
      @before_sha = data[:before_sha]
      @timeout = data[:timeout] || TIMEOUT
      @allow_git_fetch = data[:allow_git_fetch]
    end

    def run
      @state = :running

      @commands.unshift(checkout_cmd)

      if repo_exists? && @allow_git_fetch
        @commands.unshift(fetch_cmd)
      else
        FileUtils.rm_rf(project_dir)
        FileUtils.mkdir_p(project_dir)
        @commands.unshift(clone_cmd)
      end

      @commands.each do |line|
        status = Bundler.with_clean_env { command line }
        @state = :failed and return unless status
      end

      @state = :success
    end

    def completed?
      success? || failed?
    end

    def success?
      state == :success
    end

    def failed?
      state == :failed
    end

    def running?
      state == :running
    end

    def trace
      output + tmp_file_output
    rescue
      ''
    end

    def tmp_file_output
      tmp_file_output = GitlabCi::Encode.encode!(File.binread(tmp_file_path)) if tmp_file_path && File.readable?(tmp_file_path)
      tmp_file_output ||= ''
    end

    private

    def command(cmd)
      cmd = cmd.strip
      status = 0

      @output ||= ""
      @output << "\n"
      @output << cmd
      @output << "\n"

      @process = ChildProcess.build('bash', '--login', '-c', cmd)
      @tmp_file = Tempfile.new("child-output", binmode: true)
      @process.io.stdout = @tmp_file
      @process.io.stderr = @tmp_file
      @process.cwd = project_dir

      # ENV
      # Bundler.with_clean_env now handles PATH, GEM_HOME, RUBYOPT & BUNDLE_*.

      @process.environment['CI_SERVER'] = 'yes'
      @process.environment['CI_SERVER_NAME'] = 'GitLab CI'
      @process.environment['CI_SERVER_VERSION'] = nil# GitlabCi::Version
      @process.environment['CI_SERVER_REVISION'] = nil# GitlabCi::Revision

      @process.environment['CI_BUILD_REF'] = @ref
      @process.environment['CI_BUILD_BEFORE_SHA'] = @before_sha
      @process.environment['CI_BUILD_REF_NAME'] = @ref_name
      @process.environment['CI_BUILD_ID'] = @id

      @process.start

      @tmp_file_path = @tmp_file.path

      begin
        @process.poll_for_exit(@timeout)
      rescue ChildProcess::TimeoutError
        @output << "TIMEOUT"
        @process.stop # tries increasingly harsher methods to kill the process.
        return false
      end

      @process.exit_code == 0

    rescue => e
      # return false if any exception occurs
      @output << e.message
      false

    ensure
      @tmp_file.rewind
      @output << GitlabCi::Encode.encode!(@tmp_file.read)
      @tmp_file.close
      @tmp_file.unlink
    end

    def checkout_cmd
      cmd = []
      cmd << "cd #{project_dir}"
      cmd << "git reset --hard"
      cmd << "git checkout #{@ref}"
      cmd.join(" && ")
    end

    def clone_cmd
      cmd = []
      cmd << "cd #{config.builds_dir}"
      cmd << "git clone #{@repo_url} project-#{@project_id}"
      cmd << "cd project-#{@project_id}"
      cmd << "git checkout #{@ref}"
      cmd.join(" && ")
    end

    def fetch_cmd
      cmd = []
      cmd << "cd #{project_dir}"
      cmd << "git reset --hard"
      cmd << "git clean -fdx"
      cmd << "git remote set-url origin #{@repo_url}"
      cmd << "git fetch origin"
      cmd.join(" && ")
    end

    def repo_exists?
      File.exists?(File.join(project_dir, '.git'))
    end

    def config
      @config ||= Config.new
    end

    def project_dir
      File.join(config.builds_dir, "project-#{@project_id}")
    end
  end
end
