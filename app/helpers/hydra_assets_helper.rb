module HydraAssetsHelper
  include Hydra::HydraAssetsHelperBehavior
  include Cul::Scv::Hydra::Controllers::Helpers::HydraAssetsHelperBehavior
  def get_file_asset_count(document)
    count = 0
    obj = load_af_instance_from_solr(document)
    if obj.respond_to? :file_objects
      count += obj.file_objects.length unless obj.nil?
    elsif obj.respond_to? :parts
      count += obj.parts.length unless obj.nil?
    end
    count
  end
end