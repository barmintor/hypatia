require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'factory_girl'
require File.join(File.dirname(__FILE__), "/../fixtures/ftk/factories/ftk_files.rb")

describe FtkItemAssembler do
  before(:all) do
    @coll_pid = "hypatia:fixture_coll"
  end

  context "basic behavior" do
    before(:all) do
      delete_fixture(@coll_pid)
      import_fixture(@coll_pid)
    end
    it "can instantiate" do
      assembler = FtkItemAssembler.new
      assembler.class.should eql(FtkItemAssembler)
    end
    it "sets the pid of the collection object these items belong to" do
      assembler = FtkItemAssembler.new
      assembler.collection_pid = @coll_pid
      assembler.collection_pid.should eql(@coll_pid)
    end
  end # context basic behavior
  
  context "metadata (and RELS-EXT) datastreams" do
    before(:all) do
      delete_fixture(@coll_pid)
      import_fixture(@coll_pid)
      @assembler = FtkItemAssembler.new(:collection_pid => @coll_pid)
      @ff_intermed = FactoryGirl.build(:ftk_file)
    end
    
    it "creates the correct descMetadata" do
      desc_md_doc = Nokogiri::XML(@assembler.build_desc_metadata(@ff_intermed))
      desc_md_doc.namespaces.size.should eql(1)
      desc_md_doc.namespaces["xmlns:mods"].should eql("http://www.loc.gov/mods/v3")
      desc_md_doc.xpath("/mods:mods/mods:identifier[@type='filename']/text()").to_s.should eql(@ff_intermed.filename)
      desc_md_doc.xpath("/mods:mods/mods:identifier[@type='ftk_id']/text()").to_s.should eql(@ff_intermed.id)
      desc_md_doc.xpath("/mods:mods/mods:location/mods:physicalLocation[@type='filepath']/text()").to_s.should eql(@ff_intermed.filepath)
      nodeSet = desc_md_doc.xpath("/mods:mods/mods:physicalDescription/mods:extent")
      nodeSet.size.should eql(2)
      values = [nodeSet[0].text, nodeSet[1].text]
      values[0].should_not eql(values[1])
      values.include?(@ff_intermed.filesize).should be_true
      values.include?(@ff_intermed.medium).should be_true
      desc_md_doc.xpath("/mods:mods/mods:physicalDescription/mods:digitalOrigin/text()").to_s.should eql("born digital")
      desc_md_doc.xpath("/mods:mods/mods:originInfo/mods:dateCreated/text()").to_s.should eql(@ff_intermed.file_creation_date)
      desc_md_doc.xpath("/mods:mods/mods:originInfo/mods:dateOther[@type='last_accessed']/text()").to_s.should eql(@ff_intermed.file_accessed_date)
      desc_md_doc.xpath("/mods:mods/mods:originInfo/mods:dateOther[@type='last_modified']/text()").to_s.should eql(@ff_intermed.file_modified_date)
      desc_md_doc.xpath("/mods:mods/mods:relatedItem/mods:titleInfo/mods:title/text()").to_s.should eql(@ff_intermed.title)
      desc_md_doc.xpath("/mods:mods/mods:note[@displayLabel='filetype']/text()").to_s.should eql(@ff_intermed.filetype)
      desc_md_doc.xpath("/mods:mods/mods:note[not(@displayLabel)]/text()").to_s.should eql(@ff_intermed.type)
    end

    it "creates the correct rightsMetadata" do
      rights_md_doc = Nokogiri::XML(@assembler.build_rights_metadata)
      rights_md_doc.namespaces.size.should eql(1)
      ns = "http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1"
      rights_md_doc.namespaces["xmlns"].should eql(ns)
      rights_md_doc.xpath("/ns:rightsMetadata/ns:access", {"ns" => ns}).size.should eql(3)
      # "public" group can only have one permission group:  read, not discover
      rights_md_doc.xpath("/ns:rightsMetadata/ns:access[@type='discover']/ns:machine/ns:group/text()", {"ns" => ns}).to_s.should_not eql("public")
      rights_md_doc.xpath("/ns:rightsMetadata/ns:access[@type='read']/ns:machine/ns:group/text()", {"ns" => ns}).to_s.should eql("public")
      rights_md_doc.xpath("/ns:rightsMetadata/ns:access[@type='edit']/ns:machine/ns:group/text()", {"ns" => ns}).to_s.should eql("archivist")
    end
    
    context "link_to_parent method for RELS-EXT" do
      before(:all) do
        @ftk_item_object = HypatiaFtkItem.new
        @disk_objects = build_fixture_disk_objects
        # @disk_object title_sort (match fields) are:  single_match, mult_match, mult_match, no_match
      end
      
      it "creates a member_of relationship with a single matching disk image item" do
        ff_intermed = FactoryGirl.build(:ftk_file)
        ff_intermed.disk_image_name = "single_match"
        ftk_item_object = HypatiaFtkItem.new
        @assembler.link_to_parent(ftk_item_object, ff_intermed)
        ftk_item_object.relationships(:is_member_of).size.should be(1)
        ftk_item_object.relationships(:is_member_of).first.should eql("info:fedora/#{@disk_objects.first.pid}")
      end
      it "disambiguates multiple matches with the collection pid" do
        ff_intermed = FactoryGirl.build(:ftk_file)
        ff_intermed.disk_image_name = "mult_match"
        ftk_item_object = HypatiaFtkItem.new
        ftk_item_object.save
        @assembler.link_to_parent(ftk_item_object, ff_intermed)
        ftk_item_object.relationships(:is_member_of).size.should be(1)
        ftk_item_object.relationships(:is_member_of).first.should eql("info:fedora/#{@disk_objects[2].pid}")
        ftk_item_object.delete
      end
      it "does not create an is_member_of relationship when no disk image matches" do
        ff_intermed = FactoryGirl.build(:ftk_file)
        ff_intermed.disk_image_name = "will_not_match"
        ftk_item_object = HypatiaFtkItem.new
        ftk_item_object.save
        @assembler.link_to_parent(ftk_item_object, ff_intermed)
        ftk_item_object.relationships(:is_member_of).should eql([])
        ftk_item_object.delete
      end
      it "creates an is_member_of_collection relationship when no disk image matches" do
        ff_intermed = FactoryGirl.build(:ftk_file)
        ff_intermed.disk_image_name = "will_not_match"
        ftk_item_object = HypatiaFtkItem.new
        ftk_item_object.save
        @assembler.link_to_parent(ftk_item_object, ff_intermed)
        ftk_item_object.relationships(:is_member_of_collection).first.should eql("info:fedora/#{@coll_pid}")
        ftk_item_object.delete
      end
      it "does not create an is_member_of_collection relationship when a disk image matches" do
        ff_intermed = FactoryGirl.build(:ftk_file)
        ff_intermed.disk_image_name = "single_match"
        ftk_item_object = HypatiaFtkItem.new
        ftk_item_object.save
        @assembler.link_to_parent(ftk_item_object, ff_intermed)
        ftk_item_object.relationships(:is_member_of_collection).should eql([])
        ftk_item_object.delete
      end
    end # context  link_to_parent method for RELS-EXT

  end # context  metadata datastreams
  
  context "FtkItem assets" do
    before(:all) do
      delete_fixture(@coll_pid)
      import_fixture(@coll_pid)
      @assembler = FtkItemAssembler.new(:collection_pid => @coll_pid)
      @ftk_file_intermed = FactoryGirl.build(:ftk_file)
      @ftk_item_object = HypatiaFtkItem.new
      @ftk_item_object.save # lazy init of pid in ActiveFedora 3.2
      @assembler.file_dir = Pathname.new(File.join(__FILE__,'..','..','fixtures','ftk' )).realpath.to_s
      @assembler.display_derivative_dir = Pathname.new(File.join(__FILE__,'..','..','fixtures','ftk','display_derivatives')).realpath.to_s 
      @file_asset = @assembler.create_file_asset(@ftk_item_object, @ftk_file_intermed)
      @file_asset.save # lazy init of pid in ActiveFedora 3.2
      @file_asset.datastreams["DC"] # lazy init in ActiveFedora 3.2
      @ftk_item_pid = @ftk_item_object.internal_uri
      @content_file_ds = @file_asset.datastreams["content"]
      @deriv_file_ds = @file_asset.datastreams["derivative_html"]
      
      @ftk_file_intermed_no_deriv = FactoryGirl.build(:ftk_file)
      @ftk_file_intermed_no_deriv.filename = "foofile.txt"
      @ftk_file_intermed_no_deriv.export_path = "files/foofile.txt"
      @file_asset_no_deriv = @assembler.create_file_asset(@ftk_item_object, @ftk_file_intermed_no_deriv)
      @file_asset_no_deriv.save # lazy init of pid in ActiveFedora 3.2
      @file_asset_no_deriv.datastreams["DC"] # lazy init in ActiveFedora 3.2
      @content_file_ds_no_deriv = @file_asset_no_deriv.datastreams["content"]
    end
    
    after(:all) do
      # clean up test objects
      @ftk_item_object.delete
      @file_asset.delete
      @file_asset_no_deriv.delete
    end

    context "FileAsset creation for FTK file" do
      it "creates no FileAsset object if the file doesn't exist" do
        ff_intermed = FactoryGirl.build(:ftk_file)
        ff_intermed.export_path = "non_existing_file"
        @assembler.create_file_asset(@ftk_item_object, ff_intermed).should be_nil
      end
      it "creates a FileAsset object with the correct relationships and descriptive metadata" do
        @file_asset.should be_instance_of(FileAsset) # model
        @file_asset.ids_for_outbound(:is_part_of).should == ["#{@ftk_item_pid.gsub("info:fedora/", "")}"]
        # descMetadata:
        desc_md_ds_fields_hash = @file_asset.datastreams["descMetadata"].fields
        # extent value (file size) is computed by FileAsset.add_file_datastream
        desc_md_ds_fields_hash[:extent][:values].first.should match(/(bytes|KB|MB|GB|TB)$/)
        desc_md_ds_fields_hash[:title][:values].should == ["FileAsset for FTK file #{@ftk_file_intermed.filename}"]
      end
      it "creates the correct FileAsset object for the FTK file and its display derivative" do
        # datastreams:  DC, RELS-EXT, descMetadata, content, derivative-html
        confirm_datastreams(@file_asset,["DC", "RELS-EXT", "descMetadata", "content", "derivative_html"])
        # content file datastream:
        @content_file_ds.dsLabel.should ==  @ftk_file_intermed.filename 
        @content_file_ds.dsLabel.should == "BURCH1" 
        #  can't get mimeType here, even though it is set when the datastream is written to Fedora
        # display derivative datastream
        @deriv_file_ds.dsLabel.should ==  @ftk_file_intermed.display_deriv_fname
        @deriv_file_ds.dsLabel.should == "BURCH1.htm"
        @deriv_file_ds.mimeType.should == "text/html"
      end
      it "creates the correct FileAsset object when there is no display derivative" do
        confirm_datastreams(@file_asset_no_deriv,["DC", "RELS-EXT", "descMetadata", "content"])
        @file_asset_no_deriv.datastreams.size.should == 4
        @content_file_ds_no_deriv.dsLabel.should ==  @ftk_file_intermed_no_deriv.filename 
        @content_file_ds_no_deriv.dsLabel.should == "foofile.txt" 
        @content_file_ds_no_deriv.mimeType.should == "text/plain"
        @file_asset_no_deriv.datastreams["derivative_html"].should be_nil
       end
       it "creates the correct FileAsset object when the content file has no extension" do
         # see  "creates the correct FileAsset object for the FTK file and its display derivative"
       end
       it "creates the correct FileAsset object when the content file has an extension" do
         # see "creates the correct FileAsset object when there is no display derivative"
       end
    end  # context "FileAsset creation for FTK file"

    context "contentMetadata" do
      before(:all) do
        @content_md_doc = Nokogiri::XML(@assembler.build_content_metadata(@ftk_file_intermed, "ftk_item_pid", @file_asset))
        @content_md_no_deriv_doc = Nokogiri::XML(@assembler.build_content_metadata(@ftk_file_intermed_no_deriv, "ftk_item_pid2", @file_asset_no_deriv))
      end
      it "creates no contentMetadata if there is no FileAsset" do
        @assembler.build_content_metadata(@ftk_file_intermed, "ftk_item_pid", nil).should be_nil
      end
      it "creates the correct contentMetdata element" do
        @content_md_doc.xpath("/contentMetadata/@objectId").to_s.should eql("ftk_item_pid")
        @content_md_doc.xpath("/contentMetadata/@type").to_s.should eql("file")
        @content_md_no_deriv_doc.xpath("/contentMetadata/@objectId").to_s.should eql("ftk_item_pid2")
        @content_md_no_deriv_doc.xpath("/contentMetadata/@type").to_s.should eql("file")
      end
      it "creates the correct resource element" do
        @content_md_doc.xpath("/contentMetadata/resource").size.should eql(1)
        @content_md_doc.xpath("/contentMetadata/resource/@objectId").to_s.should eql(@file_asset.pid)
        @content_md_doc.xpath("/contentMetadata/resource/@type").to_s.should eql("file")
        # id attribute on resource element is just a unique identifier
        @content_md_doc.xpath("/contentMetadata/resource/@id").to_s.should eql(@content_file_ds.dsLabel)
        @content_md_doc.xpath("/contentMetadata/resource/@id").to_s.should eql("BURCH1")
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource").size.should eql(1)
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/@objectId").to_s.should eql(@file_asset_no_deriv.pid)
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/@type").to_s.should eql("file")
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/@id").to_s.should eql(@content_file_ds_no_deriv.dsLabel)
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/@id").to_s.should eql("foofile.txt")
      end
      it "creates the correct file elements when there is a display derivative" do
        # id attribute on file element must match the label of the datastream in the FileAsset object
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='#{@content_file_ds.dsLabel}']").should_not be_nil
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1']").should_not be_nil
#        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1']/@format").to_s.should eql("BINARY")  # skipping for Hypatia demo
#        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1']/@mimetype").to_s.should eql("application/octet-stream")  # skipping for Hypatia demo
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1']/@size").to_s.should match(/^\d+$/)
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1']/@preserve").to_s.should eql("yes")
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1']/@publish").to_s.should eql("yes")
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1']/@shelve").to_s.should eql("yes")
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1']/location/@type").to_s.should eql("datastreamID")
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1']/location/text()").to_s.should eql(@content_file_ds.dsid)
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1']/checksum[@type='md5']/text()").to_s.should eql(@ftk_file_intermed.md5)
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1']/checksum[@type='md5']/text()").to_s.should eql("4E1AA0E78D99191F4698EEC437569D23")
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1']/checksum[@type='sha1']/text()").to_s.should eql(@ftk_file_intermed.sha1)
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1']/checksum[@type='sha1']/text()").to_s.should eql("B6373D02F3FD10E7E1AA0E3B3AE3205D6FB2541C")
        # id attribute on file element must match the label of the datastream in the FileAsset object
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='#{@deriv_file_ds.dsLabel}']").should_not be_nil
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1.htm']").should_not be_nil
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1.htm']/@format").to_s.should eql("HTML")
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1.htm']/@mimetype").to_s.should eql("text/html")
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1.htm']/@size").to_s.should match(/^\d+$/)
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1.htm']/@preserve").to_s.should eql("yes")
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1.htm']/@publish").to_s.should eql("yes")
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1.htm']/@shelve").to_s.should eql("yes")
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1.htm']/location/@type").to_s.should eql("datastreamID")
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1.htm']/location/text()").to_s.should eql(@deriv_file_ds.dsid)
# TODO:  compute md5 and sha1 for deriv html (?)
#        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1.htm']/checksum[@type='md5']/text()").to_s.should eql(Digest::MD5.hexdigest(@deriv_file_ds.content))
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1.htm']/checksum[@type='md5']/text()").to_s.should eql("906aec05a5a8de7391daec5681eedcf6")
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1.htm']/checksum[@type='sha1']/text()").to_s.should eql(Digest::SHA1.hexdigest(@deriv_file_ds.content))
        @content_md_doc.xpath("/contentMetadata/resource/file[@id='BURCH1.htm']/checksum[@type='sha1']/text()").to_s.should eql("84742c2bbe55ce0847145a6c47dc411435932a7e")
      end
      it "creates the correct file element for when there is no display derivative" do
        # id attribute on file element must match the label of the datastream in the FileAsset object
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='#{@content_file_ds.dsLabel}']").should_not be_nil
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='foofile.txt']").should_not be_nil
#        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='foofile.txt']/@format").to_s.should eql("BINARY")  # skipping for Hypatia demo
#        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='foofile.txt']/@mimetype").to_s.should eql("application/octet-stream")  # skipping for Hypatia demo
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='foofile.txt']/@size").to_s.should match(/^\d+$/)
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='foofile.txt']/@preserve").to_s.should eql("yes")
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='foofile.txt']/@publish").to_s.should eql("yes")
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='foofile.txt']/@shelve").to_s.should eql("yes")
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='foofile.txt']/location/@type").to_s.should eql("datastreamID")
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='foofile.txt']/location/text()").to_s.should eql(@content_file_ds_no_deriv.dsid)
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='foofile.txt']/checksum[@type='md5']/text()").to_s.should eql(@ftk_file_intermed_no_deriv.md5)
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='foofile.txt']/checksum[@type='md5']/text()").to_s.should eql("4E1AA0E78D99191F4698EEC437569D23")
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='foofile.txt']/checksum[@type='sha1']/text()").to_s.should eql(@ftk_file_intermed_no_deriv.sha1)
        @content_md_no_deriv_doc.xpath("/contentMetadata/resource/file[@id='foofile.txt']/checksum[@type='sha1']/text()").to_s.should eql("B6373D02F3FD10E7E1AA0E3B3AE3205D6FB2541C")
      end
    end  # context "contentMetadata"
  end # context "FtkItem assets"

  context "create_hypatia_ftk_item" do
    before(:all) do
      delete_fixture(@coll_pid)
      import_fixture(@coll_pid)
      @assembler = FtkItemAssembler.new(:collection_pid => @coll_pid)
      @assembler.ftk_report = "spec/fixtures/ftk/Gould_FTK_Report.xml"
      @assembler.file_dir = "spec/fixtures/ftk"
      @assembler.display_derivative_dir = "spec/fixtures/ftk/display_derivatives" 
      @ff_intermed = FactoryGirl.build(:ftk_file)
      @ftk_item = @assembler.create_hypatia_ftk_item(@ff_intermed)
    end
    it "doesn't build an object if the file doesn't exist" do
      ff_intermed = FactoryGirl.build(:ftk_file)
      ff_intermed.export_path = "non_existing_file"
      @assembler.create_hypatia_ftk_item(ff_intermed).should be_nil
    end
    it "is a kind of HypatiaFtkItem object" do
      @ftk_item.should be_kind_of(HypatiaFtkItem)
    end
    it "includes all the expected metadata datastreams" do
      ['contentMetadata','descMetadata','rightsMetadata','DC','RELS-EXT'].each do |datastream_name|
         @ftk_item.datastreams[datastream_name].should_not eql(nil)
      end
      # NOTE:  rights metadata is actually populated in the process method, as it is constant for all objects
      #  it is just a nil or empty object here
    end
    it "has correct descMetadata" do
      desc_md_ds = @ftk_item.datastreams["descMetadata"]
      desc_md_ds.term_values(:display_name).should == [@ff_intermed.filename]
      desc_md_ds.term_values(:ftk_id).should == [@ff_intermed.id]
      desc_md_ds.term_values(:date_last_modified).should == [@ff_intermed.file_modified_date]
    end
    it "has correct RELS-EXT" do
      # our factory ftk file isn't matching any disk images, so relationship to collection object
      @ftk_item.relationships(:is_member_of_collection).size.should eql(1)
      @ftk_item.relationships(:is_member_of_collection).first.should eql("info:fedora/#{@coll_pid}")
    end
    it "has correct contentMetadata" do
      content_md_ds = @ftk_item.datastreams["contentMetadata"]
      content_md_ds.term_values(:content_filename).should == [@ff_intermed.filename]
      content_md_ds.term_values(:content_size).first.should match(/^\d+$/)
      content_md_ds.term_values(:content_md5).should == [@ff_intermed.md5]
      content_md_ds.term_values(:html_filename).should == ["#{@ff_intermed.filename}.htm"]
      content_md_ds.term_values(:html_format).should == ["HTML"]
    end
    it "has a file object with an isPartOf relationship" do
      part_of = ActiveFedora::Predicates.find_graph_predicate(:is_part_of)
      @ftk_item.inbound_relationships(part_of).length.should eql(1)
    end
    it "has parts populated with FileAsset for file and display derivative" do
      @ftk_item.parts.size.should be(1)
      part = @ftk_item.parts.first
      part.should be_kind_of(FileAsset)
      content_ds = part.datastreams["content"]
      # the (file) datastream of a FileAsset part object should have a label value = filename
      content_ds.dsLabel.should == @ff_intermed.filename
      html_ds = part.datastreams["derivative_html"]
      html_ds.dsLabel.should == "#{@ff_intermed.filename}.htm"
    end
  end # context "create_hypatia_ftk_item"


  context "processing a directory" do
    before(:all) do
      delete_fixture(@coll_pid)
      import_fixture(@coll_pid)
      remove_fixture_ftk_report_objects
      @assembler = FtkItemAssembler.new(:collection_pid => @coll_pid)
      ftk_report = Pathname.new(File.join(File.dirname(__FILE__), "../fixtures/ftk/Gould_FTK_Report.xml")).realpath.to_s
      ftk_file_dir = Pathname.new(File.join(File.dirname(__FILE__), "../fixtures/ftk")).realpath.to_s
      display_derivative_dir = Pathname.new(File.join(File.dirname(__FILE__), "../fixtures/ftk/display_derivatives")).realpath.to_s
      @assembler.process(ftk_report, ftk_file_dir, display_derivative_dir)
      solr_response = get_solr_response_for_ftk_report_objects
      @solr_docs = solr_response.docs
      # BURCH1 is the only document with an actual file and a display derivative
      @burch1_solr_doc = @solr_docs.find { |d| d[:filename_display].first == "BURCH1"}
      @burch1_hfi = HypatiaFtkItem.load_instance(@burch1_solr_doc[:id])
    end

    it "creates the HypatiaFtkItem objects for the existing file indicated in FTK report, with correct filenames" do
      @solr_docs.size.should be(1)
      @burch1_solr_doc.should_not be_nil
      @burch1_solr_doc[:has_model_s].first.should == "info:fedora/afmodel:HypatiaFtkItem"
    end
    
    it "creates correct rightsMetadata for each file in the FTK report" do
      rights_md_ds = @burch1_hfi.datastreams["rightsMetadata"]
      # "public" group can only have one permission group:  read, not discover
      rights_md_ds.term_values(:discover_access).first.should_not match(/^\s*public\s*$/)
      rights_md_ds.term_values(:read_access).first.should match(/^\s*public\s*$/)
      rights_md_ds.term_values(:edit_access).first.should match(/^\s*archivist\s*$/)
    end
    it "creates correct descMetadata for each file in the FTK report" do
      desc_md_ds = @burch1_hfi.datastreams["descMetadata"]
      desc_md_ds.term_values(:digital_origin).should == ["born digital"]
    end
    it "creates correct RELS-EXT for each file in the FTK report" do
      rels_ext_ds = @burch1_hfi.datastreams["RELS-EXT"]
      # all files in the FTK report match no disk image
      @burch1_hfi.collections.size.should be(1)
      @burch1_hfi.sets.size.should be(0)
      @burch1_hfi.parts.size.should be(1)
    end
    it "creates correct contentMetadta for FileAsset with file and display derivative file" do
      content_md_ds = @burch1_hfi.datastreams["contentMetadata"]
      content_md_ds.term_values(:content_filename).should == ["BURCH1"]
      content_md_ds.term_values(:content_ds_id).should == ["content"]
      content_md_ds.term_values(:content_md5).should == ["E769B03076214F30766258C8BC857F7E"]
      content_md_ds.term_values(:html_filename).should == ["BURCH1.htm"]
      content_md_ds.term_values(:html_ds_id).should == ["derivative_html"]
      content_md_ds.term_values(:html_mimetype).should == ["text/html"]
    end
  end # context "processing a directory" 

