require 'spec/rake/spectask'
require "cucumber/rake/task"
require File.join(File.dirname(__FILE__), "/../../config/environment.rb")
require File.join(File.dirname(__FILE__), "/../ftk_item_assembler")
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "/.."))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "/../../app/models"))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "/../../vendor/plugins/hydra-head/lib/"))


# number of seconds to pause after issuing commands to return a git repos to it's pristine state (e.g. make jetty squeaky clean)
GIT_RESET_WAIT = 7

namespace :hypatia do
  
  namespace :load do
    
    ##########################
    # Gould collection loading
    ##########################
    namespace :gould do
        gould_collection_pid = "hypatia:gould_collection"
      
        desc "Load all Gould data"
        task :all do
          Rake::Task["hypatia:load:gould:ftk_disk_items"].invoke
          Rake::Task["hypatia:load:gould:ftk_file_items"].invoke
        end
      
        desc "Build disk objects (do this first)"
        task :ftk_disk_items do  
          disk_image_files_dir = "/data_raw/Stanford/M1437\ Gould/Disk\ Image" 
          computer_media_photos_dir = "/data_raw/Stanford/M1437\ Gould/Computer\ Media\ Photo" 
          assembler = FtkDiskImageItemAssembler.new(:collection_pid => gould_collection_pid, :disk_image_files_dir => disk_image_files_dir, :computer_media_photos_dir => computer_media_photos_dir)
          assembler.process
        end
      
        desc "Build ftk objects"
        task :ftk_file_items do  
          f = FtkItemAssembler.new(:collection_pid => gould_collection_pid)
          gould_report = "/data_raw/Stanford/M1437\ Gould/FTK\ xml/Report.xml"
          file_dir = "/data_raw/Stanford/M1437\ Gould/FTK\ xml/"
          display_derivative_dir = "/data_raw/Stanford/M1437\ Gould/Display\ Derivatives"
          f.process(gould_report,file_dir,display_derivative_dir)
        end
  
    end
    ###########################
    # Xanadu collection loading
    ###########################
    namespace :xanadu do
      xanadu_collection_pid = "hypatia:xanadu_collection"
      
      desc "Load all Xanadu data"
      task :all do
        Rake::Task["hypatia:load:xanadu:ftk_disk_items"].invoke
      end
            
      desc "Build Xanadu disk objects"
      task :ftk_disk_items do  
        disk_image_files_dir = "/data_raw/Stanford/M1292\ Xanadu/Disk\ Image" 
        computer_media_photos_dir = "/data_raw/Stanford/M1292\ Xanadu/Computer\ Media\ Photo" 
        assembler = FtkDiskImageItemAssembler.new(:collection_pid => xanadu_collection_pid, :disk_image_files_dir => disk_image_files_dir, :computer_media_photos_dir => computer_media_photos_dir)
        assembler.process
      end
    end
    
    ###########################
    # Cheuse collection loading
    ###########################
    namespace :cheuse do
      
      cheuse_collection_pid = "hypatia:cheuse_collection"
      
      desc "Load all Cheuse data"
      task :all do
        Rake::Task["hypatia:load:cheuse:ftk_disk_items"].invoke
        Rake::Task["hypatia:load:cheuse:ftk_file_items"].invoke
      end
      
      desc "Build disk objects (do this first)"
      task :ftk_disk_items do  
        disk_image_files_dir = "/data_raw/Virginia/cheuse/oldFiles/diskImages" 
        computer_media_photos_dir = "/data_raw/Virginia/cheuse/oldFiles/photos" 
        assembler = FtkDiskImageItemAssembler.new(:collection_pid => cheuse_collection_pid, :disk_image_files_dir => disk_image_files_dir, :computer_media_photos_dir => computer_media_photos_dir)
        assembler.process
      end
      desc "Build Cheuse ftk file objects"
      task :ftk_file_items do   
        f = FtkItemAssembler.new(:collection_pid => cheuse_collection_pid)
        report = "/data_raw/Virginia/cheuse/CheuseFTKReport/Report.xml"
        file_dir = "/data_raw/Virginia/cheuse/CheuseFTKReport"
        f.process(report,file_dir)
      end
    end
    
    ############################
    # Creeley collection loading
    ############################
    namespace :creeley do
      
      creeley_collection_pid = "hypatia:creeley_collection"
      
      desc "Load all Creeley data"
      task :all do
        Rake::Task["hypatia:load:creeley:ftk_disk_items"].invoke
        Rake::Task["hypatia:load:creeley:ftk_file_items"].invoke
      end
      
      desc "Build disk objects (do this first)"
      task :ftk_disk_items do  
        disk_image_files_dir = "/data_raw/Stanford/M0662\ Creeley/Disk\ Image/" 
        computer_media_photos_dir = "/data_raw/Stanford/M0662\ Creeley/Computer\ Media\ Photo" 
        assembler = FtkDiskImageItemAssembler.new(:collection_pid => creeley_collection_pid, :disk_image_files_dir => disk_image_files_dir, :computer_media_photos_dir => computer_media_photos_dir)
        assembler.process
      end
      desc "Build Creeley ftk file objects"
      task :ftk_file_items do  
        f = FtkItemAssembler.new(:collection_pid => creeley_collection_pid)
        report = "/data_raw/Stanford/M0662\ Creeley/FTK\ xml/Report.xml"
        file_dir = "/data_raw/Stanford/M0662\ Creeley/FTK\ xml/files/"
        display_derivative_dir = "/data_raw/Stanford/M0662\ Creeley/Display\ Derivatives/"
        f.process(report,file_dir,display_derivative_dir)
      end
    end
  end
end