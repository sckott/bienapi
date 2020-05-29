# require_relative 'base'
require 'safe_attributes/base'

def check_limit_offset(params)
  %i(limit offset).each do |p|
    unless params[p].nil?
      begin
        params[p] = Integer(params[p])
      rescue ArgumentError
        raise Exception.new("#{p.to_s} is not an integer")
      end
    end
  end
  return params
end

def is_bool(x)
  [true, false].include? x
end

def check_type(x, name, type = "bool")
  case type
  when "bool"
    raise Exception.new('%s must be of class bool' % name) unless is_bool(x)
  end
end

class List < ActiveRecord::Base
  self.table_name = 'bien_species_all'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    select('species')
      .order('species')
      .limit(params[:limit] || 10)
      .offset(params[:offset])
  end
end

class ListCountry < ActiveRecord::Base
  self.table_name = 'species_by_political_division'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    country_code = params[:country_code]
    cc = country_code.nil? ? sprintf("('%s')", params[:country]) : sprintf("(SELECT country FROM country WHERE iso in ( '%s' ))", country_code)
    cultivated = params[:cultivated] || false
    only_new_world = params[:only_new_world] || false
    sel = %w(country scrubbed_species_binomial is_cultivated_observation is_cultivated_in_region is_new_world)
    where_query = "country in %s AND scrubbed_species_binomial IS NOT NULL %s %s"
    cultivated_false = "AND (is_cultivated_observation = 0 OR is_cultivated_observation IS NULL)"
    new_world_true = "AND is_new_world = 1"
    cult = cultivated ? "" : cultivated_false
    newworld = only_new_world ? new_world_true : ""
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    select(sel.join(', ')).distinct
          .order(:scrubbed_species_binomial)
          .where(sprintf(where_query, cc, cult, newworld))
          .limit(params[:limit] || 10)
          .offset(params[:offset])
  end
end

class PlotMetadata < ActiveRecord::Base
  self.table_name = 'plot_metadata'

  def self.endpoint(params)
    req_field = 'plot_metadata_id'
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    fields = params[:fields].nil? ? req_field : req_field.concat(',') + params[:fields]
    limit(params[:limit] || 10)
        .offset(params[:offset])
        .select(fields)
  end
end

class PlotProtocols < ActiveRecord::Base
  self.table_name = 'plot_metadata'

  def self.endpoint
    select(:sampling_protocol).distinct()
  end
end

# class PlotSamplingProtocol < ActiveRecord::Base
#   self.table_name = 'plot_metadata'
#   def self.endpoint(params)
#     req_field = 'plot_metadata_id'
#     params.delete_if { |k, v| v.nil? || v.empty? }
#     params = check_limit_offset(params)
#     raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
#     fields = params[:fields].nil? ? req_field : req_field.concat(',') + params[:fields]
#     select(fields)
#       .where("sampling_protocol = ?", params[:protocol])
#       .limit(params[:limit] || 10)
#       .offset(params[:offset])
#   end
# end

# class PlotSamplingProtocol < ActiveRecord::Base
#   self.table_name = 'plot_metadata'
#   def self.endpoint(params)
#     params.delete_if { |k, v| v.nil? || v.empty? }
#     params = check_limit_offset(params)
#     raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000

#     sel = %w(view_full_occurrence_individual.plot_name subplot view_full_occurrence_individual.elevation_m view_full_occurrence_individual.plot_area_ha 
#       view_full_occurrence_individual.sampling_protocol recorded_by scrubbed_species_binomial individual_count)

#     fields_tax = %w(view_full_occurrence_individual.verbatim_family view_full_occurrence_individual.verbatim_scientific_name view_full_occurrence_individual.family_matched view_full_occurrence_individual.name_matched view_full_occurrence_individual.name_matched_author view_full_occurrence_individual.higher_plant_group view_full_occurrence_individual.scrubbed_taxonomic_status view_full_occurrence_individual.scrubbed_family view_full_occurrence_individual.scrubbed_author)
#     # tax = params[:all_taxonomy].nil? ? nil : fields_tax

