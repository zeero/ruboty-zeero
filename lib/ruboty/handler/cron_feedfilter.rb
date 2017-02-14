module Ruboty
  module Handlers
    class CronFeedFilter < Base
      on(
        /feedfilter(?: +(?<YYYYMMDD>[0-9]{1,8}))?$/i,
        name: "feedfilter",
        description: "登録したfeedの新着情報をチェックする。"
      )

      def initialize(robot)
        super
        @thread = Thread.new {
          schedule = "0 * * * *"
          Chrono::Trigger.new(schedule) {
            data = robot.brain.data[Ruboty::Handlers::Feed::BRAIN_KEY] || {}
            data.each_with_index do |feed, index|
              msg = Message.new(robot: robot)
              attributes = {
                to: "general@conference.zeero.xmpp.slack.com/zeero",
                type: "groupchat",
                body: feed_filter(feed, feed[:check_date]),
                original: msg.original
              }
              robot.say(attributes)
              robot.brain.data[Ruboty::Handlers::Feed::BRAIN_KEY][index][:check_date] = Time.now
            end
          }.run
        }
      end

      def feedfilter(msg)
        data = robot.brain.data[Ruboty::Handlers::Feed::BRAIN_KEY] || {}
        data.each_with_index do |feed, index|
          check_date = msg[:YYYYMMDD] ? Date.strptime(msg[:YYYYMMDD], "%Y%m%d") : feed[:check_date]
          msg.reply(feed_filter(feed, check_date))
          robot.brain.data[Ruboty::Handlers::Feed::BRAIN_KEY][index][:check_date] = Time.now
        end
      end

      private

      def feed_filter(feed, check_date)
        replies = []
        items = get_new_items(feed, check_date)
        if ! items.empty?
          replies << "【Feed】#{feed[:title]}"
          replies.concat(items.map { |item| "#{item.link}"})
        end
        return replies.join("\n")
      end

      def get_new_items(feed, check_date)
        # p feed[:url]
        rss = RSS::Parser.parse(feed[:url], false)
        keyword = feed[:keyword]
        keyword_type = feed[:keyword_type]

        results = []
        rss.items.each do |item|
          dc_date = item.dc_date rescue nil
          dc_date ||= item.pubDate rescue nil
          dc_date ||= item.published.content rescue nil
          next if ! dc_date
          # p dc_date

          if dc_date > check_date
            results << item if ! keyword || has_keyword?(item, keyword, keyword_type)
          else
            next
          end
        end

        return results
      end

      def has_keyword?(item, keyword, keyword_type)
        title = ""
        description = ""
        if item.instance_of? RSS::Atom::Feed::Entry
          title = item.title.content
          description = item.summary.content
        else
          title = item.title
          description = item.description
        end

        target = ""
        case keyword_type
        when "0"
          target = "#{title}\n#{description}"
        when "1"
          target = title
        when "2"
          target = description
        end

        keyword.split(",").each do |keyword|
          return true if target.match keyword
        end

        return false
      end
    end
  end
end

