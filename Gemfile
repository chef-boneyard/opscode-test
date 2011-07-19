# A sample Gemfile
source "http://rubygems.org"

#gem "mixlib-log", :git => "git://github.com/opscode/mixlib-log.git", :branch => "master"
gem "chef", :git => "git://github.com/opscode/chef.git", :branch => "master"
#gem "chef-solr", :git => "git://github.com/opscode/chef.git", :branch => "pl-master", :require => "chef/solr" 

gem "rake"

gem "rest-client", "~> 1.6.0"
gem "json", '1.4.6'
gem "coderay"
gem "rb-appscript"

gem "mixlib-cli"

# OPSCODE PROJECTS IN GIT
gem "mixlib-authentication", :git => "git@github.com:opscode/mixlib-authentication.git", :branch => 'master', :require => 'mixlib/authentication'
# no gemspec yet :(
#gem 'mixlib-config', :git => "git@github.com:opscode/mixlib-config.git", :branch => 'master', :require => 'mixlib/config'
#gem "mixlib-authorization", :git => 'git@github.com:opscode/mixlib-authorization.git', :branch => 'master', :require => 'mixlib/authorization'
gem "mixlib-authorization", :path => "/Users/ddeleo/opscode/mixlib-authorization"
gem "mixlib-localization", :git => 'git@github.com:opscode/mixlib-localization.git', :require => ['mixlib/localization', 'mixlib/localization/messages']
gem "opscode-billing", :git => 'git@github.com:opscode/opscode-billing', :require => 'opscode/billing'

# OPSCODE PATCHED GEMS
gem "couchrest", :git => "git://github.com/opscode/couchrest.git"
gem "aws-s3", :git => 'git@github.com:opscode/aws-s3.git', :require => 'aws/s3'

# Work around bug in libxml-ruby causing invalid ELF header
gem "libxml-ruby", "1.1.3"

gem "rspec", "1.3.0", :require => "spec"
