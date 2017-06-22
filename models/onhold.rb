class PlotDataset < ActiveRecord::Base
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
    sel1 = %w(view_full_occurrence_individual.plot_name subplot view_full_occurrence_individual.elevation_m
       view_full_occurrence_individual.plot_area_ha view_full_occurrence_individual.sampling_protocol
       recorded_by scrubbed_species_binomial individual_count view_full_occurrence_individual.latitude
       view_full_occurrence_individual.longitude view_full_occurrence_individual.date_collected
       view_full_occurrence_individual.datasource view_full_occurrence_individual.dataset
       view_full_occurrence_individual.dataowner custodial_institution_codes
       collection_code view_full_occurrence_individual.datasource_id)
    select(sel1.join(', '))
      .from(sprintf("(SELECT * FROM view_full_occurrence_individual
      WHERE view_full_occurrence_individual.dataset in ( '%s' )
      AND (view_full_occurrence_individual.is_cultivated = 0 OR view_full_occurrence_individual.is_cultivated IS NULL)
      AND view_full_occurrence_individual.is_new_world = 1
      AND ( view_full_occurrence_individual.native_status IS NULL OR view_full_occurrence_individual.native_status NOT IN ( 'I', 'Ie' ) )
      AND higher_plant_group IS NOT NULL
      AND (is_geovalid = 1 OR is_geovalid IS NULL)
      AND observation_type='plot'
      ORDER BY country,plot_name,subplot,scrubbed_species_binomial)
      as view_full_occurrence_individual", params[:dataset]))
      .joins('LEFT JOIN plot_metadata ON (view_full_occurrence_individual.plot_metadata_id=plot_metadata.plot_metadata_id)')
      .limit(params[:limit] || 10)
      .offset(params[:offset])
  end
end

# SELECT view_full_occurrence_individual.plot_name,
#        subplot,
#        view_full_occurrence_individual.elevation_m,
#        view_full_occurrence_individual.plot_area_ha,
#        view_full_occurrence_individual.sampling_protocol,
#        recorded_by,
#        scrubbed_species_binomial,
#        individual_count,
#        view_full_occurrence_individual.latitude,
#        view_full_occurrence_individual.longitude
#        view_full_occurrence_individual.date_collected,
#        view_full_occurrence_individual.datasource,
#        view_full_occurrence_individual.dataset,
#        view_full_occurrence_individual.dataowner,
#        custodial_institution_codes,
#        collection_code,
#        view_full_occurrence_individual.datasource_id
#   FROM "(SELECT * FROM view_full_occurrence_individual
#       WHERE view_full_occurrence_individual.dataset in ( '%s' )
#       AND (view_full_occurrence_individual.is_cultivated = 0 OR view_full_occurrence_individual.is_cultivated IS NULL)
#       AND view_full_occurrence_individual.is_new_world = 1
#       AND ( view_full_occurrence_individual.native_status IS NULL OR view_full_occurrence_individual.native_status NOT IN ( 'I', 'Ie' ) )
#       AND higher_plant_group IS NOT NULL
#       AND (is_geovalid = 1 OR is_geovalid IS NULL)
#       AND observation_type='plot'
#     ORDER BY country,plot_name,subplot,scrubbed_species_binomial)", params[:dataset]) as view_full_occurrence_individual
#   LEFT JOIN plot_metadata ON (view_full_occurrence_individual.plot_metadata_id=plot_metadata.plot_metadata_id)
