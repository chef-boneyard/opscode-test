#!/usr/bin/ruby

require 'rubygems'
require 'rubygems/specification'

class BambooSandboxer
  BAMBOO_BUILD_ROOT = '/home/tim/devel/Bamboo/xml-data/build-dir/'
  SYSTEM_GEMS_ROOT = '/var/lib/gems/1.8'

  GITPROJ_TO_BAMBOO = {
    'mixlib-log' => 'MLLOG',
    'mixlib-authentication' => 'MLAUTHEN',
    'mixlib-authorization' => 'MLAUTHOR',
    'mixlib-config' => 'MLCONFIG',
    'mixlib-cli' => 'MLCLI',
    'ohai' => 'OHAI',
    'chef' => 'CHEF',
    'opscode-chef' => 'OPSCHEF',
    'opscode-rest' => 'OPSREST',
    'opscode-audit' => 'OPSAUDIT'
  }

  attr_reader :installto_rubygems_root_dir
  attr_accessor :debug

  def initialize(installto_rubygems_root_dir)
    @installto_rubygems_root_dir = installto_rubygems_root_dir
    @queued_procs = Array.new
    @queued_gemnames = Hash.new

    # TODO mkdir
    Dir.mkdir(@installto_rubygems_root_dir)
    Dir.mkdir(@installto_rubygems_root_dir + "/gems")
    Dir.mkdir(@installto_rubygems_root_dir + "/specifications")
  end

  def cleanup()
    puts "cleanup #{@installto_rubygems_root_dir}: not implemented"

    # TODO rmdir
  end

  # Return the dependencies of a given spec, recursively. Dependencies
  # will only ever be system dependencies; this will never return a
  # bamboo dependency. In other words, if while recursively walking the
  # dependency tree it runs into a dep that is a bamboo dependency, 
  # it will skip it.
  # .. given a Spec, return an array of Spec's.
  def get_dependencies(spec, visited_deps = {})
    if !spec.is_a?(Gem::Specification)
      raise ArgumentError, "spec should be a Gem::Specification: #{spec} : #{spec.class}"
    end

    # handle circular dependencies by keeping track of spec's that we've
    # visited.
    visited_deps[spec.name] = 1

    res = Array.new
  
    spec.dependencies.each do |dep|
      if GITPROJ_TO_BAMBOO[dep.name]
        puts "get_dependencies #{spec.name}: ignoring bamboo dependency '#{dep.name}' (need to include with -d?)"
        next
      end

      dep_spec_array = Gem.source_index.find_name(dep.name)
      if dep_spec_array && !dep_spec_array.empty?
        dep_spec = dep_spec_array[0]
        res << dep_spec
        unless visited_deps[dep_spec.name]
          res += get_dependencies(dep_spec, visited_deps)
        end
      else
        raise ArgumentError, "get_dependencies #{spec.name}: missing system dependency '#{dep.name}' -- install it!"
      end
    end

    res
  end

  # Return the Spec for a system-installed GEM
  def spec_from_system(gemname)
    array_res = Gem.source_index.find_name(gemname)
    if array_res.nil?
      raise ArgumentError, "could not resolve system GEM: #{gemname}"
    end

    if array_res.length > 1
      puts "spec_from_system: '#{gemname}' resolves to more than one result: #{array_res.join(' ')}; returning first"
    end
    array_res[0]
  end

  # Return the Spec for a GEM given a gemspec filename
  def spec_from_file(gemspec_filename)
    Gem::Specification.load(gemspec_filename)
  end

  def location_sandbox_gemspec(gemspec)
    "#{@installto_rubygems_root_dir}/specifications/#{gemspec.name}-#{gemspec.version.version}.gemspec"
  end
  def location_sandbox_files(gemspec)
    "#{@installto_rubygems_root_dir}/gems/#{gemspec.name}-#{gemspec.version.version}"
  end

  def location_system_gemspec(gemspec)
    "#{SYSTEM_GEMS_ROOT}/specifications/#{gemspec.name}-#{gemspec.version.version}.gemspec"
  end
  def location_system_files(gemspec)
    "#{SYSTEM_GEMS_ROOT}/gems/#{gemspec.name}-#{gemspec.version.version}"
  end

  def location_bamboo_build(bamboo_projname, bamboo_branch)
    "#{BAMBOO_BUILD_ROOT}/#{bamboo_projname}-#{bamboo_branch}/checkout"
  end

  # -private-
  # Given a Bamboo build directory, return any gemspec file, if one exists.
  def _bamboo_get_gemspec_filenames(bamboo_dirname)
    # Generate gemspec's based on some predefined rake task names.
    # Call rake to figure out the name of the task that generates the gemspec file.
    Dir.chdir(bamboo_dirname) do |dir|
      # TODO: Our projects use different tasks for generating their gemspec.
      # Make it consistent?
      allowed_tasks = ['make_spec', 'gem', 'gemspec']

      puts "running 'rake -T' to determine rake tasks: looking for any of: #{allowed_tasks.join(', ')}" if @debug

      found_task = nil
      IO::popen("rake -T") do |io|
        io.each_line do |line|
          if line =~ /rake (\w+)\s*\#.*/
            task = $1
            puts " rake task = '#{task}'" if @debug

            if allowed_tasks.include?(task)
              found_task = task
            end
          end
        end
      end

      puts "_bamboo_get_gemspec_filenames: found_task = '#{found_task}'"
      if found_task
        puts "_bamboo_get_gemspec_filenames: calling 'rake #{found_task}' to generate gemspec"
        system "rake #{found_task}"
      end
    end

    # look for gemspecs both in the root directory and any sub-directories
    # one level down.
    gemspec_filenames = Dir.glob("#{bamboo_dirname}/*.gemspec") + Dir.glob("#{bamboo_dirname}/*/*.gemspec")

    gemspec_filenames
  end
  private :_bamboo_get_gemspec_filenames

  
  def install_bamboo_deps(git_projname, git_branch)
    bamboo_projname = GITPROJ_TO_BAMBOO[git_projname]
    if bamboo_projname.nil?
      raise ArgumentError, "Project with git name #{git_projname} unknown -- cannot map to Bamboo project name"
    end

    # 
    bamboo_dirname = location_bamboo_build(bamboo_projname, git_branch.upcase)
    if !File.directory?(bamboo_dirname)
      raise ArgumentError, "Bamboo checkout for #{git_projname} in dir '#{bamboo_dirname}' doesn't exist or is not a directory"
    end

    # TODO look for gemspec
    #  jeweler-maintained needs 'rake build' before the .gemspec exists
    #  others should have .gemspec file in directory already
    gemspec_filenames = _bamboo_get_gemspec_filenames bamboo_dirname
    if gemspec_filenames.empty?
      raise ArgumentError, "Cannot find gemspec(s) for Bamboo project '#{git_projname}' in dir '#{bamboo_dirname}'"
    end

    gemspec_filenames.each do |gemspec_filename|
      #puts "gemspec_filename exists, reading spec from it: #{gemspec_filename}"
      puts "install_bamboo_deps #{git_projname}: processing spec #{gemspec_filename}"
      spec = spec_from_file(gemspec_filename)

      dependencies = get_dependencies(spec)
      #puts "dependencies for #{git_projname} = " + dependencies.join(', ')
      dependencies.each do |dep|
        queue_system_dep dep.name
      end
    end

    bamboo_dirname
  end
  private :install_bamboo_deps

  def queue_bamboo_dep(git_projname, git_branch)
    if !@queued_gemnames[git_projname].nil?
      return false
    end
    
    bamboo_dirname = install_bamboo_deps(git_projname, git_branch)

    puts "queue rake install: #{bamboo_dirname}" if @debug
    @queued_procs << proc {
      Dir.chdir(bamboo_dirname) do |dir|
        #system("rake install")
        puts "execute rake install: #{Dir.pwd}; ENV[GEM_PATH] is #{ENV['GEM_PATH']}"
        
        system "rake install"
        if $? != 0
          raise "rake install for #{git_projname} returned #{$?}"
        end
      end
    }

    @queued_gemnames[git_projname] = true
    true
  end

  # The last step - the project to run 'rake spec' on.
  def test_bamboo_proj(git_projname, git_branch)
    bamboo_dirname = install_bamboo_deps(git_projname, git_branch)

    puts "queue rake spec: #{bamboo_dirname}" if @debug
    @queued_procs << proc {
      Dir.chdir(bamboo_dirname) do |dir|
        puts
        puts "-- EXECUTE RAKE SPEC --"
        puts "execute rake spec: #{Dir.pwd}"

        system "rake spec"
        sysret = $?

        puts "rake spec returned: #{sysret}"
        exit (sysret == 0 ? 0 : 1)
      end
    }

    true
  end

  # Queue a system dependency (managed by RubyGems) and any of its dependencies.
  def queue_system_dep(gemname)
    # Do not queue the same GEM more than once.
    if !@queued_gemnames[gemname].nil?
      return false
    end

    spec = spec_from_system(gemname)
    if spec.nil?
      raise ArgumentError, "No such system dependency: #{gemname}"
    end

    loc_sys_files = location_system_files spec
    loc_sys_gemspec = location_system_gemspec spec

    loc_sb_files = location_sandbox_files spec
    loc_sb_gemspec = location_sandbox_gemspec spec

    if !File.directory?(loc_sys_files)
      raise ArgumentError, "System files for #{gemname} does not exist in: #{loc_sys_files}"
    end

    if !File.exists?(loc_sys_gemspec)
      raise ArgumentError, "System gemspec for #{gemname} does not exist in: #{loc_sys_gemspec}"
    end

    @queued_gemnames[gemname] = true

    # Recurse and add the dependencies of this system GEM.
    dependencies = get_dependencies(spec)
    #puts "queue_system_dep: dependencies for #{gemname} = " + dependencies.join(', ')
    dependencies.each do |dep|
      queue_system_dep dep.name
    end

    puts "queue symlink: #{loc_sys_files} -> #{loc_sb_files}" if @debug
    puts "queue symlink: #{loc_sys_gemspec} -> #{loc_sb_gemspec}" if @debug
    @queued_procs << proc {
      if File.directory?(loc_sb_files)
        # It's possible that one of the rake install's we've run has done a 'gem install'
        # on a system dep. In that case, we wouldn't have updated our @queued_gemnames
        # hash, but the dependency was already installed into the sandbox.
        puts "skipping symlink: #{loc_sys_files} -> #{loc_sb_files} as directory already exists in sandbox" if @debug
        return
      end
      puts "execute symlink: #{loc_sys_files} -> #{loc_sb_files}" if @debug
      File.symlink(loc_sys_files, loc_sb_files)
      
      puts "execute symlink: #{loc_sys_gemspec} -> #{loc_sb_gemspec}" if @debug
      File.symlink(loc_sys_gemspec, loc_sb_gemspec)
    }

    true
  end

  def execute_queue()
    ENV['GEM_PATH'] = @installto_rubygems_root_dir
    ENV['GEM_HOME'] = @installto_rubygems_root_dir
    ENV['RUBYLIB'] = @installto_rubygems_root_dir

    # Execute the queued up steps.
    @queued_procs.each do |step|
      step.call()
    end
  end

