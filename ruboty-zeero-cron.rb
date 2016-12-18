module Ruboty
  module Handlers
    class HelloWorld < Base
      on(
        /test/i,
        name: "test",
        description: "Test!"
      )

      def test(message)
        message.reply("Test")
      end
    end
  end
end