#     fields_nat = %w(view_full_occurrence_individual.native_status view_full_occurrence_individual.native_status_reason view_full_occurrence_individual.native_status_sources view_full_occurrence_individual.is_introduced view_full_occurrence_individual.native_status_country view_full_occurrence_individual.native_status_state_province view_full_occurrence_individual.native_status_county_parish)
#     native_status = params[:native_status].nil? ? false : params[:native_status]
#     check_type(native_status, "native_status")
#     nat_query = native_status ? "AND (view_full_occurrence_individual.is_introduced=0 OR view_full_occurrence_individual.is_introduced IS NULL) " : ""

#     fields_pol = %w(view_full_occurrence_individual.country view_full_occurrence_individual.state_province view_full_occurrence_individual.county view_full_occurrence_individual.locality)
#     # pol = params[:political_boundaries].nil? ? nil : fields_pol

#     fields_coll = %w(view_full_occurrence_individual.catalog_number view_full_occurrence_individual.recorded_by view_full_occurrence_individual.record_number view_full_occurrence_individual.date_collected view_full_occurrence_individual.identified_by view_full_occurrence_individual.date_identified view_full_occurrence_individual.identification_remarks)
#     # coll = params[:collection_info].nil? ? nil : fields_coll

#     cultivated = params[:cultivated].nil? ? false : params[:cultivated]
#     check_type(cultivated, "cultivated")
#     cult_query = cultivated ? "" : "AND (view_full_occurrence_individual.is_cultivated_observation = 0 OR view_full_occurrence_individual.is_cultivated_observation IS NULL) AND view_full_occurrence_individual.is_location_cultivated IS NULL"
    
#     nw = params[:only_new_world].nil? ? false : params[:only_new_world]
#     check_type(nw, "only_new_world")
#     nw_query = nw ? "AND view_full_occurrence_individual.is_new_world = 1 " : ""
#     # met_query = params[:all_metadata] ? nil : ""

#     prots = params[:protocol]
#     select(sel + fields_tax + fields_nat + fields_pol + fields_coll)
#       .from(sprintf(
#         "(SELECT * FROM view_full_occurrence_individual WHERE view_full_occurrence_individual.sampling_protocol in ( %s )
#         %s
#         AND view_full_occurrence_individual.higher_plant_group NOT IN ('Algae','Bacteria','Fungi') 
#         AND (view_full_occurrence_individual.is_geovalid = 1 ) 
#         AND (view_full_occurrence_individual.georef_protocol is NULL OR view_full_occurrence_individual.georef_protocol<>'county centroid') 
#         AND (view_full_occurrence_individual.is_centroid IS NULL OR view_full_occurrence_individual.is_centroid=0) 
#         AND view_full_occurrence_individual.observation_type='plot' 
#         AND view_full_occurrence_individual.scrubbed_species_binomial IS NOT NULL",
#         prots.split(',').map{ |z| "'#{z}'" }.join(', '), [cult_query, nat_query, nw_query].join(" "))
#       )
#       .order('view_full_occurrence_individual.country, view_full_occurrence_individual.plot_name, view_full_occurrence_individual.subplot,
#           view_full_occurrence_individual.scrubbed_species_binomial) as view_full_occurrence_individual')
#       .joins("JOIN plot_metadata ON (view_full_occurrence_individual.plot_metadata_id=plot_metadata.plot_metadata_id)")
#       .limit(params[:limit] || 10)
#       .offset(params[:offset])
#   end
# end

# class PlotName < ActiveRecord::Base
#   self.table_name = 'view_full_occurrence_individual'

