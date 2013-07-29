require 'sshkey'

module GitlabCi
  class SshKeyGenerator
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def generate_key
      raise 'No key was configured' unless key_location

      key = SSHKey.generate
      save_key_to_disk(key)
    end

    private

    def key_location
      config.key_location
    end

    def public_key_location
      "#{key_location}.pub"
    end

    def save_key_to_disk(key)
      FileUtils.mkdir_p File.dirname(key_location)

      private_key = File.new(key_location, 'w')
      private_key.sync = true
      private_key.write(key.private_key)

      public_key = File.new(public_key_location, 'w')
      public_key.sync = true
      public_key.write(key.ssh_public_key)

      File.chmod(0600, key_location, public_key_location)
    end
  end
end
