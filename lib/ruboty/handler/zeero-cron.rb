require 'chrono'

module Ruboty
  module Handlers
    class CronP2Q < Base
      def initialize(robot)
        super
        @thread = Thread.new {
          msg = Message.new(robot: robot)
          attributes = {
            to: "log@conference.zeero.xmpp.slack.com/zeero",
            type: "groupchat",
            body: "ChronoTrigger!",
            original: msg.original
          }
          Chrono::Trigger.new("10 0 * * *") {
            robot.say(attributes)
          }.run
        }
      end
    end
  end
end