#   def self.endpoint(params)
#     params.delete_if { |k, v| v.nil? || v.empty? }
#     params = check_limit_offset(params)
#     raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
#     cols = %w(view_full_occurrence_individual.plot_name subplot view_full_occurrence_individual.elevation_m  view_full_occurrence_individual.plot_area_ha
#       view_full_occurrence_individual.sampling_protocol view_full_occurrence_individual.recorded_by  view_full_occurrence_individual.scrubbed_species_binomial
#       view_full_occurrence_individual.individual_count view_full_occurrence_individual.latitude  view_full_occurrence_individual.longitude view_full_occurrence_individual.date_collected
#       view_full_occurrence_individual.datasource view_full_occurrence_individual.dataset view_full_occurrence_individual.dataowner
#       view_full_occurrence_individual.custodial_institution_codes collection_code view_full_occurrence_individual.datasource_id
#     )
#     select(cols.join(', '))
#       # .select("(SELECT * FROM view_full_occurrence_individual WHERE view_full_occurrence_individual.plot_name in ( :plot )
#       #       AND higher_plant_group IS NOT NULL
#       #       AND (is_geovalid = 1 OR is_geovalid IS NULL)
#       #       AND observation_type='plot'
#       #       ORDER BY country,plot_name,subplot,scrubbed_species_binomial) as view_full_occurrence_individual", {plot: params[:plot]})
#       # .joins("LEFT JOIN plot_metadata ON (view_full_occurrence_individual.plot_metadata_id=plot_metadata.plot_metadata_id)")
#       # .limit(params[:limit] || 10)
#       # .offset(params[:offset])
#       .where("view_full_occurrence_individual.plot_name in ( :plot )
#               AND higher_plant_group IS NOT NULL
#               AND (is_geovalid = 1 OR is_geovalid IS NULL)
#               AND observation_type='plot'
#               ORDER BY country,plot_name,subplot,scrubbed_species_binomial as view_full_occurrence_individual", {plot: params[:plot]})
#         .joins("LEFT JOIN plot_metadata ON (view_full_occurrence_individual.plot_metadata_id=plot_metadata.plot_metadata_id)")
#         .limit(params[:limit] || 10)
#         .offset(params[:offset])
#   end
# end

class TaxonomySpecies < ActiveRecord::Base
  self.table_name = 'bien_taxonomy'
  self.primary_key = 'bien_taxonomy_id'
  alias_attribute :clazz, :class
  alias_attribute :zorder, :order
  class << self
    def instance_method_already_implemented?(method_name)
      return true if method_name == 'class'
      super
    end
  end
  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    sel1 = %w(bien_taxonomy_id higher_plant_group taxon_class superorder taxon_order scrubbed_family scrubbed_genus
      scrubbed_species_binomial scrubbed_author scrubbed_taxonomic_status)
    ord1 = %w(higher_plant_group scrubbed_family scrubbed_genus scrubbed_species_binomial scrubbed_author)
    select(sel1.join(', '))
        .distinct
        .where(scrubbed_species_binomial: params[:species]).where.not(scrubbed_species_binomial: nil)
        .order(ord1.join(', '))
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end

class TaxonomyGenus < ActiveRecord::Base
  self.table_name = 'bien_taxonomy'
  self.primary_key = 'bien_taxonomy_id'
  alias_attribute :clazz, :class
  alias_attribute :zorder, :order
  class << self
    def instance_method_already_implemented?(method_name)
      return true if method_name == 'class'
      super
    end
  end
  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    sel1 = %w(bien_taxonomy_id higher_plant_group taxon_class superorder taxon_order scrubbed_family scrubbed_genus
      scrubbed_species_binomial scrubbed_author scrubbed_taxonomic_status)
    ord1 = %w(higher_plant_group scrubbed_family scrubbed_genus scrubbed_species_binomial scrubbed_author)
    select(sel1.join(', '))
        .distinct
        .where(scrubbed_genus: params[:genus]).where.not(scrubbed_species_binomial: nil)
        .order(ord1.join(', '))
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end

