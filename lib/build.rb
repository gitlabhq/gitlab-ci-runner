require_relative 'encode'
require_relative 'config'

require 'childprocess'
require 'pty'
require 'tempfile'
require 'fileutils'
require 'bundler'
require 'shellwords'

module GitlabCi
  class Build
    TIMEOUT = 7200

    attr_accessor :id, :commands, :ref, :ref_type, :tmp_file_path, :output, :before_sha, :run_at, :post_message,
                  :build_method, :build_os, :build_image, :custom_commands, :job_id

    def initialize(data)
      @output = ""
      @post_message = ""
      @commands = data[:commands].to_a
      @ref = data[:ref]
      @ref_name = data[:ref_name]
      @ref_type = data[:ref_type]
      @id = data[:id]
      @project_id = data[:project_id]
      @repo_url = data[:repo_url]
      @before_sha = data[:before_sha]
      @timeout = data[:timeout] || TIMEOUT
      @allow_git_fetch = data[:allow_git_fetch]
      @build_method = data[:build_method]
      @build_os = data[:build_os]
      @build_image = data[:build_image]
      @custom_commands = data[:custom_commands]
      @job_id = 0
      @runner_id = data[:runner_id] || 0
    end

    def run
      open_build_script_file

      if @custom_commands
        @commands.each do |command|
          @run_file.puts(command)
        end
      else
        @run_file.puts %|#!/bin/bash|
        @run_file.puts %|set -e|
        @run_file.puts %|trap 'kill -s INT 0' EXIT|

        if @allow_git_fetch
          @run_file.puts %|if [[ -e #{project_dir.shellescape}/.git ]]; then #{fetch_cmd}; else #{clone_cmd}; fi|
        else
          @run_file.puts(clone_cmd)
        end

        @run_file.puts(checkout_cmd)

        @commands.each do |command|
          command.strip!
          @run_file.puts %|echo #{command.shellescape}|
          @run_file.puts(command)
        end
      end

      @run_file.flush
      @run_at = Time.now

      Bundler.with_clean_env { execute("#{config.execute_script} #{@run_file.path}") }
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
      @run_file.close
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

    def open_build_script_file
      FileUtils.mkdir_p(config.scripts_dir)

      @job_id = 0

      while true
        # try to acquire lock
        @run_file = File.open(project_build_script, File::RDWR|File::CREAT, 0700)
        next unless @run_file
        lock_result = @run_file.flock(File::LOCK_EX|File::LOCK_NB)
        break if lock_result
        @run_file.close
        @job_id += 1
      end

      @run_file.truncate(0)
    end

    def execute(cmd)
      cmd = cmd.strip

      @process = ChildProcess.build('bash', '--login', '-c', cmd)
      @tmp_file = Tempfile.new("child-output", binmode: true)
      @process.io.stdout = @tmp_file
      @process.io.stderr = @tmp_file

      # ENV
      # Bundler.with_clean_env now handles PATH, GEM_HOME, RUBYOPT & BUNDLE_*.

      @process.environment['CI_SERVER'] = 'yes'
      @process.environment['CI_SERVER_NAME'] = 'GitLab CI'
      @process.environment['CI_SERVER_VERSION'] = nil# GitlabCi::Version
      @process.environment['CI_SERVER_REVISION'] = nil# GitlabCi::Revision

      @process.environment['CI_BUILD_REF'] = @ref
      @process.environment['CI_BUILD_BEFORE_SHA'] = @before_sha
      @process.environment['CI_BUILD_REF_NAME'] = @ref_name
      @process.environment['CI_BUILD_REF_TYPE'] = @ref_type
      @process.environment['CI_BUILD_ID'] = @id
      @process.environment['CI_BUILD_METHOD'] = @build_method
      @process.environment['CI_BUILD_OS'] = @build_os
      @process.environment['CI_BUILD_IMAGE'] = @build_image
      @process.environment['CI_BUILD_ALLOW_GIT_FETCH'] = @allow_git_fetch
      @process.environment['CI_BUILD_TIMEOUT'] = @timeout
      @process.environment['CI_BUILD_JOB_ID'] = @job_id

      @process.environment['CI_PROJECT_ID'] = @project_id
      @process.environment['CI_RUNNER_ID'] = @runner_id

      @process.start

      @tmp_file_path = @tmp_file.path
    rescue => e
      @output << e.message
    end

    def checkout_cmd
      cmd = []
      cmd << "cd #{project_dir.shellescape}"
      cmd << "git reset --hard"
      cmd << "git checkout #{@ref}"
      cmd.join(" && ")
    end

    def clone_cmd
      cmd = []
      cmd << "rm -rf #{project_dir.shellescape}"
      cmd << "mkdir -p #{builds_dir.shellescape}"
      cmd << "cd #{builds_dir.shellescape}"
      cmd << "git clone #{@repo_url.shellescape} #{project_dir_name.shellescape}"
      cmd << "cd #{project_dir_name.shellescape}"
      cmd << "git checkout #{@ref}"
      cmd.join(" && ")
    end

    def fetch_cmd
      cmd = []
      cmd << "cd #{project_dir.shellescape}"
      cmd << "git reset --hard"
      cmd << "git clean -fdx"
      cmd << "git remote set-url origin #{@repo_url.shellescape}"
      cmd << "git fetch origin"
      cmd.join(" && ")
    end

    def config
      @config ||= Config.new
    end

    def builds_dir
      config.builds_dir
    end

    def project_dir_name
      "project-#{@project_id}-job-#{@job_id}"
    end
    
    def project_dir
      File.join(builds_dir, project_dir_name)
    end

    def project_build_script
      File.join(config.scripts_dir, project_dir_name)
    end
  end
end
