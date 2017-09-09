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

Those checked off have been implemented:

- [x] `/` base route - a pretty landing page with info
- [x] `/heartbeat/` list all routes

### `occurrence` routes

- [ ] `/occurrence/species/` Extract occurrence data for specified species from BIEN (~ `BIEN::BIEN_occurrence_species`)
- [ ] `/occurrence/genus/` Extract occurrence data for specified genus from BIEN (~ `BIEN::BIEN_occurrence_genus`)
- [ ] `/occurrence/family/` Extract occurrence data for specified family from BIEN (~ `BIEN::BIEN_occurrence_family`)
- [ ] `/occurrence/spatial/` Extract occurrence data for specified polygons (WKT) or bounding box (~ `BIEN::BIEN_occurrence_spatialpolygons`)
- [ ] `/occurrence/state/` Extract occurrence data for a state (~ `BIEN::BIEN_occurrence_state`)
- [ ] `/occurrence/county/` Extract occurrence data for a county (~ `BIEN::BIEN_occurrence_county`)
- [ ] `/occurrence/country/` Extract occurrence data for a country (~ `BIEN::BIEN_occurrence_country`)
- [ ] `/occurrence/count/` Count the number of (geoValid) occurrence records for each species in BIEN (~ `BIEN::BIEN_occurrence_records_per_species`)

examples:

not working yet

```
curl 'https://bienapi.club/occurrence/count'
curl 'https://bienapi.club/occurrence/species?species=Pinus%20contorta'
curl 'https://bienapi.club/occurrence/genus?genus=Pinus'
curl 'https://bienapi.club/occurrence/family?family=Pinaceae'
curl -XPOST 'https://bienapi.club/occurrence/spatial' -d "wkt=POLYGON((-114.125 34.230,-112.346 34.230,-112.346 32.450,-114.125 32.450,-114.125 34.230)); lat_min=27.31; lat_max=37.29; lon_min=-117.13; lon_max=-108.62"
```

### species `list` routes

- [x] `/list/` Extract species list (~ `BIEN::BIEN_list_all`)
- [x] `/list/county/` Extract species list by county (~ `BIEN::BIEN_list_country`)
- [ ] `/list/country/` Extract species list by country
- [ ] `/list/state/` Extract a species list by state/province
- [ ] `/list/spatial/` Extract a list of species within a given WKT

examples:

```
curl 'https://bienapi.club/list/country?country=Canada'
curl 'https://bienapi.club/list?country=Canada'
```

### `meta` routes

- [x] `/meta/version/` Get current BIEN database version and release date (~ `BIEN::BIEN_metadata_database_version`)
- [ ] `/meta/citations/` Get citations for BIEN data (~ `BIEN::BIEN_metadata_citation`)
- [x] `/meta/politicalnames/` Get political divisions and associated geonames codes (~ `BIEN::BIEN_metadata_list_political_names`)

examples:

```
curl 'https://bienapi.club/meta/version'
curl 'https://bienapi.club/meta/politicalnames'
```

### `phylogeny` routes

- [x] `/phylogeny/` Download the complete or conservative BIEN phylogeny (~ `BIEN::BIEN_phylogeny_complete` and `BIEN::BIEN_phylogeny_conservative` )

examples:

```
# by default uses conservative tree
curl 'https://bienapi.club/phylogeny'
# same as
curl 'https://bienapi.club/phylogeny?type=conservative'

# complete
curl 'https://bienapi.club/phylogeny?type=complete'

# select certain number (default: 10)
curl 'https://bienapi.club/phylogeny?type=complete&limit=4'
```

### `plot` routes