end



# gemsb -d bamboo_built_dependency_gem_name -s public_gem_name bamboo_proj_to_run_spec

sandbox = BambooSandboxer.new "/tmp/gem-sandbox.#{$$}"
['rspec', 'gemcutter', 'jeweler'].each do |sysdep|
  sandbox.queue_system_dep sysdep
end

tobuild_projname = nil

puts
puts "--- PROCESS COMMAND LINE / QUEUE ---"
while (ARGV.length > 0) do
  arg = ARGV.shift

  if "-d" == arg
    # specify project name as proj/branch if you want something other than
    # 'master'.
    projname = ARGV.shift
    if projname =~ /(.+)\/(.+)/
      projname = $1
      branchname = $2

      sandbox.queue_bamboo_dep projname, branchname.upcase
    else
      sandbox.queue_bamboo_dep projname, 'MASTER'
    end
  elsif "-s" == arg
    gemname = ARGV.shift

    sandbox.queue_system_dep gemname
  elsif "-v" == arg
    sandbox.debug = true
  else
    if !tobuild_projname.nil?
      raise ArgumentError, "Can only list one project name on the command line."
    end

    tobuild_projname = arg

    if tobuild_projname =~ /(.+)\/(.+)/
      tobuild_projname = $1
      tobuild_branchname = $2

      sandbox.test_bamboo_proj tobuild_projname, tobuild_branchname.upcase
    else
      sandbox.test_bamboo_proj tobuild_projname, 'MASTER'
    end
  end

end

puts
puts "--- EXECUTE QUEUE ---"
sandbox.execute_queue

# Return with goodness if we've gotten here.
puts "--- EXIT WITH GOODNESS ---"
exit 0
