require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "active_fedora"

describe HypatiaCollection do
  
  before(:all) do
    ActiveFedora.init()
    # Fedora::Repository.stubs(:instance).returns(stub('set_stub').as_null_object)
    @hypatia_coll = HypatiaCollection.new
  end
  
  after(:all) do
  end
  
  it "should be a kind of ActiveFedora::Base" do
    @hypatia_coll.should be_kind_of(ActiveFedora::Base)
  end
  
  it "should have a descMetadata datastream of type HypatiaCollDescMetadataDS" do
    @hypatia_coll.datastreams.should have_key("descMetadata")
    @hypatia_coll.datastreams["descMetadata"].should be_instance_of(HypatiaCollDescMetadataDS)
  end

  it "should have a rightsMetadata datastream of type Hydra::RightsMetadata" do
    @hypatia_coll.datastreams.should have_key("rightsMetadata")
    @hypatia_coll.datastreams["rightsMetadata"].should be_instance_of(Hydra::RightsMetadata)
  end
    
  it "should have a members relationship" do
    @hypatia_coll.should respond_to(:members)
  end
  
  it "should have not have a sets relationship" do
    @hypatia_coll.should_not respond_to(:sets)
  end
  
  it "should have a parts relationship (for EAD, image, etc.)" do
    @hypatia_coll.should respond_to(:parts)
  end
  
end