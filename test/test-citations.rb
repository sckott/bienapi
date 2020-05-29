# frozen_string_literal: true

require 'test/unit'
require_relative 'test-helper'

class TestCitations < Test::Unit::TestCase

  def test_citations_traits
    res = $bien_conn_auth.get '/meta/citations/traits/20024404/';
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["data", "error"], x.keys)
    assert_instance_of(Array, x["data"])
    assert_instance_of(Hash, x["data"][0])
    assert_instance_of(String, x["data"][0]['citation_bibtex'])
    assert_true(x["error"].nil?)
  end

  def test_citations_occurrences
    res = $bien_conn_auth.get '/meta/citations/occurrence/22';
    x = MultiJson.load(res.body);

    assert_instance_of(Faraday::Response, res)
    assert_equal(200, res.status)
    assert_instance_of(String, res.body)
    assert_instance_of(Hash, x)
    assert_equal(["data", "error"], x.keys)
    assert_instance_of(Array, x["data"])
    assert_instance_of(Hash, x["data"][0])
    assert_instance_of(String, x["data"][1]['source_citation'])
    assert_true(x["error"].nil?)
  end

end