end # describe FtkItemAssembler

#------------- supporting methods --------------------

# Create four HypatiaDiskImageItem fixture objects for testing is_member_of relationships
# @return [Array] of four FtkDiskImageItema
def build_fixture_disk_objects
  # ensure we don't have duplicates when we don't want to
  clean_fixture_disk_objects 

  di_txt_file = Pathname.new(File.join(File.dirname(__FILE__), "/../fixtures/ftk/disk_images/CM5551212.001.txt")).realpath.to_s
  fdi_intermed = FtkDiskImage.new(di_txt_file)
  di_assembler = FtkDiskImageItemAssembler.new(:disk_image_files_dir => ".", :computer_media_photos_dir => ".")

  fdi_intermed.disk_name = "single_match"
  fdi_intermed.case_number = "cn1"
  di1 = di_assembler.build_object(fdi_intermed)
  fdi_intermed.disk_name = "mult_match"
  fdi_intermed.case_number = "cn2"
  di2 = di_assembler.build_object(fdi_intermed)
  fdi_intermed.disk_name = "mult_match"
  fdi_intermed.case_number = "cn3"
  di3 = di_assembler.build_object(fdi_intermed)
  di3.add_relationship(:is_member_of_collection, "info:fedora/#{@coll_pid}")
  di3.save
  fdi_intermed.disk_name = "no_match"
  fdi_intermed.case_number = "cn4"
  di4 = di_assembler.build_object(fdi_intermed)
  di4.add_relationship(:is_member_of_collection, "info:fedora/#{@coll_pid}")
  di4.save
  return [di1, di2, di3, di4]
