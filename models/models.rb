require_relative 'base'

module Models
  def self.models
    constants.select { |c| const_get(c).is_a?(Class) }
  end

  class Iucn < Base; end
  class Usda < Base; end

  class List < Base
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

end
