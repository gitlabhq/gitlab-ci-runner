require_relative 'config'
require_relative 'network'
require 'yaml'

module GitlabCi
  class Setup
    def initialize
      build_config
      generate_ssh_key
      register_runner
    end

    private

    def build_config
      puts 'Please enter the gitlab-ci coordinator URL (e.g. http://gitlab-ci.org:3000/ )'
      url = gets.chomp

      Config.new.write('url', url)
    end

    def generate_ssh_key
      system('ssh-keygen -t rsa')
    end

    def register_runner
      registered = false

      public_key = File.read(File.expand_path('~/.ssh/id_rsa.pub'))

      until registered
        puts 'Please enter the gitlab-ci token for this runner: '
        token = gets.chomp

        runner = Network.new.register_runner(public_key, token)

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
