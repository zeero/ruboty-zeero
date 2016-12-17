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
  end
end
