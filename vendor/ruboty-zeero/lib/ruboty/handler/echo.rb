module Ruboty
  module Handlers
    class Echo < Base
      on(
        /echo +(?<message>.*)/i,
        name: "echo",
        description: "メッセージをそのままエコーする。"
      )

      def echo(message)
        message.reply("#{message[:message]}")
      end
    end
  end
end
