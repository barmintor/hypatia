class CatalogController < ApplicationController
  include Blacklight::Catalog
  include Hydra::Catalog
  include Cul::Scv::Hydra::Controllers::Catalog
  helper :all # include all helpers, all the time
  
  # These before_filters apply the hydra access controls
  before_filter :enforce_access_controls
  before_filter :enforce_viewing_context_for_show_requests, :only=>:show
  # This applies appropriate access controls to all solr queries
  CatalogController.solr_search_params_logic << :add_access_controls_to_solr_params
  # This filters out objects that you want to exclude from search results, like FileAssets
  CatalogController.solr_search_params_logic << :exclude_unwanted_models

  before_filter :load_fedora_document, :only => [:edit, :show, :edit_members]
  before_filter :load_resources, :only => [:edit, :show, :edit_members]
  before_filter :load_bookmarks, :only => [:edit_members]
  before_filter :featured_collections, :only => [:index]
  
  def exclude_unwanted_models(solr_parameters, user_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "-has_model_s:\"info:fedora/afmodel:HypatiaCollection\""
      solr_parameters[:fq] << "-has_model_s:\"info:fedora/afmodel:FileAsset\""
      unless @document_fedora and @document_fedora.is_a? StaticImageAggregator
        solr_parameters[:fq] << "-has_model_s:\"info:fedora/ldpd:Resource\""
      end
  end
  
  def exclude_member_types(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    if @document_fedora.is_a? StaticImageAggregator or @document_fedora.is_a? StaticAudioAggregator
      solr_parameters[:fq] << "-has_model_s:\"info:fedora/ldpd:StaticImageAggregator\""
      solr_parameters[:fq] << "-has_model_s:\"info:fedora/ldpd:StaticAudioAggregator\""
      solr_parameters[:fq] << "-has_model_s:\"info:fedora/ldpd:ContentAggregator\""
      solr_parameters[:fq] << "-has_model_s:\"info:fedora/ldpd:BagAggregator\""
    end
    if @document_fedora.is_a? ContentAggregator or @document_fedora.is_a? BagAggregator
      solr_parameters[:fq] << "-has_model_s:\"info:fedora/ldpd:Resource\""
    end
    if @document_fedora.is_a? ContentAggregator
      solr_parameters[:fq] << "-has_model_s:\"info:fedora/ldpd:ContentAggregator\""
      solr_parameters[:fq] << "-has_model_s:\"info:fedora/ldpd:BagAggregator\""
    end
  end
  
  def exclude_document(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "-id:\"#{@document_fedora.pid}\""
  end
  
  def edit_members
    q = build_lucene_query("\" AND NOT _query_:\"info\\\\:fedora/afmodel\\\\:HypatiaCollection")
    puts "search query: #{q}"
    search_params = solr_search_params
    user_params = {}
    exclude_document(search_params, user_params)
    exclude_member_types(search_params, user_params)
    apply_gated_discovery(search_params, user_params)
    @response, @document_list = get_search_results(user_params,search_params)
    @folder_response, @folder_list = get_solr_response_for_field_values("id",session[:folder_document_ids] || [])
  end
  
  def update_members
    status_text = ""
    parent_doc = load_fedora_doc_from_id(params[:id])
    child_ids = params[:child_ids] || []
    remove_ids = parent_doc.members_ids - child_ids
    child_ids.each do |cid|
      unless parent_doc.members_ids.include?(cid) #don't add a relationship if we already have one.
        child = load_fedora_doc_from_id(cid)
        child.add_relationship(:cul_member_of,"info:fedora/#{params[:id]}")
        status_text << "Added #{:cul_member_of} relationship of #{cid} to #{params[:id]}"
        child.save
      end
    end
    remove_ids.each do |cid|
      child = load_fedora_doc_from_id(cid)
      child.remove_relationship(relationship,params[:id])
      status_text << "Removed #{relationship} relationship of #{cid} to #{params[:id]}"
      child.save
    end

    render :text => status_text
  end

  def featured_collections
    @featured_collections ||= begin
      response, docs = get_solr_response_for_field_values("id",Blacklight.config[:featured_collections], {:sort=>"title_sort desc"})
      docs
    end
    puts "featured_collections [#{@featured_collections.length}]"
    @featured_collections.each do |coll|
      puts coll.inspect
    end
    @featured_collections
  end

  # overriding to correct unexpected template reference in Blacklight
  # when solr (RSolr) throws an error (RSolr::RequestError), this method is executed.
    def rsolr_request_error(exception)
      logger.error exception
      if Rails.env == "development"
        raise exception # Rails own code will catch and give usual Rails error page with stack trace
      else
        flash_notice = "Sorry, I don't understand your search."
        # Set the notice flag if the flash[:notice] is already set to the error that we are setting.
        # This is intended to stop the redirect loop error
        notice = flash[:notice] if flash[:notice] == flash_notice
        unless notice
          flash[:notice] = flash_notice
        end
        redirect_to root_path, :status => 500
      end
    end
    
    def enforce_opensearch_permissions(opts={})
      return true
      # Do nothing. Relies on enforce_search_permissions being included in the Controller's solr_search_params_logic
      # apply_gated_discovery
      # if !reader? 
      #   solr_parameters[:qt] = Blacklight.config[:public_qt]
      # end
    end
    
    def enforce_update_members_permissions(opts={})
      enforce_edit_permissions(opts)
    end
    
    def enforce_edit_members_permissions(opts={})
      enforce_edit_permissions(opts)
    end
    
    def add_access_controls_to_solr_params(solr_parameters, user_parameters)
      apply_gated_discovery(solr_parameters, user_parameters)
      if !reader? 
        solr_parameters[:qt] = Blacklight.config[:public_qt] || 'search' # not sure why it can't pull this from BL config
      end
    end
  
  protected
  
  def requirements
  end
  
  def load_fedora_doc_from_id(id)
    af_base = ActiveFedora::Base.load_instance(id)
    the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
    if the_model.nil?
      the_model = DcDocument
    end
    return af_base.adapt_to(the_model)
  end
  
  def load_bookmarks
    @bookmarks = current_user.bookmarks.page(params[:page])
  end
end
