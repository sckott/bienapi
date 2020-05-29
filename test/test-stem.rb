# frozen_string_literal: true

require 'test/unit'
require_relative 'test-helper'

class TestStem < Test::Unit::TestCase

  def test_stem_species
    res = $bien_conn_auth.get '/stem/species', {:species=>"Abies amabilis"};
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_equal("Abies amabilis", x["data"][0]["scrubbed_species_binomial"])
    assert_instance_of(Integer, x["count"])
    assert_equal(10, x["returned"])
    assert_instance_of(Array, x["data"])
    assert_true(x["error"].nil?)

    res2 = $bien_conn_auth.get '/stem/species', {:xxx=>"Quercus"};
    x = MultiJson.load(res2.body);
    assert_equal(400, res2.status)
    assert_equal("must pass \"species\" parameter", x["error"]["message"])
  end

  def test_stem_genus
    # res = $bien_conn_auth.get '/stem/genus', {:genus=>"Abies"};
    # x = MultiJson.load(res.body);

    # assert_instance_of(Faraday::Response, res)
    # assert_equal(200, res.status)
    # assert_instance_of(String, res.body)
    # assert_instance_of(Hash, x)
    # assert_equal(["count", "returned", "data", "error"], x.keys)
    # assert_instance_of(Integer, x["count"])
    # assert_true(x["returned"] > 20)
    # assert_equal(["genus", "gid", "st_astext"], x["data"][0].keys)
    # assert_true(x["error"].nil?)

    res2 = $bien_conn_auth.get '/stem/genus', {:species=>"Quercus"};
    x = MultiJson.load(res2.body);
    assert_equal(400, res2.status)
    assert_equal("must pass \"genus\" parameter", x["error"]["message"])
  end

  def test_stem_family
    res = $bien_conn_auth.get '/stem/family', {:family=>"Marantaceae"};
    x = MultiJson.load(res.body);
    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_instance_of(Integer, x["count"])
    assert_equal(10, x["returned"])
    assert_equal("Marantaceae", x["data"][0]["scrubbed_family"])
    assert_true(x["error"].nil?)
  end

end
