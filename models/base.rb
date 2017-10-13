class Base < ActiveRecord::Base
  self.abstract_class = true
  self.pluralize_table_names = false
  self.req_field = nil

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
    params[:fields].nil? ? self.req_field : self.req_field.concat(',') + params[:fields]
    limit(params[:limit] || 10)
        .offset(params[:offset])
        .select()
  end
end

# class Base < ActiveRecord::Base
#   attr_accessor :with_id

#   self.abstract_class = true
#   self.pluralize_table_names = false

#   def self.endpoint(params)
#     params.delete_if { |k, v| v.nil? || v.empty? }

#     %i(limit offset).each do |p|
#       unless params[p].nil?
#         begin
#           params[p] = Integer(params[p])
#         rescue ArgumentError
#           raise Exception.new("#{p.to_s} is not an integer")
#         end
#       end
#     end
#     raise Exception.new('limit too large (max 1000)') unless (params[:limit] || 0) <= 1000
#     return where(primary_key => params[:id]).select(params[:fields]) if params[:id]
#     fields = columns.map(&:name)
#     limit(params[:limit] || 10)
#         .offset(params[:offset])
#         .select(params[:fields])
#   end
# end
