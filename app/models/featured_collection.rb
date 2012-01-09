# -*- encoding : utf-8 -*-
class FeaturedCollection 

  include Blacklight::Solr::Document
  include Blacklight::SolrHelper
  # Email uses the semantic field mappings below to generate the body of an email.
  use_extension( Blacklight::Solr::Document::Email )
  
  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  use_extension( Blacklight::Solr::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Solr::Document::DublinCore)    
  field_semantics.merge!(    
                         :title => "title_display",
                         :author => "author_display",
                         :language => "language_facet",
                         :format => "format"
                         )
  def self.find(ids)
    if ids.is_a? String
      return super
    elsif ids.is_a? Array
      response, docs = get_solr_response_for_field_values("id",ids, {:sort=>"title_sort desc"})
      return docs
    end
    return nil
  end
end
