require 'test_helper'

class Ruboty::ZeeroTest < Minitest::Test
  def setup
    @robot = MockRobot.new
    @message = MockMessage.new
  end

  def test_that_it_has_a_version_number
    refute_nil ::Ruboty::Zeero::VERSION
  end

  def test_it_does_something_useful
    hello = Ruboty::Handlers::HelloWorld.new(@robot)
    assert_equal hello.hello(@message), "Hello world!"
  end
end

