

$: << File.join(File.dirname(__FILE__), '..', 'opscode-chef', 'chef', 'lib')

OPSCODE_COMMUNITY_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-community-site"))

if File.exists?(File.dirname(__FILE__) + "/../opscode-test")
  # local dev environment
  OPSCODE_PROJECT_DIR = File.expand_path(File.dirname(__FILE__) + '/../')
  OPSCODE_PROJECT_DIR_RELATIVE = '../'
  OPSCODE_PROJECT_SUFFIX = ""
elsif File.exists?(File.dirname(__FILE__) + "/../../../opscode-test/current")
  # chef-deployed
  OPSCODE_PROJECT_DIR = File.expand_path(File.dirname(__FILE__) + '/../../../')
  OPSCODE_PROJECT_DIR_RELATIVE = '../../../'
  OPSCODE_PROJECT_SUFFIX = "current"
else
  raise "could not determine OPSCODE_PROJECT_DIR: neither '..' (local dev) or '../../..' (PIAB)"
end

Dir["tasks/*.rake"].each { |t| load t }
