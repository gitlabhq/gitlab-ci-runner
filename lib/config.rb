require 'yaml'
require 'optparse'

# The default root path is the path where the gitlab-ci-runner source got
# installed. This may be overridden by the OptionParser below.
$root_path = File.expand_path(File.join(File.dirname(__FILE__), ".."))

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

    def builds_dir
      @builds_path ||= File.join($root_path, 'tmp', 'builds')
    end

    def write(key, value)
      @config[key] = value

      File.open(config_path, "w") do |f|
        f.write(@config.to_yaml)
      end
    end

    private

    def config_path
      File.join($root_path, 'config.yml')
    end
  end
end

OptionParser.new do |opts|
  opts.on('-CWORKING_DIRECTORY', 'Specify the working directory for gitlab-ci-runner') do |v|
    $root_path = File.expand_path(v)
  end
end.parse!
