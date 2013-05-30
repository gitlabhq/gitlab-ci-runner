require_relative 'encode'

require 'childprocess'
require 'tempfile'

module GitlabCi
  class Build
    TIMEOUT = 3600

    attr_accessor :id, :commands, :path, :ref, :tmp_file_path, :output, :state

    def initialize(id, commands, path, ref)
      @commands = commands
      @path = path
      @ref = ref
      @id = id
      @state = :waiting
    end

    def run
      @state = :running
      @commands.unshift git_cmd

      @commands.each do |line|
        status = command line
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
      return output if completed?

      File.read(tmp_file_path)
    rescue
      ''
    end

    private

    def command(cmd)
      cmd = cmd.strip
      status = 0

      @output ||= ""
      @output << "\n"
      @output << cmd
      @output << "\n"

      @process = ChildProcess.build(cmd)
      @tmp_file = Tempfile.new("child-output", binmode: true)
      @process.io.stdout = @tmp_file
      @process.io.stderr = @tmp_file
      @process.cwd = @path

      # ENV
      @process.environment['BUNDLE_GEMFILE'] = File.join(@path, 'Gemfile')
      @process.environment['BUNDLE_BIN_PATH'] = ''
      @process.environment['RUBYOPT'] = ''

      @process.environment['CI_SERVER'] = 'yes'
      @process.environment['CI_SERVER_NAME'] = 'GitLab CI'
      @process.environment['CI_SERVER_VERSION'] = nil# GitlabCi::Version
      @process.environment['CI_SERVER_REVISION'] = nil# GitlabCi::Revision

      @process.environment['CI_BUILD_REF'] = @ref

      @process.start

      @tmp_file_path = @tmp_file.path

      begin
        @process.poll_for_exit(TIMEOUT)
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

    def git_cmd
      cmd = []
      cmd << "cd #{@path}"
      cmd << "git fetch"
      cmd << "git reset --hard"
      cmd << "git checkout #{@ref}"
      cmd.join(" && ")
    end
  end
end
