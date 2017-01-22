require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'logger'

require 'chrono'
require 'qiita'

module Ruboty
  module Handlers
    class CronP2Q < Base
      on(
        /p2q (?<yyyymmdd>[0-9]+)/i,
        name: "p2q",
        description: "Pocketに登録したQiitaの記事をストックする。"
      )

      def initialize(robot)
        super
        @thread = Thread.new {
          schedule = ! $DEBUG ? "0 0 * * *" : "* * * * *"
          Chrono::Trigger.new(schedule) {
            msg = Message.new(robot: robot)
            attributes = {
              to: "log@conference.zeero.xmpp.slack.com/zeero",
              type: "groupchat",
              body: p2q,
              original: msg.original
            }
            robot.say(attributes)
          }.run
        }
      end

      def p2q(msg = nil)
        since = msg ? Date.strptime(msg[:yyyymmdd], "%Y%m%d") : Date.today - 1
        json = fetch_pocket(since.to_time.to_i)
        qids = filter_qiita(json)
        reply = stock_qiita(qids)
        return Ruboty::Message === msg ? msg.reply(reply) : reply
      end

      def fetch_pocket(since)
        # header
        headers = {
          "Content-type" => "application/x-www-form-urlencoded; charset=utf8",
        }

        # body
        body = URI.encode_www_form({
          consumer_key: ENV["RUBOTY_POCKET_CONSUMER_KEY"],
          access_token: ENV["RUBOTY_POCKET_TOKEN"],
          since: String(since),
          search: 'qiita.com',
          sort: 'oldest',
          count: "1",
        })

        # post
        uri = URI.parse("https://getpocket.com/v3/get")
        begin
          http = Net::HTTP.new(uri.host, uri.port)
          http.set_debug_output $stderr if $DEBUG
          # SSL
          http.use_ssl = true
          # 接続タイムアウト
          http.open_timeout = 5
          # 読込タイムアウト
          http.read_timeout = 10

          # 実行
          res = http.post(uri.path, body, headers)

          # 結果取得
          case res
          when Net::HTTPSuccess
            json = JSON.parse(res.body)
            Ruboty::Zeero.logger.info "Pocket API: json=#{json}" if $DEBUG
            return json
          when Net::HTTPRedirection
            Ruboty::Zeero.logger.warn "HTTP Redicect: code=#{res.code} message=#{res.message}"
          else
            Ruboty::Zeero.logger.error "HTTP Error: code=#{res.code} message=#{res.message}"
          end
        rescue => e
          Ruboty::Zeero.logger.error e.message
        end
      end

      def filter_qiita(json)
        map = {}
        json["list"].each do |pid, pitem|
          given_url = pitem["given_url"]
          qid = given_url ? given_url.match(/\/\/qiita\.com\/.+\/items\/(.+)$/) : nil
          if qid
            map[qid[1]] = pitem["resolved_title"]
          end
        end
        return map
      end

      def stock_qiita(qids)
        client = Qiita::Client.new(access_token: ENV["RUBOTY_QIITA_TOKEN"])
        qids.each do |qid, qtitle|
          result = client.stock_item qid
          Ruboty::Zeero.logger.info "Qiita API: status=#{result.status} body=#{result.body}" if $DEBUG
        end
        msg = "【P2Q】"
        case qids.count
        when 0
          msg += "ストック対象はありません"
        when 1
          msg += "「#{qids.first[1]}」をストックしました"
        else
          msg += "「#{qids.first[1]}」他、#{qids.count}個の記事をストックしました"
        end
        return msg
      end
    end


    class CronF2P < Base
      on(
        /f2p (?<yyyymmdd>[0-9]+)/i,
        name: "f2p",
        description: "FourSquareに登録したurlをPocketに登録する。"
      )

      def initialize(robot)
        super
        @thread = Thread.new {
          schedule = ! $DEBUG ? "0 0 * * *" : "* * * * *"
          Chrono::Trigger.new(schedule) {
            msg = Message.new(robot: robot)
            attributes = {
              to: "log@conference.zeero.xmpp.slack.com/zeero",
              type: "groupchat",
              body: f2p,
              original: msg.original
            }
            robot.say(attributes)
          }.run
        }
      end

      def f2p(msg = nil)
        since = msg ? Date.strptime(msg[:yyyymmdd], "%Y%m%d") : Date.today - 1
        json = fetch_4sq
        urls = filter_recent(json, since.to_time.to_i)
        reply = post_pocket(urls)
        return Ruboty::Message === msg ? msg.reply(reply) : reply
      end

      def fetch_4sq
        # header
        headers = {
          "Content-type" => "application/x-www-form-urlencoded; charset=utf8",
        }

        # body
        params = {
          oauth_token: ENV["RUBOTY_4SQ_TOKEN"],
          sort: "recent",
          v: "20170101",
        }
        params.merge!({limit: "1"}) if $DEBUG
        body = URI.encode_www_form(params)

        # post
        uri = URI.parse("https://api.foursquare.com/v2/lists/self/todos")
        begin
          http = Net::HTTP.new(uri.host, uri.port)
          http.set_debug_output $stderr if $DEBUG
          # SSL
          http.use_ssl = true
          # 接続タイムアウト
          http.open_timeout = 5
          # 読込タイムアウト
          http.read_timeout = 10

          # 実行
          res = http.get("#{uri.path}?#{body}")

          # 結果取得
          case res
          when Net::HTTPSuccess
            json = JSON.parse(res.body)
            Ruboty::Zeero.logger.info "Pocket API: json=#{json}" if $DEBUG
            return json
          when Net::HTTPRedirection
            Ruboty::Zeero.logger.warn "HTTP Redicect: code=#{res.code} message=#{res.message}"
          else
            Ruboty::Zeero.logger.error "HTTP Error: code=#{res.code} message=#{res.message}"
          end
        rescue => e
          Ruboty::Zeero.logger.error e.message
        end
      end

      def filter_recent(json, since)
        map = {}
        json["response"]["list"]["listItems"]["items"].each do |fitem|
          if since < fitem["sharedAt"]
            name = fitem["venue"]["name"]
            url = fitem["venue"]["url"]
            url ||= "https://ja.foursquare.com/v/#{fitem["venue"]["id"]}"
            map[url] = name
          end
        end
        return map
      end

      def post_pocket(urls)
        # header
        headers = {
          "Content-type" => "application/x-www-form-urlencoded; charset=utf8",
        }

        # body
        params = {
          consumer_key: ENV["RUBOTY_POCKET_CONSUMER_KEY"],
          access_token: ENV["RUBOTY_POCKET_TOKEN"],
          tags: "4sq",
        }

        # post
        uri = URI.parse("https://getpocket.com/v3/add")
        begin
          http = Net::HTTP.new(uri.host, uri.port)
          http.set_debug_output $stderr if $DEBUG
          # SSL
          http.use_ssl = true
          # 接続タイムアウト
          http.open_timeout = 5
          # 読込タイムアウト
          http.read_timeout = 10

          # 実行
          count = 0
          last_name = ""
          urls.each do |url, name|
            params.merge!({url: url})
            res = http.post(uri.path, URI.encode_www_form(params), headers)

            # 結果取得
            case res
            when Net::HTTPSuccess
              json = JSON.parse(res.body)
              Ruboty::Zeero.logger.info "Pocket API: json=#{json}" if $DEBUG
              count += 1
              last_name = name
            when Net::HTTPRedirection
              Ruboty::Zeero.logger.warn "HTTP Redicect: code=#{res.code} message=#{res.message}"
            else
              Ruboty::Zeero.logger.error "HTTP Error: code=#{res.code} message=#{res.message}"
            end
          end
        rescue => e
          Ruboty::Zeero.logger.error e.message
        end

        msg = "【F2P】"
        case count
        when 0
          msg += "登録対象はありません"
        when 1
          msg += "「#{last_name}」を登録しました"
        else
          msg += "「#{last_name}」他、#{count}個のurlを登録しました"
        end
        return msg
      end
    end


    class FeedFilter < Base
      on(
        /feedfilter$/i,
        name: "feed_filter",
        description: "登録したfeedの新着情報をチェックする。"
      )

      def initialize(robot)
        super
        @thread = Thread.new {
          schedule = ! $DEBUG ? "0 * * * *" : "* * * * *"
          Chrono::Trigger.new(schedule) {
            msg = Message.new(robot: robot)
            attributes = {
              to: "general@conference.zeero.xmpp.slack.com/zeero",
              type: "groupchat",
              body: feed_filter,
              original: msg.original
            }
            robot.say(attributes)
          }.run
        }
      end

      def feed_filter(msg = nil)
        data = robot.brain.data[Ruboty::Handlers::Feed::BRAIN_KEY] || {}
        replies = []
        data.each_with_index do |feed, index|
          items = get_new_items(feed)
          if ! items.empty?
            replies << "【Feed】#{feed.title}"
            replies.concat(items.map { |item| "#{item.link}"})
          end
          robot.brain.data[Ruboty::Handlers::Feed::BRAIN_KEY][index][:check_date] = Time.now
        end
        reply = replies.join("\n")
        return Ruboty::Message === msg ? msg.reply(reply) : reply
      end

      private

      def get_new_items(feed)
        rss = RSS::Parser.parse(feed[:url])
        keyword = feed[:keyword]
        keyword_type = feed[:keyword_type]

        results = []
        rss.items.each do |item|
          dc_date = item.dc_date rescue Error
          dc_date ||= item.pubDate rescue Error
          break if ! dc_date

          if dc_date > feed[:check_date]
            results << item if ! keyword || has_keyword?(item, keyword, keyword_type)
          else
            break
          end
        end

        return results
      end

      def has_keyword?(item, keyword, keyword_type)
        target = ""
        case keyword_type
        when "0"
          target = "#{item.title}\n#{item.description}"
        when "1"
          target = item.title
        when "2"
          target = item.description
        end

        keyword.split(",").each do |keyword|
          return true if target.match keyword
        end

        return false
      end
    end


  end
end

