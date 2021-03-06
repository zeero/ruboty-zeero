module Ruboty
  module Handlers
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
  end
end

