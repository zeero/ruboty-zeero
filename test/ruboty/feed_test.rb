require 'test_helper'

describe Ruboty::Handlers::Feed do
  before do
    @robot = Ruboty::Robot.new
    @message = MockMessage.new
  end

  describe "list" do
    it "登録がなかったらエラーメッセージを表示する" do
      feed = Ruboty::Handlers::Feed.new(@robot)
      assert_equal feed.list(@message), "登録済みのfeedはありません"
    end
  end

end

