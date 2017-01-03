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
      @@logger = Logger.new($stdout)

      on(
        /p2q ([0-9]+)/,
        name: "p2q",
        description: "Pocketに登録したQiitaの記事をストックする"
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
        since = msg ? Date.strptime(msg[1], "%Y%m%d") : Date.today - 1
        json = fetch_pocket(since.to_time.to_i)
        qids = filter_qiita(json)
        msg = stock_qiita(qids)
        return msg
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
            @@logger.info "Pocket API: json=#{json}" if $DEBUG
            return json
          when Net::HTTPRedirection
            @@logger.warn "HTTP Redicect: code=#{res.code} message=#{res.message}"
          else
            @@logger.error "HTTP Error: code=#{res.code} message=#{res.message}"
          end
        rescue => e
          @@logger.error e.message
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
          @@logger.info "Qiita API: status=#{result.status} body=#{result.body}" if $DEBUG
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
  end
end

