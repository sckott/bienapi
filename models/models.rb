require_relative 'base'

module Models
  def self.models
    constants.select { |c| const_get(c).is_a?(Class) }
  end

  class Iucn < Base; end
  class Usda < Base; end
end

class List < ActiveRecord::Base
  self.table_name = 'bien_species_all'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    %i(limit offset).each do |p|
      unless params[p].nil?
        begin
          params[p] = Integer(params[p])
        rescue ArgumentError
          raise Exception.new("#{p.to_s} is not an integer")
        end
      end
    end
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
    %i(limit offset).each do |p|
      unless params[p].nil?
        begin
          params[p] = Integer(params[p])
        rescue ArgumentError
          raise Exception.new("#{p.to_s} is not an integer")
        end
      end
    end
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    select('country, scrubbed_species_binomial').distinct
          .where(sprintf("country in ('%s')
            AND scrubbed_species_binomial IS NOT NULL
            AND (is_cultivated = 0 OR is_cultivated IS NULL)
            AND is_new_world = 1", params[:country]))
          .order('scrubbed_species_binomial')
          .limit(params[:limit] || 10)
          .offset(params[:offset])
  end
end

class PlotMetadata < ActiveRecord::Base
  self.table_name = 'plot_metadata'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    %i(limit offset).each do |p|
      unless params[p].nil?
        begin
          params[p] = Integer(params[p])
        rescue ArgumentError
          raise Exception.new("#{p.to_s} is not an integer")
        end
      end
    end
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    limit(params[:limit] || 10)
        .offset(params[:offset])
        .select(params[:fields])
  end
end

class PlotProtocols < ActiveRecord::Base
  self.table_name = 'plot_metadata'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    %i(limit offset).each do |p|
      unless params[p].nil?
        begin
          params[p] = Integer(params[p])
        rescue ArgumentError
          raise Exception.new("#{p.to_s} is not an integer")
        end
      end
    end
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    select("sampling_protocol")
        .distinct()
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end

class TaxonomySpecies < ActiveRecord::Base
  self.table_name = 'bien_taxonomy'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    %i(limit offset).each do |p|
      unless params[p].nil?
        begin
          params[p] = Integer(params[p])
        rescue ArgumentError
          raise Exception.new("#{p.to_s} is not an integer")
        end
      end
    end
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    sel1 = %w(higher_plant_group "class" superorder "order" scrubbed_family scrubbed_genus
      scrubbed_species_binomial scrubbed_author scrubbed_taxonomic_status)
    ord1 = %w(higher_plant_group scrubbed_family scrubbed_genus scrubbed_species_binomial scrubbed_author)
    select(sel1.join(', '))
        .distinct()
        .where(sprintf("scrubbed_species_binomial in ('%s')
           AND scrubbed_species_binomial IS NOT NULL", params[:species]))
        .order(ord1.join(', '))
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end

class Traits < ActiveRecord::Base
  self.table_name = 'agg_traits'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    %i(limit offset).each do |p|
      unless params[p].nil?
        begin
          params[p] = Integer(params[p])
        rescue ArgumentError
          raise Exception.new("#{p.to_s} is not an integer")
        end
      end
    end
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
    %i(limit offset).each do |p|
      unless params[p].nil?
        begin
          params[p] = Integer(params[p])
        rescue ArgumentError
          raise Exception.new("#{p.to_s} is not an integer")
        end
      end
    end
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    cols = %w(scrubbed_family scrubbed_genus scrubbed_species_binomial trait_name trait_value unit method latitude longitude elevation url_source project_pi project_pi_contact access id)
    select(cols.join(', '))
        .where(sprintf("scrubbed_family in ( '%s' )", params[:family]))
        .order("scrubbed_family, scrubbed_species_binomial")
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end

class OccurrenceSpecies < ActiveRecord::Base
  self.table_name = 'view_full_occurrence_individual'

  def self.endpoint(params)
    params.delete_if { |k, v| v.nil? || v.empty? }
    %i(limit offset).each do |p|
      unless params[p].nil?
        begin
          params[p] = Integer(params[p])
        rescue ArgumentError
          raise Exception.new("#{p.to_s} is not an integer")
        end
      end
    end
    raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
    cols = %w(scrubbed_species_binomial latitude longitude date_collected datasource dataset dataowner custodial_institution_codes collection_code view_full_occurrence_individual.datasource_id)
    select(cols.join(', '))
        .where(sprintf("scrubbed_species_binomial in ( '%s' ) AND (is_cultivated = 0 OR is_cultivated IS NULL)", params[:species]))
        .order("scrubbed_species_binomial")
        .limit(params[:limit] || 10)
        .offset(params[:offset])
  end
end
# SELECT scrubbed_species_binomial,latitude,longitude,date_collected,datasource,dataset,dataowner,custodial_institution_codes,collection_code,view_full_occurrence_individual.datasource_id
# FROM view_full_occurrence_individual
# WHERE
#   scrubbed_species_binomial in ( 'Abies amabilis' ) AND
#   (is_cultivated = 0 OR is_cultivated IS NULL) AND
#   is_new_world = 1  AND
#   ( native_status IS NULL OR native_status NOT IN ( 'I', 'Ie' ) ) AND
#   higher_plant_group IS NOT NULL AND
#   (is_geovalid = 1 OR is_geovalid IS NULL)
# ORDER BY scrubbed_species_binomial