class TaxonomyFamily < ActiveRecord::Base
  self.table_name = 'bien_taxonomy'
  self.primary_key = 'bien_taxonomy_id'
  alias_attribute :clazz, :class
  alias_attribute :zorder, :order
  class << self
    def instance_method_already_implemented?(method_name)
      return true if method_name == 'class'
      super
    end
  end
  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    sel1 = %w(bien_taxonomy_id higher_plant_group taxon_class superorder taxon_order scrubbed_family scrubbed_genus
      scrubbed_species_binomial scrubbed_author scrubbed_taxonomic_status)
    ord1 = %w(higher_plant_group scrubbed_family scrubbed_genus scrubbed_species_binomial scrubbed_author)
    select(sel1.join(', '))
        .distinct
        .where(scrubbed_family: params[:family]).where.not(scrubbed_species_binomial: nil)
        .order(ord1.join(', '))
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end



class Traits < ActiveRecord::Base
  self.table_name = 'agg_traits'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    select("trait_name")
        .distinct()
        .order("trait_name")
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end

class TraitsFamily < ActiveRecord::Base
  self.table_name = 'agg_traits'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    cols = %w(scrubbed_family scrubbed_genus scrubbed_species_binomial trait_name trait_value unit method latitude longitude elevation_m url_source project_pi project_pi_contact access id)
    select(cols.join(', '))
        .where(sprintf("scrubbed_family in ( '%s' )", params[:family]))
        .order("scrubbed_family, scrubbed_species_binomial")
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end

class TraitsFamilyId < ActiveRecord::Base
  self.table_name = 'agg_traits'
  self.primary_key = 'id'
  def self.endpoint(params)
    return where(primary_key => params[:id])
  end
end

class OccurrenceSpecies < ActiveRecord::Base
  self.table_name = 'view_full_occurrence_individual'
  self.primary_key = 'taxonobservation_id'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    cols = %w(taxonobservation_id scrubbed_species_binomial latitude longitude date_collected datasource dataset dataowner custodial_institution_codes collection_code view_full_occurrence_individual.datasource_id)
    select(cols.join(', '))
        .where(sprintf("scrubbed_species_binomial in ( '%s' ) AND higher_plant_group IS NOT NULL AND (is_geovalid = 1 OR is_geovalid IS NULL)", params[:species]))
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end

class OccurrenceGenus < ActiveRecord::Base
  self.table_name = 'view_full_occurrence_individual'
  self.primary_key = 'taxonobservation_id'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    cols = %w(taxonobservation_id scrubbed_genus scrubbed_species_binomial latitude longitude date_collected datasource dataset dataowner custodial_institution_codes collection_code view_full_occurrence_individual.datasource_id)
    select(cols.join(', '))
        .where(sprintf("scrubbed_genus in ( '%s' ) AND higher_plant_group IS NOT NULL AND (is_geovalid = 1 OR is_geovalid IS NULL)", params[:genus]))
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end

class OccurrenceFamily < ActiveRecord::Base
  self.table_name = 'view_full_occurrence_individual'
  self.primary_key = 'taxonobservation_id'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    cols = %w(taxonobservation_id scrubbed_family scrubbed_species_binomial latitude longitude date_collected datasource dataset dataowner custodial_institution_codes collection_code view_full_occurrence_individual.datasource_id)
    select(cols.join(', '))
        .where(sprintf("scrubbed_family in ( '%s' ) AND higher_plant_group IS NOT NULL AND (is_geovalid = 1 OR is_geovalid IS NULL)", params[:family]))
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end

