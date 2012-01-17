# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
ROOT = File.expand_path(File.join(File.dirname(__FILE__),'..','..'))
require File.expand_path(File.join(ROOT,'config','environment'))
require 'rspec/autorun'
require 'rspec/rails'

Dir[File.expand_path(File.join(ROOT,'lib','**','*.rb'))].each {|f| require f}
# Uncomment the next line to use webrat's matchers
#require 'webrat/integrations/rspec-rails'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

RSpec.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = ROOT + '/test_support/spec/fixtures/'

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses its own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  #
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner
  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  # describe "...." do
  # fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses its own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  #
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner

  # similar to File.join, build the path of the requested object below the fixtures directory
  def fixtures_path(*args)
    rails_root = File.expand_path(File.join(File.dirname(__FILE__),'..','..'))
    parts = [rails_root, 'test_support', 'fixtures'].concat args
    File.expand_path(File.join(*parts))
  end
  def active_fedora_fixture(file)
    File.new(fixtures_path(file))
  end
  
  # import a fixture
  def import_fixture(pid)
    filename = fixtures_path("#{pid.gsub(":","_")}.foxml.xml")    
    file = File.new(filename, "r")
    repo = ActiveFedora::RubydoraConnection.instance
    result = repo.connection.ingest(:pid=>pid, :file=>file.read)
    if result
      if !pid.nil?
        solrizer = Solrizer::Fedora::Solrizer.new 
        solrizer.solrize(pid) 
      end    
    else
      raise "Failed to ingest the fixture."
    end
  end

  # delete a fixture
  def delete_fixture(pid)
    begin
      ActiveFedora::Base.load_instance(pid).delete
    rescue ActiveFedora::ObjectNotFoundError
    rescue Errno::ECONNREFUSED => e
      raise "Can't connect to Fedora! Are you sure jetty is running?"
    end
  end
  
  def confirm_datastreams(obj, expected_dsids)
    actual = obj.datastreams.keys
    expected_dsids.each do |dsid|
      actual.delete(dsid).should eql(dsid)
    end
    actual.length.should eql(0)
  end
end
