require 'spec_helper'
require_relative '../lib/ssh_key_generator'

describe GitlabCi::SshKeyGenerator do
  let(:key_location) { '/home/user/.ssh/id_rsa' }
  let(:public_key_location) { "#{key_location}.pub" }

  describe '#generate_key' do

    it 'needs a location' do
      config = double('config', key_location: nil)
      generator = GitlabCi::SshKeyGenerator.new(config)
      expect{generator.generate_key}.to raise_error
    end

    describe 'private/public pair', type: :fakefs do

      before(:each) do
        config = double('config', key_location: key_location)
        generator = GitlabCi::SshKeyGenerator.new(config)
        generator.generate_key
      end

      it 'generates the private key' do
        expect(File.exist?(key_location)).to be_true
      end

      it 'generates the public key' do
        expect(File.exist?(public_key_location)).to be_true
      end

      it 'generates a valid public key' do
        public_key = File.read(public_key_location)
        expect(SSHKey.valid_ssh_public_key?(public_key)).to be_true
      end
    end

  end

end
