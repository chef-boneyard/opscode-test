
# Meant to be mixed into another class
@server_pids = []
at_exit do
  puts "# server pids:"
  puts "sudo kill -9 #{@server_pids.join(' ')}"
  puts "sudo kill #{@server_pids.join(' ')}"
end


# synchronously calls the cmd.
# returns: pid of cmd executed
def run(cmd, ignore_error = false)
  puts "RUN CMD: #{cmd}"
  #system cmd
  pid = fork
  if pid.nil?
    exec cmd
  else
    Process.waitpid pid
    ret = $?
  end

  if ret.exitstatus != 0
    if ignore_error
      puts "Warning: subprocess #{cmd} returned non-zero exit: #{ret.exitstatus}"
    else
      raise "Error: subprocess #{cmd} returned non-zero exit: #{ret.exitstatus}"
    end
  end

  pid
end

def run_server(dirname_or_cmd, cmd_or_nil = nil)
  if cmd_or_nil.nil?
    dirname = "."
    cmd = dirname_or_cmd
    log_filename = "logs/#{cmd}.log"
  else
    dirname = dirname_or_cmd
    cmd = cmd_or_nil

    shortcmd = dirname.split('/')[-1]
    log_filename = "logs/#{shortcmd}.log"
  end
  log_file = File.open(log_filename, "w")
  log_file.sync = true

  puts "RUN SERVER: (cd #{dirname}; #{cmd}) >& #{log_filename}"

  pipe_reader, pipe_writer = IO.pipe

  pid = fork
  if pid.nil?
    $stdin.reopen pipe_reader
    pipe_writer.close

    $stderr.reopen log_file
    $stdout.reopen log_file

    Dir.chdir(dirname) do |dir|
      $stdout.puts "RUN SERVER: pid #{$$}, pwd #{Dir.pwd}, cmd #{cmd}"
      exec "sudo #{cmd}"
    end
    raise "This line should not be reachable - exec failed for cmd #{cmd} in dir #{dirname}"
  else
    log_file.close
    pipe_reader.close
    pipe_writer.close # subprocess should get immediate end of file, as don't write anything to it before losing it.
  end
  puts "RUN SERVER: #{cmd} pid is #{pid}"
  
  @server_pids << pid
  pid

end  

def git(url, branchname = 'master')
  if url =~ /^(.*)\/([^\/]+)$/
    dir = $2
    if dir =~ /^(.+)\.git$/
      dir = $1
    end
    
    if File.directory?(dir)
      puts "# GIT PULL #{url}"
      Dir.chdir(dir) do |_|
        puts "cd #{Dir.pwd}"
        if branchname == 'master'
          run "git checkout master"
        else
          run "git checkout origin/#{branchname}"
        end
        run "git pull origin #{branchname}"
      end
    else
      puts "# GIT CLONE #{url}"
      run "git clone #{url}"
      Dir.chdir(dir) do |_|
        puts "cd #{Dir.pwd}"
        if branchname != 'master'
          run "git checkout origin/#{branchname}"
        else
          run "git checkout master"
        end
      end
    end
    puts
  else
    raise ArgumentError, "cannot figure out directory name from git url #{url}"
  end

  puts
end

def make(subdir)
  puts "# MAKE #{subdir}"
  Dir.chdir(subdir) do |_|
    puts "cd #{Dir.pwd}"
    run "make"
  end

  puts
end

def make_install(subdir)
  puts "# MAKE INSTALL #{subdir}"
  Dir.chdir(subdir) do |_|
    puts "cd #{Dir.pwd}"
    run "sudo make install"
  end

  puts
end

def rake_install(subdir)
  puts "# RAKE INSTALL #{subdir}"
  Dir.chdir(subdir) do |_|
    puts "cd #{Dir.pwd}"
    run "sudo rake install"
  end

  puts
end
