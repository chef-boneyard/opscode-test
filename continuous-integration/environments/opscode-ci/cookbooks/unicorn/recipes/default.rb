#
# Cookbook Name:: unicorn
# Recipe:: default
#
# Copyright 2009, Opscode, Inc
#
# All rights reserved - Do Not Redistribute
#

gems = {
  "unicorn" => nil
}

gem_dir = Dir['/srv/localgems/gems/*']

gems.each do |name,version|
  unless gem_dir.find{|d|d=~/#{name}/}
    script "install_#{name}_local" do
      interpreter "bash"
      user "root"
      code <<-EOH
        export GEM_HOME=/srv/localgems
        export GEM_PATH=/srv/localgems
        export PATH="/srv/localgems/bin:$PATH"
        gem install #{name} #{version.nil? ? '' : "--version #{version}" }
      EOH
    end
  end
end
