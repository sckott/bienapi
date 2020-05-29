# frozen_string_literal: true

require 'test/unit'
require_relative 'test-helper'

class TestPhylogeny < Test::Unit::TestCase

  def test_phylogeny
    res = $bien_conn_auth.get '/phylogeny';
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_instance_of(Array, x["data"])
    assert_equal(
        ["phylogeny_id", "phylogeny_version",
            "replicate", "filename", "citation", "phylogeny"], x["data"][0].keys)
    assert_match("conservative", x["data"][0]["phylogeny_version"])
    assert_true(x["error"].nil?)
  end

  def test_phylogeny_type_parameter
    res = $bien_conn_auth.get '/phylogeny', {:type=>"complete"};
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["count", "returned", "data", "error"], x.keys)
    assert_instance_of(Array, x["data"])
    assert_equal(
        ["phylogeny_id", "phylogeny_version",
            "replicate", "filename", "citation", "phylogeny"], x["data"][0].keys)
    assert_match("complete", x["data"][0]["phylogeny_version"])
    assert_true(x["error"].nil?)
  end

end
