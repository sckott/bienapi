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
    where(params.select { |param| fields.any? { |s| s.to_s.casecmp(param.to_s)==0 } })
        .limit(params[:limit] || 10)
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
