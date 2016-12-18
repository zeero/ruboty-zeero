require 'chrono'

module Ruboty
  module Handlers
    class CronP2Q < Base
      def initialize(robot)
        super
        Chrono::Trigger.new("10 * * * *") {
          robot.say({
            body: "ChronoTrigger!",
          })
        }.run
      end
    end
  end
end

