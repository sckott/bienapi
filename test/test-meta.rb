# frozen_string_literal: true

require 'test/unit'
require_relative 'test-helper'

class TestMeta < Test::Unit::TestCase

  def test_meta_version
    res = $bien_conn_auth.get '/meta/version'
    x = MultiJson.load(res.body)

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["data", "error"], x.keys)
    assert_instance_of(String, x["data"][0]["db_version"])
    assert_instance_of(String, x["data"][0]["db_release_date"])
    assert_true(x["error"].nil?)
  end

  def test_meta_politicalnames
    res = $bien_conn_auth.get '/meta/politicalnames'
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_true(x["count"] > 1000)
    assert_equal(10, x["returned"])
    assert_instance_of(Array, x["data"])
    assert_equal(["county_parish_id", "country", "state_province",
        "state_province_ascii", "country.code", "state.code"], x["data"][0].keys)
    assert_true(x["error"].nil?)
  end

end
