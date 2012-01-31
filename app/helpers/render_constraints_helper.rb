# require 'blacklight/render_constraints_helper_behavior'
module RenderConstraintsHelper
  include ::Blacklight::RenderConstraintsHelperBehavior
  
  def render_constraint_element(label, value, options = {})
      render(:partial => "catalog/constraints_element", :locals => {:label => label, :value => t(value), :options => options})    
  end
  #def render_constraints_filters(localized_params = params)
  #   return "".html_safe unless localized_params[:f]
  #   content = ""
  #   localized_params[:f].each_pair do |facet,values|
  #      values.each do |val|
  #         content << render_constraint_element( facet_field_labels[facet],
  #                t(val,:default=>val), 
  #                :remove => catalog_index_path(remove_facet_params(facet, val, localized_params)),
  #                :classes => ["filter", "filter-" + facet.parameterize] 
  #              ) + "\n"                 					            
  #			end
  #   end 

  #   return content.html_safe    
  #end

end
