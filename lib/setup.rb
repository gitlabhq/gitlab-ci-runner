require_relative 'config'
require_relative 'network'
require_relative 'ssh_key_generator'
require 'yaml'

module GitlabCi
  class Setup
    attr_reader :config

    def initialize
      @config = Config.new
      build_config
      generate_ssh_key
      register_runner
    end

    private

    def build_config
      puts 'Please enter the gitlab-ci coordinator URL (e.g. http://gitlab-ci.org:3000/ )'
      url = gets.chomp
      puts 'Please type where you would like the ssh key to be generated (Ex. ~/.ssh/id_rsa)'
      key_location = gets.chomp
      config.write('url', url)
      config.write('key_location', key_location)
    end

    def generate_ssh_key
      generator = GitlabCi::SshKeyGenerator.new(config)
      generator.generate_key
    end

    def register_runner
      registered = false

      public_key = File.read(File.expand_path("#{config.key_location}.pub"))

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
