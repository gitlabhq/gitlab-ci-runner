require_relative 'config'
require_relative 'network'
require 'yaml'

module GitlabCi
  class Setup
    def initialize
      build_config

      rebuild_key = false
      check_key = File.exist?(File.expand_path('~/.ssh/id_rsa.pub'))
      if check_key
          puts 'Rebuild SSH Key'
          get_rebuild = gets.chomp
          if get_rebuild == 'y'
              rebuild_key = true
          elsif get_rebuild == 'yes'
              rebuild_key = true
          else
              rebuild_key = false
          end
      else
          rebuild_key = true
      end               

      if rebuild_key
          generate_ssh_key
      end

      register_runner
    end

    private

    def build_config
      puts 'Please type gitlab-ci url (Ex. http://gitlab-ci.org:3000/ )'
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
        puts 'Please type gitlab-ci runners token: '
        token = gets.chomp

        runner = Network.new.register_runner(public_key, token)

        if runner
          write_token(runner[:token])
          puts 'Runner registered. Feel free to start it'
          return
        else
          puts 'Cannot register Runner. Maybe invalid key or network problem'
        end
      end
    end

    def write_token(token)
      puts "Runner Token: #{token}"

      Config.new.write('token', token)
    end
  end
end
