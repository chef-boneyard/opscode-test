#
# Cookbook Name:: opscode-ci-piab
# Recipe:: base 
#
# Copyright 2009, Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "erlang_binary"
include_recipe "runit"

execute "add_opscode_gemrepo" do
  not_if "gem sources --list | grep gems.opscode.com"
  command "gem sources --add http://gems.opscode.com"
end

# update rubygems if < 1.3.6
bash "upgrade to rubygems 1.3.6" do
  user "root"
  cwd "/tmp"
  not_if { (Gem::Version.new(Gem::VERSION) <=> Gem::Version.new("1.3.6")) >= 0 }
  code <<-EOH
    wget http://rubyforge.org/frs/download.php/69365/rubygems-1.3.6.tgz
    tar xvf rubygems-1.3.6.tgz
    cd rubygems-1.3.6
    ruby setup.rb --no-format-executable
  EOH
end

group "opscode" do
  gid 5049
end

user "opscode" do
  comment "Opscode User"
  shell "/bin/sh"
  uid 5049
  gid 5049
end

directory "/home/opscode" do
  mode 0755
  owner "opscode"
  group "opscode"
end

directory "/home/opscode/.ssh" do
  mode 0700
  owner "opscode"
  group "opscode"
end

include_recipe "opscode-github"

directory "/etc/opscode" do
  mode 0770
  owner "root"
  group "opscode"
end

remote_file "/etc/opscode/azs.pem" do
  source "azs.pem"
  owner "opscode"
  group "opscode"
  mode "0600"
end

remote_file "/etc/opscode/webui_pub.pem" do
  source "webui_pub.pem"
  owner "opscode"
  group "opscode"
  mode "0600"
end

# Prepare the audit directory
directory "/var/spool/opscode" do
  owner "opscode"
  group "opscode"
  mode "0770"
end

directory "/var/spool/opscode/audit" do
  owner "opscode"
  group "opscode"
  mode "0770"
end

package "libxml2" 
package "libxml2-dev"
package "libsqlite3-dev"
package "libxslt1-dev"
package "libxml-simple-ruby"

__gems = {
  "net-ssh-multi" => nil,
  "rack" => '1.1.0',
  "actionpack" => "2.3.8",
#  "chef" => nil,
  "fog" => nil,
  #"couchrest" => '0.23',
  #"aws-s3" => nil,
  "ruby-hmac" => nil,
  "uuidtools" => nil,
#  "merb-slices" => '1.0.15',
#  "merb-assets" => '1.0.15',
#  "merb-helpers" => '1.0.15',
#  "merb-haml" => '1.0.15',
#  "merb-param-protection" => "1.0.15",
  "merb-slices" => '1.1.3',
  "merb-assets" => '1.1.3',
  "merb-helpers" => '1.1.3',
  "merb-haml" => '1.1.3',
  "merb-param-protection" => "1.1.3",
  "rspec" => '1.3.0',
  "libxml-ruby" => nil,
  "rake" => nil,
  "rack-test" => '0.5.4',
  "thin" => nil,
  "amqp" => nil,
  "open4" => nil,
  "cucumber" => nil,
  "gherkin" => '2.1.4',
  "rest-client" => nil,
  "jeweler" => nil,
  "json" => '1.4.2',
  "coderay" => nil,
  "mongrel" => nil,
  "camping" => '1.5.180',
  "sqlite3-ruby" => '1.2.4',
  "ci_reporter" => '1.6.2',
}

# These GEM's are used for chef-server and parkplace, but not needed for other 
# packages like opscode-chef or opscode-account, as they use bundler.
gems = {
  'rspec' => '1.3.0',
  'rspec-rails' => '1.3.2',
  'gemcutter' => '0.6.1',
  'jeweler' => '1.4.0',
  'cucumber' => '0.8.5',
  'ci_reporter' => '1.6.2',
  'bunny' => '0.6.0',
  'moneta' => '0.6.0',
  'uuidtools' => '2.1.1',
  'merb-slices' => '1.1.3',
  'merb-assets' => '1.1.3',
  'merb-helpers' => '1.1.3',
  'merb-haml' => '1.1.3',
  'merb-param-protection' => '1.1.3',
  'treetop' => '1.4.9',
  'unicorn' => '2.0.1',
  'fog' => '0.2.30',
  
  # parkplace
  'mongrel' => '1.1.5',
  'metaid' => '1.0',
  'camping' => '1.5.180',
  'sqlite3-ruby' => '1.2.4',
}

gem_dir = Dir['/srv/localgems/gems/*']

gems.each do |name,version|
  unless gem_dir.find{|d|d=~/\/#{name}-/}
    script "install_#{name}_local" do
      interpreter "bash"
      user "root"
        #gem install -i /srv/localgems #{name} #{version.nil? ? '' : "--version #{version}" }
      code <<-EOH
        export GEM_HOME=/srv/localgems
        export GEM_PATH=/srv/localgems
        export PATH="/srv/localgems/bin:$PATH"
        gem install #{name} #{version.nil? ? '' : "--version #{version}" }
      EOH
    end
  end
end

# These are also just needed by chef-server.
opscode_gems = [
  "mixlib-log",
  "mixlib-cli",
  "mixlib-config",
  "opscode-rest",
  "mixlib-authentication",
  "mixlib-authorization",
  "ohai",
  "couchrest",
  "mixlib-localization",
  "aws-s3",
  "ohai"
]

opscode_gems.each do |name|

  directory "/srv/#{name}" do
    owner "root"
    group "root"
    mode '2775'
    recursive true
  end

  deploy_revision "gem-#{name}-src" do
    revision (node[:environment]["#{name}-revision"] || node[:environment]['default-revision'])
    repository 'git@github.com:' + (node[:environment]["#{name}-remote"] || node[:environment]['default-remote']) + "/#{name}.git"
    remote (node[:environment]["#{name}-remote"] || node[:environment]['default-remote'])
    symlink_before_migrate Hash.new
    #user "opscode"
    #group "opscode"
    user "root"
    group "root"
    deploy_to "/srv/#{name}"
    migrate false
    before_symlink do
      bash "install_#{name}_local" do
        user "root"
        cwd "#{release_path}"
        code <<-EOH
          export "GEM_HOME=/srv/localgems"
          export "GEM_PATH=/srv/localgems"
          export "PATH=/srv/localgems/bin:$PATH"
          rake repackage || rake build
          gem install pkg/*.gem 
        EOH
      end
    end
  end
end



