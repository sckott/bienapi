require_relative 'base'

module Models
  def self.models
    constants.select { |c| const_get(c).is_a?(Class) }
  end

  class iucn < Base; end
  class usda < Base; end

end
