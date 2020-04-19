require 'minitest/autorun'
require 'minitest/stub_any_instance'

require 'ruboty'

require 'ruboty/zeero'

class MockRobot
end

class MockMessage
  def reply(msg)
    msg
  end

  def []
  end
end
