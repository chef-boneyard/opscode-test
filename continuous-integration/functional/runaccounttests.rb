#!/usr/bin/env ruby

# TODO:
# how do i give ruby capability to my remote servers?

require "yaml"

class << @self
  require "#{File.dirname(__FILE__)}/cmdutil"
end

def kill_opscode_account
  pid = nil
  File.popen("ps uxaw|grep merb|grep 4042|grep -v grep", "r") do |ps|
    ps.each_line do |line|
      fields = line.split(/\s+/)
      pid_str = fields[1]
      if pid_str =~ /\d+/
        pid = pid_str.to_i
        puts line
      end
    end
  end

  if pid
    cmd = "sudo kill -TERM #{pid}"
    puts "Killing opscode-account process at #{pid} with SIGTERM"
    run cmd
  else
    puts "No opscode-account process found, skipping.."
  end
end

def start_opscode_account
  cmd = "slice -a thin -N -p 4042 -l debug"
  Dir.chdir("opscode-account") do |dir|
    run cmd
  end
end

puts "** Test setup: Bootstrapping CouchDB..."
run "ruby #{File.dirname(__FILE__)}/bootstrap_couchdb.rb opscode-test/continuous-integration/functional/authorization_design_documents.couchdb-dump"

puts "** Test setup: Killing current opscode-account.."
kill_opscode_account


# Determine the path for cucumber binary
gem_path = `gem env gemdir`.chomp
cucumber_path = "#{gem_path}/bin/cucumber"
if !File.exists?(cucumber_path)
  cucumber_path = "cucumber"
end

# If JUNIT XML output was specified, build a command line.
cucumber_options = "--format pretty"
if ARGV.length == 2 && ARGV[0] == "--junit-out"
  cucumber_options = "--format junit --out '#{ARGV[1]}'"
end

puts
puts
puts "********************"
puts "*      TESTS       *"
puts "********************"
Dir.chdir("opscode-account") do |dir|
  run "#{cucumber_path} #{cucumber_options}"
end

puts "** Starting opscode-account back up.."
start_opscode_account
