require 'yaml'

ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__), ".."))

module GitlabCi
  class Config
    attr_reader :config

    def initialize
      @config = YAML.load_file(File.join(ROOT_PATH, 'config.yml'))
    end

    def token
      @config['token']
    end

    def url
      @config['url']
    end

    def builds_dir
      @builds_path ||= File.join(ROOT_PATH, 'tmp', 'builds')
    end
  end
end
