require 'yaml'

ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__), ".."))

module GitlabCi
  class Config
    attr_reader :config

    def initialize
      if File.exists?(config_path)
        @config = YAML.load_file(config_path)
      else
        @config = {}
      end
    end

    def token
      @config['token']
    end

    def url
      @config['url']
    end

    def key_location
      @config['key_location']
    end

    def builds_dir
      @builds_path ||= File.join(ROOT_PATH, 'tmp', 'builds')
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
