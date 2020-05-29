# frozen_string_literal: true

require 'test/unit'
require_relative 'test-helper'

class TestPlot < Test::Unit::TestCase

  def test_plot_metadata
    res = $bien_conn_auth.get '/plot/metadata'
    x = MultiJson.load(res.body)

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_instance_of(Integer, x["count"])
    assert_equal(10, x["returned"])
    assert_instance_of(Array, x["data"])
    assert_true(x["error"].nil?)
  end

  def test_plot_protocols
    res = $bien_conn_auth.get '/plot/protocols'
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_equal(1, x["count"]) # FIXME: this can't be right
    assert_equal(9, x["returned"])
    assert_instance_of(Array, x["data"])
    assert_true(x["error"].nil?)
  end

end
