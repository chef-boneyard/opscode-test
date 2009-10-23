#
# Chef Client Config File
#
# Will be overwritten
#

log_level        :info
log_location     STDOUT
file_store_path  "/var/chef/file_store"
file_cache_path  "/var/chef/cache"
ssl_verify_mode  :verify_none
chef_server_url  "https://api.opscode.com/organizations/skeptomai" 
registration_url "https://api.opscode.com/organizations/skeptomai" 
openid_url       "https://api.opscode.com/organizations/skeptomai" 
template_url     "https://api.opscode.com/organizations/skeptomai" 
remotefile_url   "https://api.opscode.com/organizations/skeptomai" 
search_url       "https://api.opscode.com/organizations/skeptomai" 
role_url         "https://api.opscode.com/organizations/skeptomai" 
client_url       "https://api.opscode.com/organizations/skeptomai" 
validation_client_name "skeptomai-validator"
validation_key     "/Users/cb/cb-in-prod/skeptomai-opscode-platform-org.pem"



