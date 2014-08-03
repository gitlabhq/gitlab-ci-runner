require_relative 'spec_helper'
require_relative '../lib/build'

describe 'Build' do
  describe :run do
    let(:build) { GitlabCi::Build.new(0, build_data) }

    before do
      build.run
      loop do
        break if build.completed?
      end
    end

    it { build.trace.should include 'bundle' }
    it { build.trace.should include 'HEAD is now at 2e008a7' }
    it { build.state.should == :success }
  end

  def build_data
    {
      commands: ['bundle'],
      project_id: 0,
      id: 9312,
      ref: '2e008a711430a16092cd6a20c225807cb3f51db7',
      repo_url: 'https://github.com/randx/six.git'
    }
  end
end

