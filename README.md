BIEN API
========

## Authentication

An API key is required for all routes. API keys can be requested from XXXX. Keys (aka tokens) are passed in a header like:

```
Authorization: token <your token>
```

Or as a curl request:

```
curl -H "Authorization: foobar" http://localhost:8876/list
```

send Scott an email (scott@ropensci.org) about the API key if you want access

## API Routes

* `/` base route - a pretty landing page with info
* `/heartbeat/` list all routes

### `occurrence` routes

* `/occurrence/species/` Extract occurrence data for specified species from BIEN
* `/occurrence/genus/` Extract occurrence data for specified genus from BIEN
* `/occurrence/family/` Extract occurrence data for specified family from BIEN
* `/occurrence/spatial/` Extract occurrence data for specified polygons (WKT) or bounding box
* `/occurrence/state/` Extract occurrence data for a state
* `/occurrence/county/` Extract occurrence data for a county
* `/occurrence/country/` Extract occurrence data for a country
* `/occurrence/count/` Count the number of (geoValid) occurrence records for each species in BIEN


### species `list` routes

* `/list/` Extract species list
* `/list/county/` Extract species list by county
* `/list/country/` Extract species list by country
* `/list/state/` Extract a species list by state/province
* `/list/spatial/` Extract a list of species within a given WKT

examples:

```
curl 'http://129.114.111.129:8876/list/country?country=Canada'
curl 'http://129.114.111.129:8876/list?country=Canada'
```

### `meta` routes

* `/meta/version/` Get current BIEN database version and release date
* `/meta/citations/` Get citations for BIEN data

### `phylogeny` routes

* `/phylogeny/` Download the complete or conservative BIEN phylogeny

### `plot` routes

* `/plot/country/` Get plot data from specified countries
* `/plot/dataset/` Get plot data by dataset name
* `/plot/datasources/` List available data sources
* `/plot/datasources/<protocol name>` Get plot data by data source name
* `/plot/protocols/` List available sampling protocols
* `/plot/protocols/<protocol name>` Get plot data by protocol name
* `/plot/metadata/` Get all plot metadata
* `/plot/name/` Get plot data by plot name
* `/plot/state/` Get plot data from specified states/provinces

examples:

```
curl 'http://129.114.111.129:8876/plot/metadata'
curl 'http://129.114.111.129:8876/plot/protocols'
```

### `ranges` routes

* `/ranges/genus/` Get range maps for a genus
* `/ranges/list/` List available range maps
* `/ranges/spatial/` Get range maps that intersect a WKT polygon or bounding box
* `/ranges/species/` Get range maps for a species
* `/ranges/species/intersect/` Get range maps that intersect the range of a species

### `stem` routes

* `/stem/datasource/` Get stem data for a datasource
* `/stem/family/` Get stem data for a family
* `/stem/genus/` Get stem data for a genus
* `/stem/species/` Get stem data for a species

### `taxonomy` routes

* `/taxonomy/family/` Extract taxonomic information for families
* `/taxonomy/genus/` Extract taxonomic information for genera
* `/taxonomy/species/` Extract taxonomic information for species

examples:

```
curl 'http://129.114.111.129:8876/taxonomy/species?species=Cannabis%20sativa'
```

### `trait` routes

* `/traits/` List all available types of trait data
* `/traits/family/` Extract all trait data for given families
* `/traits/family/<trait>` Extract specific trait data for given families
* `/traits/genus/` Extract all trait data for given genera
* `/traits/genus/<trait>` Extract specific trait data for given genera
* `/traits/species/` Extract all trait data for given species
* `/traits/species/<trait>` Extract specific trait data for given species
* `/traits/trait/` Extract all measurements for a trait
* `/traits/count/` Count the number of trait observations for each species in the BIEN database

Note: `mean` removed since that's done client side.

examples:

```
curl 'http://129.114.111.129:8876/traits/'
curl 'http://129.114.111.129:8876/traits/family/?family=Poaceae'
```