- [ ] `/plot/country/` Get plot data from specified countries
- [ ] `/plot/dataset/` Get plot data by dataset name
- [ ] `/plot/datasources/` List available data sources
- [ ] `/plot/datasources/<protocol name>` Get plot data by data source name
- [x] `/plot/protocols/` List available sampling protocols (~ `BIEN::BIEN_plot_list_sampling_protocols`)
- [ ] `/plot/protocols/<protocol name>` Get plot data by protocol name
- [x] `/plot/metadata/` Get all plot metadata  (~ `BIEN::BIEN_plot_metadata`)
- [ ] `/plot/name/` Get plot data by plot name (~ `BIEN::BIEN_plot_name`)
- [ ] `/plot/state/` Get plot data from specified states/provinces

examples:

```
curl 'https://bienapi.club/plot/metadata'
curl 'https://bienapi.club/plot/protocols'
curl 'https://bienapi.club/plot/name?plot=SR-1'
```

### `ranges` routes

- [x] `/ranges/species/` Get range maps for a species (~ `BIEN::BIEN_ranges_species`)
- [x] `/ranges/genus/` Get range maps for a genus (~ `BIEN::BIEN_ranges_genus`)
- [x] `/ranges/list/` List available range maps (~ `BIEN::BIEN_ranges_list`)
- [ ] `/ranges/spatial/` Get range maps that intersect a WKT polygon or bounding box (~ `BIEN::BIEN_ranges_box` and `BIEN::BIEN_ranges_spatialpolygons`)
- [ ] `/ranges/species/intersect/` Get range maps that intersect the range of a species (~ `BIEN::BIEN_ranges_intersect_species`)

examples:

```
curl 'https://bienapi.club/ranges/list'
curl 'https://bienapi.club/ranges/list?limit=3'
curl 'https://bienapi.club/ranges/list?limit=3&offset=2'

curl 'https://bienapi.club/ranges/species?species=Abies%20lasiocarpa'
curl 'https://bienapi.club/ranges/species?species=Abies%20lasiocarpa&match_names_only=true'
curl 'https://bienapi.club/ranges/species?species=Abies%20amabilis'

curl 'https://bienapi.club/ranges/genus?genus=Abies'
curl 'https://bienapi.club/ranges/genus?genus=Quercus'
```

### `stem` routes

- [ ] `/stem/datasource/` Get stem data for a datasource (~ `BIEN::BIEN_stem_datasource`)
- [ ] `/stem/family/` Get stem data for a family (~ `BIEN::BIEN_stem_family`)
- [ ] `/stem/genus/` Get stem data for a genus (~ `BIEN::BIEN_stem_genus`)
- [ ] `/stem/species/` Get stem data for a species (~ `BIEN::BIEN_stem_species`)

examples:

```
curl 'https://bienapi.club/stem/species?species=Abies%20amabilis'
curl 'https://bienapi.club/stem/species?species=Acer%20nigrum'
```

### `taxonomy` routes

- [ ] `/taxonomy/family/` Extract taxonomic information for families
- [ ] `/taxonomy/genus/` Extract taxonomic information for genera
- [ ] `/taxonomy/species/` Extract taxonomic information for species

examples:

```
curl 'https://bienapi.club/taxonomy/species?species=Cannabis%20sativa'
```

### `trait` routes

- [x] `/traits/` List all available types of trait data (~ `BIEN::BIEN_trait_list`)
- [x] `/traits/family/` Extract all trait data for given families (~ `BIEN::BIEN_trait_family`)
- [ ] `/traits/family/<trait>` Extract specific trait data for given families
- [ ] `/traits/genus/` Extract all trait data for given genera
- [ ] `/traits/genus/<trait>` Extract specific trait data for given genera
- [ ] `/traits/species/` Extract all trait data for given species
- [ ] `/traits/species/<trait>` Extract specific trait data for given species
- [ ] `/traits/trait/` Extract all measurements for a trait
- [ ] `/traits/count/` Count the number of trait observations for each species in the BIEN database

Note: `mean` removed since that's done client side.

examples:

```
curl 'https://bienapi.club/traits/'
curl 'https://bienapi.club/traits/family/?family=Poaceae'
```


### other routes

- [x] `/usda`
- [x] `/iucn`

