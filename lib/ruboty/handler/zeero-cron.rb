require 'chrono'

module Ruboty
  module Handlers
    class CronP2Q < Base
      def initialize(robot)
        super
        @thread = Thread.new {
          attributes = {
            from: "log@conference.zeero.xmpp.slack.com/zeero",
            type: "groupchat",
            body: "ruboty echo Trigger!",
          }
          Chrono::Trigger.new("37 * * * *") {
            puts "Chrono!"
            robot.receive(attributes)
          }.run
        }
      end
    end
  end
end

