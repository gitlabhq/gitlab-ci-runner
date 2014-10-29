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
        puts 'Please enter the gitlab-ci coordinator URL (e.g. http://gitlab-ci.org:3000/ )'
        url = gets.chomp
      end

      config.write('url', url)
      config.write('workers', config.workers)
    end

    def register_runner
      registered = false

      until registered
        token = ENV['REGISTRATION_TOKEN']
        unless token
          puts 'Please enter the gitlab-ci token for this runner: '
          token = gets.chomp
        end

        puts "Registering runner with registration token: #{token}, url: #{config.url}."
        runner = Network.new(config).register_runner(token)

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

      config.write('token', token)
    end

    private

    def config
      @config ||= Config.new
    end
  end
end
