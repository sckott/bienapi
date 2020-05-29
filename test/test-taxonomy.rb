# frozen_string_literal: true

require 'test/unit'
require_relative 'test-helper'

class TestTaxonomy < Test::Unit::TestCase

  def test_taxonomy_species
    res = $bien_conn_auth.get '/taxonomy/species', {:species => "Poa annua"};
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_instance_of(Integer, x["count"])
    assert_instance_of(Integer, x["returned"])
    assert_instance_of(Array, x["data"])
    assert_true(x["error"].nil?)
  end

  def test_taxonomy_genus
    res = $bien_conn_auth.get '/taxonomy/genus', {:genus => "Carnegiea"};
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_instance_of(Integer, x["count"])
    assert_instance_of(Integer, x["returned"])
    assert_instance_of(Array, x["data"])
    assert_true(x["error"].nil?)
  end

  def test_taxonomy_family
    res = $bien_conn_auth.get '/taxonomy/family', {:family => "Cactaceae"};
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_instance_of(Integer, x["count"])
    assert_instance_of(Integer, x["returned"])
    assert_instance_of(Array, x["data"])
    assert_true(x["error"].nil?)
  end

end
