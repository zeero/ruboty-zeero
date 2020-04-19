require 'test_helper'

describe Ruboty::Zeero do
  before do
    @robot = MockRobot.new
    @message = MockMessage.new
  end

  it "バージョン番号をもつ" do
    refute_nil ::Ruboty::Zeero::VERSION
  end

  describe "HelloWorld" do
    it "Hello world!を返す" do
      hello = Ruboty::Handlers::HelloWorld.new(@robot)
      assert_equal hello.hello(@message), "Hello world!"
    end
  end

  describe "Echo" do
    it "メッセージをそのまま返す" do
      echo = Ruboty::Handlers::Echo.new(@robot)
      MockMessage.stub_any_instance("[]", "test") do
        assert_equal echo.echo(@message), "test"
      end
    end
  end
end

