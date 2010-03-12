module OpscodeWorld
  module Tempfiles
    
    def tmpdir
      @tmpdir ||= begin
        dir = File.join(Dir.tmpdir, "chef_integration")
        FileUtils.rm_rf(dir) if File.exist?(dir)

        FileUtils.mkdir_p(dir)
        cleanup_dirs << dir
        dir
      end
    end

    def cleanup_files
      @cleanup_files ||= Array.new
    end

    def cleanup_dirs
      @cleanup_dirs ||= Array.new
    end
    
  end
end

After do
  cleanup_files.each do |file|
    system("rm #{file}")
  end
  cleanup_dirs.each do |dir|
    system("rm -rf #{dir}")
  end
end

World(OpscodeWorld::Tempfiles)