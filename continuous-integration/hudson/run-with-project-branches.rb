#!/usr/bin/env ruby

require 'socket'

# - Run the given project, e.g., opscode-account, with the branches specified
#   and their corresponding services running with the right branch's code. See
#   usage message text below.
DEFAULT_REMOTE = "opscode"   # if no remote specified, use this.
BASE_REMOTE = nil            # after we're done, go back to this remote ...
BASE_BRANCH = "deploy"       #   and branch
SERVICES_TO_RESTART = {
  "opscode-chef" => ["opscode-chef", "opscode-webui"],
  "opscode-account" => ["opscode-account"],
  "opscode-authz" => ["opscode-authz"],
  
  # TODO, tim 2010-11-10: Always restart opscode-solr-indexer and opscode-expander 
  # when changing chef branches, even though it's really an either/or option
  # (solr-indexer goes with 'master'; expander goes with 'pl-master')
  "chef" => ["chef-server", "opscode-solr", "opscode-solr-indexer", "opscode-expander"]  # platform services are bundler-ized
}

def usage
  puts <<-EOM
#{$0} [--branch PROJ1_NAME=[PROJ1_REMOTE/]PROJ1_BRANCH ...] RUN_PROJ_NAME (rake|cucumber) CUCUMBER_OPTIONS

  Runs cucumber or rake with the given CUCUMBER_OPTIONS for the given 
  RUN_PROJ_NAME, by executing 
  /srv/hudson/continuous-integration/hudson/run-cucumber.sh or run-rake.sh.
  If specified in --branch options, switches branches of those projects before
  running the tests and restarts affected services (see SERVICES_TO_RESTART in
  #{$0}). Will switch back to base branch (#{BASE_BRANCH}) after running 
  the tests then restart the affected services again.

EXAMPLES:
  #{$0} --branch opscode-account=billing --branch opscode-chef=billing opscode-chef cucumber -t @webui
  #{$0} --branch chef=pl-master chef rake spec
  #{$0} --branch chef=master chef rake spec
  
  EOM
end

def wait_for_solr_to_listen(project_name)
  max_wait = 120
  num_waited = 0
  
  puts "--- waiting up to #{max_wait} seconds for SOLR to start on port 8983"
  STDOUT.sync = true
  solr_running = false
  while !solr_running && num_waited <= max_wait
    begin
      sock = TCPSocket.open('127.0.0.1', 8983)
      sock.close
      solr_running = true
    rescue Errno::ECONNREFUSED
      # it's ok..loop
      print "."
      sleep 1
      num_waited += 1
    end
  end
  
  if solr_running
    puts "\n--- waited #{num_waited} seconds before SOLR was ready on port 8983"
  else
    puts "\n--- SOLR wasn't running on port 8983 after #{max_wait} seconds... moving on."
  end
end

def do_system(cmd)
  puts "--- #{cmd}"
  system cmd
end

# Switches to remote_wanted/branch_wanted.
def switch_branch(project_name, remote_wanted, branch_wanted)
  branch_str = remote_wanted ? "#{remote_wanted}/#{branch_wanted}" : branch_wanted
  
  puts "+++ Switching branch for #{project_name} to #{branch_str}"
  Dir.chdir("/srv/#{project_name}/current") do |dir|
    if remote_wanted
      if !(do_system "git fetch #{remote_wanted}")
        raise "Couldn't fetch from remote #{remote_wanted}"
      end
    end
    
    if !(do_system "git checkout -f #{branch_str}")
      raise "Couldn't switch to branch #{branch_str}"
    end
    
    if File.exist?("Gemfile.lock")
      if !(do_system "bundle install --deployment")
        raise "Couldn't run bundler"
      end
    end

    services_to_restart = SERVICES_TO_RESTART[project_name]
    services_to_restart.each do |service|
      # Remove the SOLR directory so it regenerates its schema. We can't just
      # remove the directory, though, as /srv on Hudson is NFS-mounted, and 
      # sometimes there are .nfs lock files. So move the directory then try 
      # to remove it.
      if service == 'opscode-solr'
        do_system "mv /srv/opscode-solr/shared/system/solr /srv/opscode-solr/shared/system/solr.bak   # move out of the way before nuking it, as NFS may make the rm -rf not work"
        do_system "rm -fr /srv/opscode-solr/shared/system/solr.bak"
        do_system "mkdir /srv/opscode-solr/shared/system/solr"
        Dir.chdir("/srv/opscode-solr/shared/system/solr") do |dir|
          puts "--- Untarring SOLR home in #{dir}"
          do_system "tar zxvf /srv/chef/current/chef-solr/solr/solr-home.tar.gz"
        end
        do_system "chown -R opscode:opscode /srv/opscode-solr/shared/system/solr"
      end
      
      do_system "/etc/init.d/#{service} force-restart"

      # Wait up to two minutes for SOLR to be listening on 8983.
      if service == 'opscode-solr'
        wait_for_solr_to_listen(project_name)
      end
    end
  end
  puts
end

def parse_command_line
  $tobranch_project_branch = Hash.new
  $tobranch_project_remote = Hash.new

  # Keep pulling off --branch lines until we exhaust them.
  begin
    branch_arg_index = ARGV.find_index("--branch")
    if branch_arg_index
      ARGV.delete_at(branch_arg_index)
      branch_arg_str = ARGV.delete_at(branch_arg_index)

      # opscode-account=opscode/master
      # opscode-chef=master
      # chef=pl-master
      if branch_arg_str =~ /^(.+)=(.+)$/
        proj_name = $1
        branch = $2
        if branch =~ /^(.+)\/(.+)$/
          remote = $1
          branch = $2
        else
          remote = DEFAULT_REMOTE
        end

        unless SERVICES_TO_RESTART[proj_name]
          raise "Don't know what to restart for #{proj_name}: update SERVICES_TO_RESTART in #{$0}"
        end

        $tobranch_project_remote[proj_name] = remote
        $tobranch_project_branch[proj_name] = branch
      else
        raise "Don't know how to parse #{branch_arg_str}: should be form PROJNAME=[REMOTE/]BRANCH"
      end
    end
  end while branch_arg_index


  # project name first.
  $project_name = ARGV.shift

  # then 'rake' or 'cucumber'
  $rake_or_cucumber = case ARGV.shift
  when "rake"
    "run-rake.sh"
  when "cucumber"
    "run-cucumber.sh"
  else
    nil
  end

  # Check arguments.
  unless ($rake_or_cucumber && $project_name)
    usage
    exit
  end

end

parse_command_line

puts "*** project_name #{$project_name}, rake_or_cucumber #{$rake_or_cucumber}"
puts "*** tobranch_project_remote = #{$tobranch_project_remote.inspect}; tobranch_project_branch = #{$tobranch_project_branch.inspect}"
puts

begin
  # Actually switch the branches.
  puts "+++ Switching branches ..."
  $tobranch_project_branch.keys.each do |tobranch_proj_name|
    switch_branch(tobranch_proj_name, $tobranch_project_remote[tobranch_proj_name], $tobranch_project_branch[tobranch_proj_name])
  end

  # Run run-rake/run-cucumber.
  cmdline = ["/srv/opscode-test/current/continuous-integration/hudson/#{$rake_or_cucumber}", $project_name, *ARGV]
  cmdline_str = cmdline.map {|arg| (arg =~ /\s+/) ? "\"#{arg}\"" : arg}.join(" ")
  puts "*** Running test #{cmdline_str}"
  
  system *cmdline
  
  ret_code = $?.exitstatus
ensure
  # Switch the branches back.
  puts
  puts "+++ Switching branches back..."
  $tobranch_project_branch.keys.each do |tobranch_proj_name|
    switch_branch(tobranch_proj_name, BASE_REMOTE, BASE_BRANCH)
  end
  
end

# return with the same error code that run-rake/run-cucumber returned.
puts "*** #{$rake_or_cucumber} returned exit code #{ret_code}."
exit ret_code

