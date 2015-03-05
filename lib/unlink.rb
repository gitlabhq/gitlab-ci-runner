require_relative 'config'
require_relative 'network'
require 'yaml'

module GitlabCi
  class Unlink
    def initialize
      unlink_runner
    end

    private

    def unlink_runner
      status = Network.new.unlink_runner

      if status
        Config.new.destroy
        puts 'Runner unlinked successfully!'
        return
      else
        puts 'Failed to unlink this runner. Perhaps the runner is not subscribed yet or you are having network problems'
      end
    end
  end
end
