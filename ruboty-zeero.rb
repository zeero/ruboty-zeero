require 'ruboty-zeero-cron'

module Ruboty
  module Handlers
    require 'yaml'

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

    class Color < Base
      @@colors = YAML.load_file(File.expand_path('../resources/colors.yaml', __FILE__))

      on(
        /color ([a-z]+)/,
        name: "color",
        description: "Reply RGB color."
      )

      def color(msg)
        msg.reply("#{msg[1]}は #{@@colors[msg[1]]} です")
      end


      on(
        /colors$/,
        name: "colors",
        description: "Reply all RGB colors."
      )

      def colors(msg)
        colors = @@colors.map { |color, rgb| "#{color}: #{rgb}" }.join("\n")
        msg.reply(colors)
      end
    end
  end
end