## spatial
class OccurrenceSpatial < ActiveRecord::Base
  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    cols = %w(scrubbed_species_binomial latitude longitude date_collected datasource dataset dataowner custodial_institution_codes collection_code a.datasource_id)
    select(cols.join(', '))
        .where("(SELECT * FROM view_full_occurrence_individual WHERE higher_plant_group IS NOT NULL AND is_geovalid =1 AND latitude BETWEEN :lat_min AND :lat_max AND longitude BETWEEN :lon_min AND :lon_max) a
            WHERE st_intersects(ST_GeographyFromText('SRID=4326; :wkt'), a.geom) AND (is_cultivated = 0 OR is_cultivated IS NULL) AND is_new_world = 1  AND ( native_status IS NULL OR native_status NOT IN ( 'I', 'Ie' ) )     AND higher_plant_group IS NOT NULL AND (is_geovalid = 1 OR is_geovalid IS NULL) ",
            {lat_min: params[:lat_min], lat_max: params[:lat_max], lon_min: params[:lon_min], lon_max: params[:lon_max], wkt: params[:wkt]})
        .order("scrubbed_species_binomial")
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end

## count
class OccurrenceCount < ActiveRecord::Base
  self.table_name = 'view_full_occurrence_individual'
  self.primary_key = 'taxonobservation_id'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    sp = params[:species] || nil
    if sp.nil?
      select("scrubbed_species_binomial, count(*)")
        .distinct
        .where("is_geovalid = 1 AND latitude IS NOT NULL AND LONGITUDE IS NOT NULL")
        .group(:scrubbed_species_binomial)
        .limit(params[:limit] || 10)
        .offset(params[:offset])
    else
      select("scrubbed_species_binomial, count(*)")
        .where(sprintf("scrubbed_species_binomial in ( '%s' ) AND is_geovalid = 1", [sp].join("', '")))
        .group(:scrubbed_species_binomial)
        .limit(params[:limit] || 10)
        .offset(params[:offset])
    end
  end
end

# SELECT scrubbed_species_binomial,count(*)
#    FROM view_full_occurrence_individual
#    WHERE scrubbed_species_binomial in ( 'Abies lasiocarpa' ) AND is_geovalid = 1
#    GROUP BY scrubbed_species_binomial;

# "SELECT DISTINCT scrubbed_species_binomial,count(*)
#    FROM view_full_occurrence_individual
#    WHERE is_geovalid = 1 AND latitude IS NOT NULL AND LONGITUDE IS NOT NULL
#    GROUP BY scrubbed_species_binomial;"

## phylogeny model
class Phylogeny < ActiveRecord::Base
  self.table_name = 'phylogeny'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 100)') unless (params[:limit] || 1) <= 100

    limit = params[:limit] || 1
    type = params[:type] || "conservative"
    if !["conservative", "complete"].include? type
      raise Exception.new("'type' must be either conservative or complete")
    end
    if type == "conservative"
      select('*')
        .where("phylogeny_version = 'BIEN_2016_conservative'")
    else
      nums = [*1..100].sample(limit).join("', '")
      select('*')
        .where(sprintf("phylogeny_version = 'BIEN_2016_complete' AND replicate in ( '%s' )", nums))
    end
  end
end

## meta models
### version
class MetaVersion < ActiveRecord::Base
  self.table_name = 'bien_metadata'
  def self.endpoint
    find_by_sql("SELECT db_version, db_release_date FROM bien_metadata a JOIN (SELECT MAX(bien_metadata_id) as max_id FROM bien_metadata) AS b ON a.bien_metadata_id=b.max_id;")
  end
end

### citations
class CitationsTrait < ActiveRecord::Base
  self.table_name = 'agg_traits'
  def self.endpoint(params)
    cols = %w(citation_bibtex source_citation source url_source access project_pi project_pi_contact)
    select(cols.join(', ')).distinct.where(id: params[:id])
  end
end

class CitationsOccurrence < ActiveRecord::Base
  self.table_name = 'datasource'
  self.primary_key = 'datasource_id'
  def self.endpoint(params)
    find_by_sql("WITH a AS (SELECT * FROM datasource where datasource_id = %s) SELECT * FROM datasource where datasource_id in (SELECT proximate_provider_datasource_id FROM a) OR datasource_id in (SELECT datasource_id FROM a);" % params[:id])
  end
