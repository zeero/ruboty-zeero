module Ruboty
  module Handlers
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
