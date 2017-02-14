module Ruboty
  module Handlers
    class Calc < Base
      on(
        /calc +(?<expr>[0-9 \+\-\*\/\%\^\(\)]+)/i,
        name: "calc",
        description: "四則演算をします。使える演算子は+-*/%^です。"
      )

      def calc(msg)
        expr = msg[:expr].gsub(/\^/, "**")
        begin
          result = eval(expr)
        rescue Exception => exc
          msg.reply("#{expr} の計算はできません")
          return
        end
        msg.reply(result)
      end
    end
  end
end