end

### political names
class MetaPoliticalNames < ActiveRecord::Base
  self.table_name = 'county_parish'
  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    select('country, country_id AS "country.code", state_province, state_province_ascii, state_province_code AS "state.code"')
    .limit(params[:limit] || 10)
    .offset(params[:offset])
  end
end


## range models
### list
class RangesList < ActiveRecord::Base
  self.table_name = 'ranges'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    select('species, gid')
      .order("species")
      .limit(params[:limit] || 10)
      .offset(params[:offset])
  end
end

### species
class RangesSpecies < ActiveRecord::Base
  self.table_name = 'ranges'
  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    raise Exception.new('must pass "species" parameter') unless params[:species]
    sp = [params[:species]].map { |z| z.gsub(/\s/, '_') }
    mn = params[:match_names_only] || false
    x1 = %w(ST_AsText(geom) species gid)
    x2 = %w(species)
    cols = mn ? x2 : x1
    select(cols.join(', '))
      .where(sprintf("species in ( '%s' )", sp.join("', '")))
      .order("species")
  end
end

### genus
class RangesGenus < ActiveRecord::Base
  self.table_name = 'ranges'
  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    raise Exception.new('must pass "genus" parameter') unless params[:genus]
    ge = [params[:genus]].map { |z| sprintf('(%s_)', z) }
    mn = params[:match_names_only] || false
    x1 = %w(ST_AsText(geom) species gid)
    x2 = %w(species)
    cols = mn ? x2 : x1
    select(cols.join(', '))
      .where(sprintf("species ~ '%s'", ge.join('|')))
      .order("species")
  end
end

### spatial
# @param crop.ranges Should the ranges be cropped to the focal area? Default is FALSE.
# @param species.names.only Return species names rather than spatial data? Default is FALSE.
class RangesSpatial < ActiveRecord::Base
  self.table_name = 'ranges'
  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    raise Exception.new('must pass "wkt" parameter') unless params[:wkt]

    wkt = params[:wkt]
    if params[:species_names_only] || false
      if params[:crop_ranges] || false
        sel = sprintf("ST_AsText(ST_intersection(geom,ST_GeographyFromText('SRID=4326;%s'))),species,gid", wkt)
        select(sel)
          .where(sprintf("st_intersects(ST_GeographyFromText('SRID=4326;%s'),geom)", wkt))
      else
        sel = %w(ST_AsText(geom) species gid)
        select(sel.join(', '))
          .where(sprintf("st_intersects(ST_GeographyFromText('SRID=4326; %s'), geom)", wkt))
      end
    else 
      select(:species)
        .where(sprintf("st_intersects(ST_GeographyFromText('SRID=4326;%s'),geom)", wkt))
    end
  end
end


