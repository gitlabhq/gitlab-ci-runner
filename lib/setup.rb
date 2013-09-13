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
      url = ENV['CI_SERVER_URL']
      unless url
        puts 'Please enter the gitlab-ci coordinator URL (e.g. http://gitlab-ci.org:3000/ )'
        url = gets.chomp
      end

      Config.new.write('url', url)
    end

    def generate_ssh_key
      system('ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""') # Create a key without a password.
    end

    def register_runner
      registered = false

      public_key = File.read(File.expand_path('~/.ssh/id_rsa.pub'))

      until registered
        token = ENV['RUNNER_TOKEN']
        unless token
          puts 'Please enter the gitlab-ci token for this runner: '
          token = gets.chomp
        end

        puts "Registering runner with public key type: #{public_key[0..6]}, token: #{token}, url: #{Config.new.url}."
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
