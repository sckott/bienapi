# frozen_string_literal: true

require 'test/unit'
require_relative 'test-helper'

class TestList < Test::Unit::TestCase

  def test_list
    res = $bien_conn_auth.get '/list'
    x = MultiJson.load(res.body)

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
  end

  def test_list_country
    res = $bien_conn_auth.get '/list/country', {:country=>"Canada"}
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_equal(1, x["count"]) # FIXME: this can't be right
    assert_equal(10, x["returned"])
    assert_instance_of(Array, x["data"])
    assert_true(x["error"].nil?)
  end

end
