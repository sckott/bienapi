# frozen_string_literal: true

require 'test/unit'
require_relative 'test-helper'

class TestRoot < Test::Unit::TestCase

  def test_root
    res = $bien_conn.get '/'

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_match("DOCTYPE", res.body)
  end

end
