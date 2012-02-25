module HydraHelper
  unloadable
  include Hydra::HydraHelperBehavior
  def get_af_model_from_solr
    (model_name, namespace) = ActiveFedora::Model.classname_from_uri(@document[:has_model_s].first)
    model_name.underscore.pluralize.to_sym
  end
  def render_all_workflow_steps
    all_edit_partials.map{|partial| render partial}.join.html_safe
    #all_edit_partials.map{|partial| render partial}.join.html_safe
  end
  def render_previous_workflow_steps
    previous_show_partials(params[:wf_step]).map{|partial| render partial}.join.html_safe
    #previous_show_partials.map{|partial| render partial}.join.html_safe
  end
  def render_submission_workflow_steps
    if params.has_key?(:wf_step)
      render workflow_partial_for_step(params[:wf_step])
    else
      render workflow_partial_for_step(first_step_in_workflow)
    end
  end
  def break_me
    render_all_workflow_steps
  end
end