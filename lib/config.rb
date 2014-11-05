require 'yaml'
require 'socket'

ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__), ".."))

module GitlabCi
  class Config
    attr_reader :config

    def initialize
      if File.exists?(config_path)
        @config = YAML.load_file(config_path)
        @mtime = File.mtime(config_path)
      else
        @config = {}
        @mtime = Time.at(0)
      end
    end

    def reload
      begin
        if File.exists?(config_path)
          new_mtime = File.mtime(config_path)
          return false unless @mtime < new_mtime
          @config = YAML.load_file(config_path)
          @mtime = new_mtime
        end
      rescue => e
        puts("Exception during file reload: #{e.to_s}")
      end
    end

    def token
      @config['token']
    end

    def url
      @config['url']
    end

    def os
      @config.fetch('os') do
        case RUBY_PLATFORM
          when /mswin|windows/i
            'windows'
          when /linux|arch/i
            'linux'
          when /sunos|solaris/i
            'solaris'
          when /darwin/i
            'osx'
          else
            'unknown'
        end
      end
    end

    def worker_update
      @config['worker_update'] || 5
    end

    def build_update
      @config['build_update'] || 3
    end

    def hostname
      @config.fetch('hostname') do
        Socket.gethostname
      end
    end

    def images
      @config['images']
    end

    def builds_dir
      @builds_path ||= @config['builds_dir']
      @builds_path ||= File.join(ROOT_PATH, 'tmp', 'builds')
    end

    def scripts_dir
      @scripts_path ||= @config['scripts_dir']
      @scripts_path ||= File.join(ROOT_PATH, 'tmp', 'scripts')
    end

    def execute_script
      @config['execute_script'] || 'setsid'
    end

    def restart_job_on_die
      @config['restart_job_on_die']
    end

    def workers
      @config.fetch('workers', 1)
    end

    def write(key, value)
      @config[key] = value

      File.open(config_path, "w") do |f|
        f.write(@config.to_yaml)
      end
    end

    private

    def config_path
      File.join(ROOT_PATH, 'config.yml')
    end
  end
end