end

# Remove from Fedora/Solr all instances of the HypatiaDiskImageItem fixtures
def clean_fixture_disk_objects
  solr_params = {}
  solr_params[:q] = "title_t:(single_match OR mult_match OR no_match)"
  solr_params[:qt] = 'standard'
  solr_params[:fl] = 'id'
  solr_response = Blacklight.solr.find(solr_params)
  solr_response.docs.each do |doc|
    ActiveFedora::Base.load_instance(doc[:id]).delete    
  end
end

# Remove from Fedora/Solr all instances of the HypatiaFtkItem fixtures from the fixture FTK report
def remove_fixture_ftk_report_objects
  solr_response = get_solr_response_for_ftk_report_objects
  solr_response.docs.each do |doc|
    ActiveFedora::Base.load_instance(doc[:id]).delete    
  end
end

# do a Solr query to get the objects generated by calling @assembler.process 
# on the fixture FTK report file
def get_solr_response_for_ftk_report_objects
  solr_params = {}
  solr_params[:q] = "filename_t:(BU3A5 OR BUR3-1 OR BURCH1 OR BURCH2 OR BURCH3 OR Description.txt)"
  solr_params[:qt] = 'standard'
  solr_params[:fl] = 'id,filename_display,has_model_s'
  solr_params[:rows] = '50'
  solr_response = Blacklight.solr.find(solr_params)
end
