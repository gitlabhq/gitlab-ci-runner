require_relative 'config'

require 'httparty'
require 'json'

module GitlabCi
  class Network
    include HTTParty

    attr_accessor :config

    def initialize(config)
      @config = config
    end

    # check for available build from coordinator
    # and pick a pending one
    # {
    #   commands: ['ls -la'],
    #   path: '/home/git/testproject',
    #   ref: '3ee2b0fda79b326692135f5fb69da8c2eb557709',
    #   id: rand(1900)
    # }
    def get_build
      opts = {
        body: default_options.to_json,
        headers: {"Content-Type" => "application/json"},
      }

      response = self.class.post(api_url + '/builds/register.json', opts)

      if response.code == 201
        broadcast 'Checking for builds... received'
        {
          id: response['id'],
          project_id: response['project_id'],
          commands: response['commands'].lines,
          repo_url: response['repo_url'],
          ref: response['sha'],
          ref_type: response['ref_type'],
          ref_name: response['ref'],
          before_sha: response['before_sha'],
          allow_git_fetch: response['allow_git_fetch'],
          timeout: response['timeout'],
          build_method: response['build_method'] || 'shell',
          build_os: response['build_os'],
          build_image: response['build_image'],
          custom_commands: response['custom_commands']
        }
      elsif response.code == 403
        broadcast 'Checking for builds... forbidden'
      else
        broadcast 'Checking for builds... nothing'
      end
    rescue
      broadcast 'Checking for builds... failed'
    end

    def update_build(id, state, trace)
      options = default_options.merge(
        state: state,
        trace: trace,
      )

      response = self.class.put("#{api_url}/builds/#{id}.json", body: options)

      case response.code
      when 200
        broadcast "Submitting build #{id} to coordinator... ok"
        :success
      when 404
        broadcast "Submitting build #{id} to coordinator... aborted"
        :aborted
      else
        broadcast "Submitting build #{id} to coordinator... response error: #{response.code}"
        :failure
      end
    rescue => e
      broadcast "Submitting build #{id} to coordinator... failure: #{e.message}"
      :failure
    end

    def register_runner(token)
      body = {
        token: token,
        hostname: config.hostname,
        os: config.os,
        images: config.images
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
      puts "#{Time.now.to_s} | #{message}"
    end

    def api_url
      config.url + '/api/v1'
    end

    def token
      config.token
    end

    def config
      @config
    end

    def default_options
      {
        token: token,
        os: @config.os,
        images: @config.images
      }
    end
  end
end
