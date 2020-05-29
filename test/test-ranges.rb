# frozen_string_literal: true

require 'test/unit'
require_relative 'test-helper'

class TestRanges < Test::Unit::TestCase

  def test_ranges
    res = $bien_conn_auth.get '/ranges/list';
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    # assert_equal(["count", "retur
    assert_instance_of(Integer, x["count"])
    assert_equal(10, x["returned"])
    assert_instance_of(Array, x["data"])
    assert_true(x["error"].nil?)
  end

  def test_ranges_species
    res = $bien_conn_auth.get '/ranges/species', {:species=>"Abies lasiocarpa"};
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_instance_of(Integer, x["count"])
    assert_equal(1, x["returned"])
    assert_instance_of(Array, x["data"])
    assert_true(x["error"].nil?)

    res2 = $bien_conn_auth.get '/ranges/species', {:species=>"Abies lasiocarpa", :match_names_only=>true};
    x = MultiJson.load(res2.body);

    assert_instance_of(Faraday::Response, res2)
    assert_equal(200, res2.status)
    assert_equal(1, x["returned"])
    assert_equal(["species", "gid"], x["data"][0].keys)

    res3 = $bien_conn_auth.get '/ranges/species', {:xxx=>"Quercus"};
    x = MultiJson.load(res3.body);
    assert_equal(400, res3.status)
    assert_equal("must pass \"species\" parameter", x["error"]["message"])
  end

  def test_ranges_genus
    res = $bien_conn_auth.get '/ranges/genus', {:genus=>"Abies"};
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_instance_of(Integer, x["count"])
    assert_true(x["returned"] > 20)
    assert_equal(["species", "gid", "st_astext"], x["data"][0].keys)
    assert_true(x["error"].nil?)

    res2 = $bien_conn_auth.get '/ranges/genus', {:genus=>"Quercus", :match_names_only=>true};
    x = MultiJson.load(res2.body);

    assert_instance_of(Faraday::Response, res2)
    assert_equal(200, res2.status)
    assert_true(x["returned"] > 200)
    assert_equal(["species", "gid"], x["data"][0].keys)

    res2 = $bien_conn_auth.get '/ranges/genus', {:speices=>"Quercus"};
    x = MultiJson.load(res2.body);
    assert_equal(400, res2.status)
    assert_equal("must pass \"genus\" parameter", x["error"]["message"])
  end

  # def test_ranges_spatial
  #   res = $bien_conn_auth.get '/ranges/spatial', {:wkt=>"POLYGON((-114.03 34.54,-112.67 34.54,-112.67 33.19,-114.03 33.19,-114.03 34.54))"};
  #   x = MultiJson.load(res.body);
  #   assert_instance_of(Faraday::Response, res)
  #   assert_equal(200, res.status)
  #   assert_instance_of(String, res.body)
  #   assert_instance_of(Hash, x)
  #   assert_equal(["count", "returned", "data", "error"], x.keys)
  #   assert_instance_of(Integer, x["count"])
  #   assert_true(x["returned"] > 20)
  #   assert_equal(["species", "gid", "st_astext"], x["data"][0].keys)
  #   assert_true(x["error"].nil?)
  # end

end
