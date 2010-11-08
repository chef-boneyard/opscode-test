#!/usr/bin/env ruby

# - If --chef-branch BRANCH is passed in, we will use that branch for what's
#   checked out into /srv/chef/current. Otherwise, we default to 'pl-master'.
# - If --chef-remote REMOTE is passed in, use that as the remote for chef.
#   Defaults to 'opscode'. NOTE/TODO: if the remote doesn't already exist,
#   we don't add it.
# - First argument (beyong --chef...) is the project to run, e.g., 
#   opscode-account.
# - Second argument is 'rake' or 'cucumber', which runs either run-rake.sh
#   or run-cucumber.sh, respectively.
# - All other arguments are passed to run-rake or run-cucumber.

def switch_chef_branch(chef_remote_wanted, chef_branch_wanted)
  Dir.chdir("/srv/chef/current") do |dir|
    puts "Fetching chef refs from remote #{chef_remote_wanted}:"
    if !(system "git fetch #{chef_remote_wanted}")
      raise "Couldn't fetch from remote #{chef_remote_wanted}"
    end
  
    puts "Switching chef branch to #{chef_branch_wanted}:"
    if !(system "git checkout -f #{chef_remote_wanted}/#{chef_branch_wanted}")
      raise "Couldn't switch to branch #{chef_remote_wanted}/#{chef_branch_wanted}"
    end
  
    puts "Restarting chef-server (OSS):"
    system "/etc/init.d/chef-server force-restart"
  end
end

DEFAULT_BRANCH = "pl-master"
DEFAULT_REMOTE = "opscode"

# See if a chef branch was specified.
chef_branch_arg_index = ARGV.find_index("--chef-branch")
chef_branch_wanted = if chef_branch_arg_index
  ARGV.delete_at(chef_branch_arg_index)
  ARGV.delete_at(chef_branch_arg_index)
else
  DEFAULT_BRANCH
end

# See if a chef remote was specified.
chef_remote_arg_index = ARGV.find_index("--chef-remote")
chef_remote_wanted = if chef_remote_arg_index
  ARGV.delete_at(chef_remote_arg_index)
  ARGV.delete_at(chef_remote_arg_index)
else
  DEFAULT_REMOTE
end

# project name first.
project_name = ARGV.shift

# then 'rake' or 'cucumber'
rake_or_cucumber = if ARGV[0] == "rake"
  "run-rake.sh"
elsif ARGV[0] == "cucumber"
  "run-cucumber.sh"
else
  nil
end

puts "project_name #{project_name}, rake_or_cucumber #{rake_or_cucumber}"

# Check arguments.
unless (rake_or_cucumber && project_name)
  puts <<EOM
#{$0} [--chef-branch BRANCH] [--chef-remote REMOTE] PROJECT_NAME (rake|cucumber) [RAKE_OR_CUCUMBER_OPTIONS ...]

  Runs either run-rake.sh or run-cucumber.sh with the options PROJECT_NAME then 
  RAKE_OR_CUCUMBER_OPTIONS. First switches chef in /srv/chef/current to the given 
  branch (default #{DEFAULT_BRANCH}) and remote (default #{DEFAULT_REMOTE}). After 
  switching branches, the OSS chef server will be restarted with with force-restart,
  then rake or cucumber will be passed the options PROJECT_NAME, 
  RAKE_OR_CUCUMBER_OPTIONS...
  
  EXAMPLES:
    #{$0} --chef-branch master --chef-remote timh opscode-chef cucumber -t @api
    #{$0} --chef-branch pl-master chef rake spec
EOM
  exit
end

# Pull off the 'rake' or 'cucumber' we just parsed.
ARGV.shift

# Actually do the switch.
switch_chef_branch(chef_remote_wanted, chef_branch_wanted)

# Run run-rake/run-cucumber.
begin
  cmdline = ["/srv/opscode-test/current/continuous-integration/hudson/#{rake_or_cucumber}", project_name, *ARGV]
  puts "cmdline = #{cmdline.inspect}"
  
  system *cmdline
  
  ret_code = $?.exitstatus
ensure
  if chef_remote_wanted != DEFAULT_REMOTE || chef_branch_wanted != DEFAULT_BRANCH
    switch_chef_branch(DEFAULT_REMOTE, DEFAULT_BRANCH)
  end
end

# return with the same error code that run-rake/run-cucumber returned.
puts "#{rake_or_cucumber} returned exit code #{ret_code}."
exit ret_code

