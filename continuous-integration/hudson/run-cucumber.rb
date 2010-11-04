#!/usr/bin/env ruby

# - First argument is path within /srv to run, i.e. the project.
# - If --chef-branch BRANCH is passed in, we will use that branch for what's
#   checked out into /srv/chef/current. Otherwise, we default to 'pl-master'.
# - If --chef-remote REMOTE is passed in, use that as the remote for chef.
#   Defaults to 'opscode'. NOTE/TODO: if the remote doesn't already exist,
#   we don't add it.
# - All other arguments are passed to cucumber.

def restart_couchdb
  system "/etc/init.d/couchdb restart"

  # Kill any lingering couchjs processes
  puts "Existing couchjs processes:"
  system "ps uxaw | grep couchjs | grep -v grep"
  system "killall couchjs"
end

def switch_chef_branch
  chef_branch_arg_index = ARGV.find_index("--chef-branch")
  chef_branch_wanted = if chef_branch_arg_index
    ARGV.delete_at(chef_branch_arg_index)
    ARGV.delete_at(chef_branch_arg_index)
  else
    "pl-master"
  end
  
  chef_remote_arg_index = ARGV.find_index("--chef-remote")
  chef_remote_wanted = if chef_remote_arg_index
    ARGV.delete_at(chef_remote_arg_index)
    ARGV.delete_at(chef_remote_arg_index)
  else
    "opscode"
  end
  

  Dir.chdir("/srv/chef/current") do |dir|
    puts "Fetching chef refs from remote #{chef_remote_wanted}:"
    if !(system "git fetch #{chef_remote_wanted}")
      raise "Couldn't fetch from remote #{chef_remote_wanted}"
    end
    
    puts "Switching chef branch to #{chef_branch_wanted}:"
    if !(system "git checkout -f #{chef_remote_wanted}/#{chef_branch_wanted}")
      raise "Couldn't switch to branch #{chef_remote_wanted}/#{chef_branch_wanted}"
    end
    
    # TODO: This may be unneeded work if the cukes are being run against another
    # project, but this is a reasonable place to put it.
    puts "Restarting chef-server (OSS):"
    if !(system "/etc/init.d/chef-server restart")
      raise "Couldn't restart OSS chef server"
    end
  end
end

# Capture the starting working directory as Hudson expects JUnit output to
# be written in a directory under this, so we'll pass this to Cucumber so
# the JUnit formatter can get at it.
starting_pwd = Dir.pwd


# Switch /srv/chef/current to the right branch, defaulting to pl-master.
switch_chef_branch()

# Check arguments.
unless ARGV.length > 0
  puts <<EOM
#{$0} project_name [--chef-branch BRANCH] [--chef-remote REMOTE] [CUCUMBER_OPTIONS ...]

  Runs cucumber for the given project, by first cd'ing into /srv/$project_name/current.
  Switches chef (/srv/chef/current) to the specified branch, or pl-master if it's not
  specified. After switching branches, OSS chef-server will be restarted.

  Cucumber is invoked with arguments to cause it to output JUnit-style XML output,
  which is written in a subdirectory of the CWD, "junit_output".
EOM
end

# Restart couchdb and kill all couchjs processes.
restart_couchdb()


# Setup environment so everything runs from localgems
ENV['GEM_HOME'] = "/srv/localgems"
ENV['GEM_PATH'] = "/srv/localgems"
ENV['PATH'] = "/srv/localgems/bin:" + ENV['PATH']



# Remove all the JUnit output files first so no stale results are around.
system "rm -f \"#{starting_pwd}\"/junit_output/*"

# Switch to the working directory of the project and run the cukes!
ret_code = nil
project_name = ARGV.shift
Dir.chdir("/srv/#{project_name}/current") do |project_dir|
  args_quoted = ARGV.map { |arg| "'#{arg}'" }.join(" ")
  partial_cmdline = "cucumber #{args_quoted} --format junit --out \"#{starting_pwd}\"/junit_output"
  
  # Run with bundler if appropriate..
  cmdline = if File.exist?("Gemfile.lock")
    "bundle exec cucumber #{partial_cmdline}"
  else
    partial_cmdline
  end
  
  puts "Executing #{cmdline}"
  system cmdline
  
  ret_code = $?.exitstatus
end

# Touch the mtime of the JUnit output files to work around the fact that the
# NFS server current time may be different than the slave current time, which if
# the times are different enough, causes Hudson to ignore all the JUnit output.
system "ruby /srv/opscode-test/current/continuous-integration/hudson/touch-files.rb \"#{starting_pwd}\"/junit_output"

# return with the same error code that cucumber returned.
exit ret_code