## stem models
### species
class StemSpecies < ActiveRecord::Base
  self.table_name = 'analytical_stem'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('must pass "species" parameter') unless params[:species]
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    sel = %w(analytical_stem.scrubbed_species_binomial analytical_stem.latitude 
      analytical_stem.longitude analytical_stem.date_collected  analytical_stem.relative_x_m  analytical_stem.relative_y_m 
      analytical_stem.taxonobservation_id analytical_stem.stem_code  analytical_stem.stem_dbh_cm  analytical_stem.stem_height_m 
      plot_metadata.dataset plot_metadata.datasource plot_metadata.dataowner analytical_stem.custodial_institution_codes 
      analytical_stem.collection_code analytical_stem.datasource_id analytical_stem.is_new_world)
    sp = params[:species]
    select(sel.join(', '))
        .from(sprintf(
          "(SELECT * FROM analytical_stem WHERE scrubbed_species_binomial in ( %s )) AS analytical_stem
          JOIN plot_metadata ON (analytical_stem.plot_metadata_id = plot_metadata.plot_metadata_id)
          JOIN view_full_occurrence_individual ON (analytical_stem.taxonobservation_id  = view_full_occurrence_individual.taxonobservation_id)",
          sp.split(',').map{ |z| "'#{z}'" }.join(', '))
        )
        .where(sprintf(
          "analytical_stem.scrubbed_species_binomial in ( %s )
          AND (analytical_stem.is_cultivated_observation = 0 OR analytical_stem.is_cultivated_observation IS NULL) 
          AND analytical_stem.is_location_cultivated IS NULL  
          AND (view_full_occurrence_individual.is_introduced=0 OR view_full_occurrence_individual.is_introduced IS NULL) 
          AND analytical_stem.higher_plant_group NOT IN ('Algae','Bacteria','Fungi')
          AND (analytical_stem.is_geovalid = 1) 
          AND (analytical_stem.georef_protocol is NULL OR analytical_stem.georef_protocol<>'county centroid')
          AND (analytical_stem.is_centroid IS NULL OR analytical_stem.is_centroid=0)", sp.split(',').map{ |z| "'#{z}'" }.join(', ')
        ))
        .order('analytical_stem.scrubbed_species_binomial')
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end

### genus
class StemGenus < ActiveRecord::Base
  self.table_name = 'analytical_stem'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('must pass "genus" parameter') unless params[:genus]
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    sel = %w(analytical_stem.scrubbed_genus analytical_stem.scrubbed_species_binomial
      analytical_stem.latitude  analytical_stem.longitude analytical_stem.date_collected  analytical_stem.relative_x_m  
      analytical_stem.relative_y_m analytical_stem.taxonobservation_id  analytical_stem.stem_code  
      analytical_stem.stem_dbh_cm  analytical_stem.stem_height_m  plot_metadata.dataset 
      plot_metadata.datasource plot_metadata.dataowner  analytical_stem.custodial_institution_codes  
      analytical_stem.collection_code analytical_stem.datasource_id analytical_stem.is_new_world)
    gen = params[:genus]
    select(sel.join(', '))
        .from(sprintf(
          "(SELECT * FROM analytical_stem WHERE scrubbed_genus in ( %s )) AS analytical_stem
          JOIN plot_metadata ON (analytical_stem.plot_metadata_id = plot_metadata.plot_metadata_id)
          JOIN view_full_occurrence_individual ON (analytical_stem.taxonobservation_id  = view_full_occurrence_individual.taxonobservation_id)",
          gen.split(',').map{ |z| "'#{z}'" }.join(', '))
        )
        .where(sprintf(
          "analytical_stem.scrubbed_genus in ( %s )
            AND (analytical_stem.is_cultivated_observation = 0 OR analytical_stem.is_cultivated_observation IS NULL) 
            AND analytical_stem.is_location_cultivated IS NULL  
            AND (view_full_occurrence_individual.is_introduced=0 OR view_full_occurrence_individual.is_introduced IS NULL) 
            AND analytical_stem.higher_plant_group NOT IN ('Algae','Bacteria','Fungi')
            AND (analytical_stem.is_geovalid = 1) 
            AND (analytical_stem.georef_protocol is NULL OR analytical_stem.georef_protocol<>'county centroid')
            AND (analytical_stem.is_centroid IS NULL OR analytical_stem.is_centroid=0)", gen.split(',').map{ |z| "'#{z}'" }.join(', ')
        ))
        .order('analytical_stem.scrubbed_genus,analytical_stem.scrubbed_species_binomial')
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end


