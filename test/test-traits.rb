# frozen_string_literal: true

require 'test/unit'
require_relative 'test-helper'

class TestTraits < Test::Unit::TestCase

  def test_traits
    res = $bien_conn_auth.get '/traits';
    x = MultiJson.load(res.body);

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

  # FIXME: hangs, not sure why
  # def test_traits_family
  #   res = $bien_conn_auth.get '/traits/family', {:family=>"Poaceae"};
  #   x = MultiJson.load(res.body);

  #   assert_instance_of(Faraday::Response, res)
  #   assert_equal(200, res.status)
  #   assert_instance_of(String, res.body)
  #   assert_instance_of(Hash, x)
  #   assert_equal(["count", "returned", "data", "error"], x.keys)
  #   assert_equal(1, x["count"]) # FIXME: this can't be right
  #   assert_equal(9, x["returned"])
  #   assert_instance_of(Array, x["data"])
  #   assert_true(x["error"].nil?)
  # end

  def test_traits_family_id
    res = $bien_conn_auth.get '/traits/family/5194345';
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_equal(1, x["count"])
    assert_equal(1, x["returned"])
    assert_instance_of(Array, x["data"])
    assert_true(x["error"].nil?)
  end

end
