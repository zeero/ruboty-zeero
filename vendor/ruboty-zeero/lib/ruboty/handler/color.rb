module Ruboty
  module Handlers
    class Color < Base
      @@colors = YAML.load_file(File.expand_path('../../../../resources/colors.yaml', __FILE__))

      on(
        /color +(?<color_name>[a-z]+)/i,
        name: "color",
        description: "指定された色のRGB表現を返す。"
      )

      def color(msg)
        msg.reply("#{msg[1]}は #{@@colors[msg[:color_name]]} です")
      end


      on(
        /colors$/i,
        name: "colors",
        description: "定義されているすべての色のRGB表現を返す。"
      )

      def colors(msg)
        colors = @@colors.map { |color, rgb| "#{color}: #{rgb}" }.join("\n")
        msg.reply(colors)
      end
    end
  end
end
