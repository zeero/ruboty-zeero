module Ruboty
  module Handlers
    class HelloWorld < Base
      on(
        /hello/i,
        name: "hello", # method name
        description: "Hello world!" # help description
      )

      def hello(message)
        message.reply("Hello world!")
      end
    end

    class Echo < Base
      on(
        /echo (.*)/i,
        name: "echo",
        description: "Echo your message."
      )

      def echo(message)
        message.reply("#{message[1]}")
      end
    end
  end
end
