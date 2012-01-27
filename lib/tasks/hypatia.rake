require 'rspec/core/rake_task'
require "cucumber/rake/task"
require "active-fedora"

# number of seconds to pause after issuing commands to return a git repos to its pristine state (e.g. make jetty squeaky clean)
GIT_RESET_WAIT = 7

namespace :hypatia do

  desc "Execute Continuous Integration build (docs, tests with coverage)"
  task :ci do   
    Rake::Task["hypatia:doc"].invoke
    Rake::Task["hypatia:db:test:reset"].invoke
    Rake::Task["hypatia:jetty:test:reset_then_config"].invoke

    require 'jettywrapper'
    jetty_params = {
      :jetty_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty'),
      :quiet => false,
      :jetty_port => 8983,
      :solr_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty/solr'),
      :fedora_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty/fedora/default'),
      :startup_wait => 30
      }
    
# FIXME:  does this make jetty run in TEST environment???
    error = Jettywrapper.wrap(jetty_params) do
      Rake::Task["hypatia:spec"].invoke
      Rake::Task["hypatia:cucumber:fixtures_then_run"].invoke
    end
    raise "test failures: #{error}" if error

  end

#============= TESTING TASKS (SPECS, FEATURES) ================

  desc "Run the hypatia specs.  Must have jetty already running and fixtures loaded."
  Spec::Rake::SpecTask.new(:spec) do |t|
