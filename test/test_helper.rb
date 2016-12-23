require 'minitest/autorun'

require 'ruboty'

require 'ruboty/zeero'

class MockRobot
end

class MockMessage
  def reply(msg)
    msg
  end
end
