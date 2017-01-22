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
        /echo +(?<message>.*)/i,
        name: "echo",
        description: "メッセージをそのままエコーする。"
      )

      def echo(message)
        message.reply("#{message[:message]}")
      end
    end


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


    class Mahjong < Base
      @@table = {
        "20" => [nil, "ツモアガリ(400/700)", "ツモアガリ(700/1300)", "ツモアガリ(1300/2600)"],
        "25" => [nil, "1600", "3200(800/1600)", "6400(1600/3200)"],
        "30" => ["1000(300/500)", "2000(500/1000)", "3900(1000/2000)", "7700(2000/3900)"],
        "40" => ["1300(400/700)", "2600(700/1300)", "5200(1300/2600)", "8000(2000/4000)"],
        "50" => ["1600(400/800)", "3200(800/1600)", "6400(1600/3200)", "8000(2000/4000)"],
        "60" => ["2000(500/1000)", "3900(1000/2000)", "7700(2000/3900)", "8000(2000/4000)"],
        "70" => ["2300(600/1200)", "4500(1200/2300)", "8000(2000/4000)", "8000(2000/4000)"],
        "80" => ["2600(700/1300)", "5200(1300/2600)", "8000(2000/4000)", "8000(2000/4000)"],
        "90" => ["2900(800/1500)", "5800(1500/2900)", "8000(2000/4000)", "8000(2000/4000)"],
        "100" => ["3200(800/1600)", "6400(1600/3200)", "8000(2000/4000)", "8000(2000/4000)"],
        "110" => ["3600(900/1800)", "7100(1800/3600)", "8000(2000/4000)", "8000(2000/4000)"],
      }

      on(
        /mj +(?<fu>[0-9]{1,3})((符|-| +)(?<han>[0-9])翻?)?/i,
        name: "mahjong",
        description: "麻雀の点数計算をします。"
      )

      def mahjong(msg)
        fu = msg[:fu]
        han = msg[:han] || "1"
        point = @@table[fu] ? @@table[fu][han.to_i - 1] : nil
        if point
          msg.reply("#{fu}符#{han}翻の点数は、#{point}です")
        else
          msg.reply("#{fu}符#{han}翻の点数は、わかりません")
        end
      end
    end


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


    class Feed < Base
      BRAIN_KEY = "ruboty_zeero_feed"

      on(/feed$/i, name: "help", description: "feedのヘルプを表示します。")
      on(/feed +list$/i, name: "list", description: "feedの一覧を表示します。")
      on(
        /feed +add +(?<url>http\S+)(?: +(?<keyword>\S+))?(?: +(?<keyword_type>[0-2]))?/i,
        name: "add",
        description: "feedを登録します。（keywordはカンマ区切り）（keyword_type=0:タイトルと本文（デフォルト）, 1:タイトル, 2:本文）"
      )
      on(/feed +del +#(?<id>[0-9]+)/i, name: "del", description: "feedを削除します。")

      def help(msg)
        new_msg = Message.new({:body => "help feed", :from => msg.from, :robot => msg.robot})
        new_msg.match(/help( me)?(?: (?<filter>.+))?\z/i)
        Ruboty::Actions::Help.new(new_msg).call
      end

      def list(msg)
        data = robot.brain.data[BRAIN_KEY] || {}
        if ! data.empty?
          # TODO
          msg.reply "登録済みのfeed：\n#{data.to_yaml}"
        else
          msg.reply "登録済みのfeedはありません"
        end
      end

      def add(msg)
        url = msg[:url]
        keyword = msg[:keyword]
        keyword_type = msg[:keyword_type] || "0"
        feed = {url: url, keyword: keyword, keyword_type: keyword_type, check_date: Time.now}

        # check valid feed
        rss = nil
        begin
          rss = RSS::Parser.parse(url, false)
        rescue
        end
        if rss
          if rss.instance_of? RSS::Atom::Feed
            feed.merge!({title: rss.title.content})
          else
            feed.merge!({title: rss.channel.title})
          end
        else
          return msg.reply "#{url} はRSSではありません"
        end

        data = robot.brain.data[BRAIN_KEY] || []
        index = data.size
        robot.brain.data[BRAIN_KEY] = data.push(feed)
        msg.reply "#{url} を登録しました（##{index}）"
      end

      def del(msg)
        id = msg[:id].to_i
        data = robot.brain.data[BRAIN_KEY] || []
        if id < data.size
          feed = data.delete_at id
          robot.brain.data[BRAIN_KEY] = data
          msg.reply "\##{id} を削除しました"
        else
          msg.reply "\##{id} はありません"
        end
      end
    end


  end
end
