require_relative 'encode'
require_relative 'config'

require 'childprocess'
require 'tempfile'
require 'fileutils'
require 'bundler'
require 'shellwords'

module GitlabCi
  class Build
    TIMEOUT = 7200

    attr_accessor :id, :commands, :ref, :tmp_file_path, :output, :before_sha, :run_at, :post_message

    def initialize(data)
      @output = ""
      @post_message = ""
      @commands = data[:commands].to_a
      @ref = data[:ref]
      @ref_name = data[:ref_name]
      @id = data[:id]
      @project_id = data[:project_id]
      @repo_url = data[:repo_url]
      @before_sha = data[:before_sha]
      @timeout = data[:timeout] || TIMEOUT
      @allow_git_fetch = data[:allow_git_fetch]
      @cache_pattern_list = data[:cache_pattern_list] || []
    end

    def run
      @run_file = Tempfile.new("executor")
      @run_file.chmod(0700)

      @commands.unshift(checkout_cmd)

      if repo_exists? && @allow_git_fetch
        @commands.unshift(fetch_cmd)
      else
        FileUtils.rm_rf(project_dir)
        FileUtils.mkdir_p(project_dir)
        @commands.unshift(clone_cmd)
      end

      @run_file.puts %|#!/bin/bash|
      @run_file.puts %|set -e|
      @run_file.puts %|trap 'kill -s INT 0' EXIT|

      @commands.each do |command|
        command.strip!
        @run_file.puts %|echo #{command.shellescape}|
        @run_file.puts(command)
      end
      @run_file.close
      @run_at = Time.now

      Bundler.with_clean_env { execute("setsid #{@run_file.path}") }
    end

    def state
      return :success if success?
      return :failed if failed?
      :running
    end

    def completed?
      @process.exited?
    end

    def success?
      return nil unless completed?
      @process.exit_code == 0
    end

    def failed?
      return nil unless completed?
      @process.exit_code != 0
    end

    def running?
      @process.alive?
    end

    def abort
      @process.stop
    end

    def trace
      output + tmp_file_output + post_message
    rescue
      ''
    end

    def tmp_file_output
      tmp_file_output = GitlabCi::Encode.encode!(File.binread(tmp_file_path)) if tmp_file_path && File.readable?(tmp_file_path)
      tmp_file_output ||= ''
    end

    def cleanup
      @tmp_file.rewind
      @output << GitlabCi::Encode.encode!(@tmp_file.read)
      @tmp_file.close
      @tmp_file.unlink
      @run_file.unlink
    end

    # Check if build execution is longer
    # than allowed by timeout
    def running_too_long?
      if @run_at && @timeout
        @run_at + @timeout < Time.now
      else
        false
      end
    end

    def timeout_abort
      self.abort

      @post_message = "\nCI Timeout. Execution took longer then #{@timeout} seconds"
    end

    private

    def execute(cmd)
      cmd = cmd.strip

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
      @process.environment['CI_BUILD_REPO'] = @repo_url

      @process.environment['CI_PROJECT_ID'] = @project_id
      @process.environment['CI_PROJECT_DIR'] = project_dir

      @process.start

      @tmp_file_path = @tmp_file.path
    rescue => e
      @output << e.message
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
      cmd << "git clean #{git_clean_opts}"
      cmd << "git remote set-url origin #{@repo_url}"
      cmd << "git fetch origin"
      cmd.join(" && ")
    end

    def git_clean_opts
      opts = @cache_pattern_list.collect { |item| "--exclude='#{item}'"}
      opts.unshift("-fdx")
      opts.join(" ")
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
