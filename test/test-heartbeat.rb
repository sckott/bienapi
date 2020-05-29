# frozen_string_literal: true

require 'test/unit'
require_relative 'test-helper'

class TestHeartbeat < Test::Unit::TestCase

  def test_heartbeat
    res = $bien_conn.get '/heartbeat'

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
  end

end
