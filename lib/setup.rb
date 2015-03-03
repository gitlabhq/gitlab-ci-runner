require_relative 'config'
require_relative 'network'
require 'yaml'

module GitlabCi
  class Setup
    def initialize
      build_config
      register_runner
    end

    private

    def build_config
      url = ENV['CI_SERVER_URL']
      unless url
        puts 'Please enter the gitlab-ci coordinator URL (e.g. http://gitlab-ci.org/ )'
        url = gets.chomp
      end

      Config.new.write('url', url)
    end

    def register_runner
      registered = false

      until registered
        token = ENV['REGISTRATION_TOKEN']
        description = ENV['RUNNER_DESCRIPTION'] || Socket.gethostname
        tag_list = ENV['RUNNER_TAG_LIST']

        unless token
          puts 'Please enter the gitlab-ci token for this runner: '
          token = gets.chomp
        end

        puts "Registering runner as #{description} with registration token: #{token}, url: #{Config.new.url}."
        runner = Network.new.register_runner(token, description, tag_list)

        if runner
          write_token(runner[:token])
          puts 'Runner registered successfully. Feel free to start it!'
          return
        else
          puts 'Failed to register this runner. Perhaps your SSH key is invalid or you are having network problems'
        end
      end
    end

    def write_token(token)
      puts "Runner token: #{token}"

      Config.new.write('token', token)
    end
  end
end