#     t.spec_opts = ['--options', "/spec/spec.opts"]
    t.pattern = 'test_support/spec/**/*_spec.rb'
    t.rcov = true
    t.rcov_opts = IO.readlines("test_support/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
  end


  desc "Easieset way to run cucumber features. (Re)loads fixtures and runs cucumber tests.  Must have jetty already running."
  task :cucumber => "cucumber:fixtures_then_run"

  namespace :cucumber do
# NOTE: features fail if test solr is empty. - must load features fresh first (?)
    desc "Run cucumber features for hypatia. Must have jetty already running and fixtures loaded."
    task :run do
      puts %x[cucumber --color --format progress test_support/features]
      raise "Cucumber tests failed" unless $?.success?
    end

    desc "(Re)loads fixtures, then runs cucumber features.  Must have jetty already running."
    task :fixtures_then_run => :environment do
      old_env = Rails.env
      Rails.env = 'test'
      Rake::Task["hypatia:fixtures:refresh"].invoke
      Rake::Task["hypatia:cucumber:run"].invoke
      Rails.env = old_env
    end    

  end # hypatia:cucumber namespace

#============= JETTY TASKS ================
  namespace :jetty do
    
    desc "return a jetty instance to its pristine state, then load our Solr and Fedora config files - takes 'test' as an arg, o.w. resets development jetty"
    task :reset_then_config, :env do |t, args|
      if args.env && args.env.downcase == "test"
        Rake::Task["hypatia:jetty:test:reset_then_config"].invoke
      else
        Rake::Task["hypatia:jetty:dev:reset_then_config"].invoke
      end
    end
    
    desc "return a jetty to its pristine state, as pulled from git - takes 'test' as an arg, o.w. resets development jetty"
    task :reset, :env  do |t, args|
      if args.env && args.env.downcase == "test"
        Rake::Task["hypatia:jetty:test:reset"].invoke
      else
        Rake::Task["hypatia:jetty:dev:reset"].invoke
      end
    end

# FIXME: !!!!!!!!!!! use separate jetty for test and for dev
    
    namespace :test do
      desc "return test jetty to its pristine state, as pulled from git"
      task :reset do
        system("cd jetty && git reset --hard HEAD && git clean -dfx & cd ..")
        sleep GIT_RESET_WAIT
      end
      
      desc "return test jetty to its pristine state, then load our Solr and Fedora config files"
      task :reset_then_config do
        Rake::Task["hypatia:jetty:test:reset"].invoke
        Rake::Task["hydra:jetty:config"].invoke
      end
    end # namespace hypatia:jetty:test

    namespace :dev do
      desc "return development jetty to its pristine state, as pulled from git"
      task :reset do
        system("cd jetty && git reset --hard HEAD && git clean -dfx & cd ..")
        sleep GIT_RESET_WAIT
      end

      desc "return development jetty to its pristine state, then load our Solr and Fedora config files"
      task :reset_then_config do
        Rake::Task["hypatia:jetty:dev:reset"].invoke
        Rake::Task["hydra:jetty:config"].invoke
      end
    end # namespace hypatia:jetty:dev
        
  end # namespace hypatia:jetty

#============= FIXTURE TASKS ================
  namespace :fixtures do
    FIXTURE_PIDS = [
      "hypatia:fixture_coll",
      "hypatia:fixture_intermed1",
      "hypatia:fixture_intermed2",
      "hypatia:fixture_intermed3",
      "hypatia:fixture_item1",
      "hypatia:fixture_item2",
      "hypatia:fixture_item3",
      
      "hypatia:fixture_coll2",
      "hypatia:fixture_file_asset_ead_for_coll",
      "hypatia:fixture_file_asset_image_for_coll",

      "hypatia:fixture_media_item",
      "hypatia:fixture_file_asset_dd_for_media_item",
      "hypatia:fixture_file_asset_image1_for_media_item",
      "hypatia:fixture_file_asset_image2_for_media_item",
      
      "hypatia:fixture_ftk_file_item",
      "hypatia:fixture_file_asset_for_ftk_file_item",
    ]

    desc "Load Hypatia fixtures"
    task :load do
      # pids are converted to file names by substituting : for _
      load_fixtures(FIXTURE_PIDS)
    end
    
    desc "Remove Hypatia fixtures"
    task :delete do
      delete_all(FIXTURE_PIDS)
    end
    
    desc "Remove then load all Hypatia fixtures"
    task :refresh do
      refresh_fixtures(FIXTURE_PIDS)
    end
  end # hypatia:fixtures namespace


#============= DATABASE TASKS ================
  namespace :db do 
    namespace :test do 
      desc "Recreate test databases from scratch"
      task :reset do 
        old_env = Rails.env # just in case
        Rails.env = "test"
        Rake::Task['db:drop'].invoke
        Rake::Task['db:migrate'].invoke
        Rails.env = old_env  # be safe
      end
    end
  end

#============= DOC TASKS ================
  # :doc task  using yard
  begin
    require 'yard'
    require 'yard/rake/yardoc_task'
    project_root = File.expand_path("#{File.dirname(__FILE__)}/../../")
    doc_destination = File.join(project_root, 'doc')
    if !File.exists?(doc_destination) 
      FileUtils.mkdir_p(doc_destination)
    end

    YARD::Rake::YardocTask.new(:doc) do |yt|
      readme_filename = 'README.textile'
      textile_docs = []
      Dir[File.join(project_root, "*.textile")].each_with_index do |f, index| 
        unless f.include?("/#{readme_filename}") # Skip readme, which is already built by the --readme option
          textile_docs << '-'
          textile_docs << f
        end
      end
      yt.files   = Dir.glob(File.join(project_root, '*.rb')) + 
                   Dir.glob(File.join(project_root, 'app', '**', '*.rb')) + 
                   Dir.glob(File.join(project_root, 'lib', '**', '*.rb')) + 
                   textile_docs
      yt.options = ['--output-dir', doc_destination, '--readme', readme_filename]
    end
  rescue LoadError
    desc "Generate YARD Documentation"
    task :doc do
      abort "Please install the YARD gem to generate rdoc."
    end
  end # doc task

end # hypatia namespace

namespace :repo do
  desc "Delete and re-import the object identified by pid" 
  task :refresh => [:delete,:load]
  
  desc "Delete the object identified by pid. Example: rake repo:delete pid=demo:12"
  task :delete => :init do
    if ENV["pid"].nil? 
      puts "You must specify a valid pid.  Example: rake repo:delete pid=demo:12"
    else
      delete(ENV["pid"])
    end
  end
  desc "Load the object located at the provided path or identified by pid. Example: rake repo:load path=spec/fixtures/demo_12.foxml.xml"
  task :load => :init do
    if !ENV["path"].nil? 
      filename = ENV["path"]
    elsif !ENV["pid"].nil?
      pid = ENV["pid"]
      filename = fixture_path(pid)
    else
      puts "You must specify a path to the object or provide its pid.  Example: rake repo:load path=spec/fixtures/demo_12.foxml.xml"
      return
    end
    load_fixture(filename)
  end

  
  desc "Init ActiveFedora configuration" 
  task :init do
    init_active_fedora
  end
end # repo namespace

#-------------- SUPPORTING METHODS -------------

def fixture_path(pid)
  File.join("test_support","fixtures","#{pid.gsub(":","_")}.foxml.xml")
end

def index_fedora_doc(id)
    af_base = ActiveFedora::Base.load_instance(id)
    the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
    if the_model.nil?
      the_model = DcDocument
    end
    af_base = af_base.adapt_to(the_model)
    af_base.send :update_index
end

# load a Fedora object from foxml, putting it in Fedora and indexing it into
# Solr
def load_foxml(file, pid)
  ENV["fixture"] = file
  Rake::Task["hydra:import_fixture"].reenable
  Rake::Task["hydra:import_fixture"].invoke  
  
  # we do this because hydra:import_fixture task is written so a provided PID
  #  implies a fixture in spec/fixtures, and a provided fixture file 
  #  implies no solr indexing.  Harrumph.
  if !pid.nil?
    solrizer = Solrizer::Fedora::Solrizer.new 
    solrizer.solrize(pid) 
  end 
end

def init_active_fedora(opts={})
  if opts[:environment].nil? and !ENV["environment"].nil? 
    opts[:environment] = ENV["environment"]
  end
  opts[:environment] = 'test' # I can't hunt this down right now
  # If Fedora Repository connection is not already initialized, initialize it using ActiveFedora defaults
  ActiveFedora.init(opts) unless ActiveFedora.config_loaded? # Thread.current[:repo]  
end

# load all the fixtures in the passed array of fixture pids
#   pid is converted to file name by substituting : for _
def load_fixtures(fixture_pids)
  fixture_pids.each { |f|  
    load_fixture_from_pid(f) 
  }
end

def load_fixture_from_pid(pid)
  filename = fixture_path(pid)
  load_fixture_from_file(filename)
end

# load a fixture object
#   pid is converted to file name by substituting : for _
def load_fixture_from_file(filename)
  if !filename.nil? and File.exist?(filename)
    init_active_fedora
    puts "Loading '#{filename}' in #{ActiveFedora.fedora_config[:url]}"
    file = File.new(filename, "r")
    result = ActiveFedora::RubydoraConnection.instance.connection.ingest(:file=>file.read)
    if result
      puts "The object has been loaded as #{result.body}"
      pid = result.body
      index_fedora_doc(pid) 
    else
      puts "Failed to load the foxml at #{filename}."
    end
  end    

end

# delete all the objects in the passed array of pids (from Fedora and Solr)
def delete_all(pids)
  pids.each { |pid|  
    delete(pid) 
  }
end

# delete an object (from Fedora and Solr)
def delete(pid)
  init_active_fedora
  if pid.nil? 
    puts "You must specify a valid pid.  Example: rake repo:delete pid=demo:12"
  else
    begin
      ActiveFedora::Base.load_instance(pid).delete
      puts "Deleted '#{pid}' from #{ActiveFedora.fedora_config[:url]}"
    rescue ActiveFedora::ObjectNotFoundError
      puts "The object #{pid} has already been deleted (or was never created)."
    rescue Errno::ECONNREFUSED => e
        puts "Can't connect to Fedora! Are you sure jetty is running?"
    end
  end
end

# refresh (delete, then load) all the fixtures in the passed array of pids
#   pid is converted to file name by substituting : for _
def refresh_fixtures(fixture_pids)
  delete_all(fixture_pids)
  load_fixtures(fixture_pids)
end
