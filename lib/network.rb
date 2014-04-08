require_relative 'config'

require 'httparty'
require 'json'

module GitlabCi
  class Network
    include HTTParty

    # check for available build from coordinator
    # and pick a pending one
    # {
    #   commands: ['ls -la'],
    #   path: '/home/git/testproject',
    #   ref: '3ee2b0fda79b326692135f5fb69da8c2eb557709',
    #   id: rand(1900)
    # }
    def get_build
      broadcast 'Checking for builds...'

      opts = {
        body: default_options.to_json,
        headers: {"Content-Type" => "application/json"},
      }

      response = self.class.post(api_url + '/builds/register.json', opts)

      if response.code == 201
        puts 'received'
        {
          id: response['id'],
          project_id: response['project_id'],
          commands: response['commands'].lines,
          repo_url: response['repo_url'],
          ref: response['sha'],
          ref_name: response['ref'],
          before_sha: response['before_sha'],
          project_name: response['project_name']
          allow_git_fetch: response['allow_git_fetch'],
          timeout: response['timeout']
        }
      elsif response.code == 403
        puts 'forbidden'
      else
        puts 'nothing'
      end
    rescue
      puts 'failed'
    end

    def update_build(id, state, trace)
      broadcast "Submitting build #{id} to coordinator..."

      options = default_options.merge(
        state: state,
        trace: trace,
      )

      response = self.class.put("#{api_url}/builds/#{id}.json", body: options)

      if response.code == 200
        puts 'ok'
        true
      else
        puts 'failed'
      end
    rescue
      puts 'failed'
      false
    end

    def register_runner(public_key, token)
      body = {
        public_key: public_key,
        token: token
      }

      opts = {
        body: body.to_json,
        headers: {"Content-Type" => "application/json"},
      }

      response = self.class.post(api_url + '/runners/register.json', opts)

      if response.code == 201
        {
          token: response['token']
        }
      end
    end

    private

    def broadcast message
      print "#{Time.now.to_s} | #{message}"
    end

    def api_url
      config.url + '/api/v1'
    end

    def token
      config.token
    end

    def config
      @config ||= Config.new
    end

    def default_options
      {
        token: token
      }
    end
  end
end