### family
class StemFamily < ActiveRecord::Base
  self.table_name = 'analytical_stem'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('must pass "family" parameter') unless params[:family]
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    sel = %w(analytical_stem.scrubbed_family analytical_stem.scrubbed_genus analytical_stem.scrubbed_species_binomial 
      analytical_stem.latitude analytical_stem.longitude analytical_stem.date_collected analytical_stem.relative_x_m
      analytical_stem.relative_y_m analytical_stem.taxonobservation_id
      analytical_stem.stem_code analytical_stem.stem_dbh_cm
      analytical_stem.stem_height_m plot_metadata.dataset plot_metadata.datasource
      plot_metadata.dataowner analytical_stem.custodial_institution_codes
      analytical_stem.collection_code analytical_stem.datasource_id)
    fam = params[:family]
    select(sel.join(', '))
        .from(sprintf(
          "(SELECT * FROM analytical_stem WHERE scrubbed_family in ( %s )) AS analytical_stem
          JOIN plot_metadata ON (analytical_stem.plot_metadata_id = plot_metadata.plot_metadata_id)
          JOIN view_full_occurrence_individual ON (analytical_stem.taxonobservation_id  = view_full_occurrence_individual.taxonobservation_id)",
          fam.split(',').map{ |z| "'#{z}'" }.join(', '))
        )
        .where(sprintf(
          "analytical_stem.scrubbed_family in ( %s )
          AND (analytical_stem.is_cultivated_observation = 0 OR analytical_stem.is_cultivated_observation IS NULL)
          AND analytical_stem.is_new_world = 1
          AND ( view_full_occurrence_individual.native_status IS NULL OR view_full_occurrence_individual.native_status NOT IN ( 'I', 'Ie' ) )
          AND analytical_stem.higher_plant_group IS NOT NULL
          AND (analytical_stem.is_geovalid = 1 OR analytical_stem.is_geovalid IS NULL)", fam.split(',').map{ |z| "'#{z}'" }.join(', ')
        ))
        .order('analytical_stem.scrubbed_genus,analytical_stem.scrubbed_species_binomial')
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end


### datasource
class StemDataSource < ActiveRecord::Base
  self.table_name = 'analytical_stem'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    params = check_limit_offset(params)
    raise Exception.new('must pass "datasource" parameter') unless params[:datasource]
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    sel = %w(analytical_stem.plot_name analytical_stem.subplot analytical_stem.elevation_m analytical_stem.plot_area_ha 
     analytical_stem.sampling_protocol analytical_stem.recorded_by analytical_stem.scrubbed_species_binomial 
     analytical_stem.latitude analytical_stem.longitude analytical_stem.date_collected analytical_stem.relative_x_m  
     analytical_stem.relative_y_m  analytical_stem.taxonobservation_id analytical_stem.stem_code  analytical_stem.stem_dbh_cm  
     analytical_stem.stem_height_m  plot_metadata.dataset plot_metadata.datasource plot_metadata.dataowner 
     analytical_stem.custodial_institution_codes  analytical_stem.collection_code analytical_stem.datasource_id)
    ds = params[:datasource]
    select(sel.join(', '))
        .from(sprintf(
          "(SELECT * FROM analytical_stem WHERE datasource in ( %s )) AS analytical_stem
          JOIN plot_metadata ON (analytical_stem.plot_metadata_id = plot_metadata.plot_metadata_id)
          JOIN view_full_occurrence_individual ON (analytical_stem.taxonobservation_id  = view_full_occurrence_individual.taxonobservation_id)",
          ds.split(',').map{ |z| "'#{z}'" }.join(', '))
        )
        .where(sprintf(
          "analytical_stem.datasource in ( %s )
          AND (analytical_stem.is_cultivated_observation = 0 OR analytical_stem.is_cultivated_observation IS NULL)
          AND analytical_stem.is_new_world = 1
          AND analytical_stem.higher_plant_group IS NOT NULL
          AND (analytical_stem.is_geovalid = 1 OR analytical_stem.is_geovalid IS NULL)", ds.split(',').map{ |z| "'#{z}'" }.join(', ')
        ))
        .order('analytical_stem.scrubbed_species_binomial')
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end

