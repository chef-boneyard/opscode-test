def set_rails_env_for_type(type)
  rails_env = (type == 'features' ? 'cucumber' : (ENV['RAILS_ENV'] || 'development'))
  ENV['RAILS_ENV'] = rails_env
end

def start_mysqld_safe
  @mysqld_pid = fork do
    exec "mysqld_safe"
  end
end

def start_community_solr
  @community_solr_pid = fork do
    Dir.chdir(OPSCODE_COMMUNITY_PATH) do
      exec "rake solr:start:foreground"
    end
  end
end

def start_community_webui(type="normal")
  set_rails_env_for_type(type)
  @community_webui_pid = fork do
    Dir.chdir(OPSCODE_COMMUNITY_PATH) do
      exec "script/server thin"
    end
  end
end

def start_couchdb(type="normal")
  @couchdb_server_pid  = nil
  cid = fork
  if cid
    @couchdb_server_pid = cid
  else
    exec("couchdb")
  end
end

def start_rabbitmq(type="normal")
  @rabbitmq_server_pid = nil
  cid = fork
  if cid
    @rabbitmq_server_pid = cid
  else
    exec("rabbitmq-server")
  end
end

def start_parkplace(type="normal")
  path = File.join(OPSCODE_PROJECT_DIR, "parkplace")
  @parkplace_pid = nil
  cid = fork
  if cid
    @parkplace_pid = cid
  else
    Dir.chdir(path) do
      exec("./bin/parkplace")
    end
  end
end

def start_chef_solr(type="normal")
  path = File.join(OPSCODE_PROJECT_DIR, "opscode-chef")
  @chef_solr_pid = nil
  cid = fork
  if cid
    @chef_solr_pid = cid
  else
    Dir.chdir(path) do
      case type
      when "normal"
        exec("bin/chef-solr -l debug")
      when "features"
        p = fork { exec("bin/chef-solr-installer -p /tmp/opscode-platform-test --force") }
        Process.wait(p)
        exec("bin/chef-solr -c #{File.expand_path(File.join(File.dirname(__FILE__), "..", "features", "data", "config", "server.rb"))} -l debug")
      end
    end
  end
end

def start_opscode_expander(type="normal")
  path = File.join(OPSCODE_PROJECT_DIR, "opscode-expander")
  @opscode_expander = nil
  cid = fork
  if cid
    @opscode_expander = cid
  else
    Dir.chdir(path)
    exec("./bin/opscode-expander -n 1 -i 1")
  end
end

def start_chef_server(type="normal")
  path = File.join(OPSCODE_PROJECT_DIR, "opscode-chef", "chef-server-api")
  @chef_server_pid = nil
  mcid = fork
  if mcid # parent
    @chef_server_pid = mcid
  else # child
    Dir.chdir(path) do
      case type
      when "normal"
        exec("./bin/chef-server-api -l debug -N")
      when "features"
        exec("./bin/chef-server-api -C #{File.join(OPSCODE_PROJECT_DIR, 'opscode-chef', "features", "data", "config", "server.rb")} -l debug -N")
      end
    end
  end
end

def start_chef_server_webui(type="normal")
  path = File.join(OPSCODE_PROJECT_DIR, "opscode-chef", "chef-server-webui")
  @chef_server_webui_pid = nil
  mcid = fork
  if mcid # parent
    @chef_server_webui_pid = mcid
  else # child
    Dir.chdir(path) do
      case type
      when "normal"
        ENV["MERB_ENV"] = "development"
        exec "bin/chef-server-webui"
      when "features"
        ENV["MERB_ENV"] = "cucumber"
        exec "bin/chef-server-webui"
      end
    end
  end
end

def start_certificate(type="normal")
  path = File.join(OPSCODE_PROJECT_DIR, "opscode-certificate")
  @certificate_pid = nil
  cid = fork
  if cid # parent
    @certificate_pid = cid
  else # child
    Dir.chdir(path) do
      exec("slice -N -a thin -p 5140")
    end
  end
end

def start_cert_erlang(type="normal")
  path = File.join(OPSCODE_PROJECT_DIR, "opscode-cert-erlang")
  @cert_erlang_pid = nil
  cid = fork
  if cid # parent
    @cert_erlang_pid = cid
  else # child
    Dir.chdir(path) do
      exec("./start.sh")
    end
  end
end

def start_opscode_authz(type="normal")
  path = File.join(OPSCODE_PROJECT_DIR, "opscode-authz")
  @opscode_authz_pid = nil
  cid = fork
  if cid # parent
    @opscode_authz_pid = cid
  else # child
    Dir.chdir(path) do
      exec("./start.sh")
    end
  end
end

def start_opscode_account(type="normal")
  path = File.join(OPSCODE_PROJECT_DIR, "opscode-account")
  @opscode_account_pid = nil
  cid = fork
  if cid # parent
    @opscode_account_pid = cid
  else # child
    Dir.chdir(path) do
      exec("bin/opscode-account -l debug")
    end
  end
end

def start_opscode_org_creator(type="normal")
  path = File.join(OPSCODE_PROJECT_DIR, "opscode-org-creator/rel/org_app")
  @opscode_org_creator_pid = nil
  cid = fork
  if cid # parent
    @opscode_org_creator_pid = cid
  else # child
    Dir.chdir(path) do
      case type
      when "normal"
        exec("bin/org_app console dev")
      when "features"
        exec("bin/org_app console test")
      end
    end
  end  
end

def start_nginx(type="normal")
  path = File.join(OPSCODE_PROJECT_DIR, "nginx-sysoev")
  nginx_pid_file = "/var/run/nginx.pid"
  @nginx_pid = nil
  cid = fork
  if cid # parent
    catch(:done) do
      5.times do
        throw :done if File.exists?(nginx_pid_file) and (@nginx_pid = File.read(nginx_pid_file).to_i)
        sleep 1
      end
    end
    exit(-1) unless @nginx_pid
  else # child
    Dir.chdir(path) do
      exec("sudo", "./objs/nginx", "-c", "#{path}/conf/platform.conf")
    end
  end
end

def configure_rabbitmq(type="normal")
  # hack. wait for rabbit to come up.
  sleep 5

  puts `rabbitmqctl add_vhost /chef`

  # create 'chef' user, give it the password 'testing'
  puts `rabbitmqctl add_user chef testing`

  # the three regexes map to config, write, read permissions respectively
  puts `rabbitmqctl set_permissions -p /chef chef ".*" ".*" ".*"`

  puts `rabbitmqctl list_users`
  puts `rabbitmqctl list_vhosts`
  puts `rabbitmqctl list_permissions -p /chef`
end

def start_dev_environment(type="normal")
  start_couchdb(type)
  start_rabbitmq(type)
  configure_rabbitmq(type)
  start_parkplace(type)
  start_chef_solr(type)
  start_chef_solr_indexer(type)
  #start_certificate(type)
  start_cert_erlang(type)
  start_opscode_authz(type)
  start_opscode_account(type)
  start_chef_server(type)
  start_chef_server_webui(type)
  start_nginx(type)
  puts "Running CouchDB at #{@couchdb_server_pid}"
  puts "Running RabbitMQ at #{@rabbitmq_server_pid}"
  puts "Running ParkPlace at #{@parkplace_pid}"
  puts "Running Chef Solr at #{@chef_solr_pid}"
  puts "Running Chef Solr Indexer at #{@chef_solr_indexer_pid}"
  #puts "Running Certificate at #{@certificate_pid}"
  puts "Running Cert(Erlang) at #{@cert_erlang_pid}"
  puts "Running Opscode Authz at #{@opscode_authz_pid}"
  puts "Running Opscode Account at #{@opscode_account_pid}"
  puts "Running Chef at #{@chef_server_pid}"
  puts "Running nginx at #{@nginx_pid}"
end

def stop_dev_environment
  if @chef_server_pid
    puts "Stopping Chef"
    Process.kill("KILL", @chef_server_pid)
  end
  if @certificate_pid
    puts "Stopping Certificate"
    Process.kill("KILL", @certificate_pid)
  end
  if @cert_erlang_pid
    puts "Stopping Certgen(Erlang)"
    Process.kill("KILL", @cert_erlang_pid)
  end
  if @opscode_authz_pid
    puts "Stopping Opscode Authz"
    Process.kill("KILL", @opscode_authz_pid)
  end
  if @opscode_account_pid
    puts "Stopping Opscode Account"
    Process.kill("KILL", @opscode_account_pid)
  end
  if @couchdb_server_pid
    puts "Stopping CouchDB"
    Process.kill("KILL", @couchdb_server_pid)
  end
  if @rabbitmq_server_pid
    puts "Stopping RabbitMQ"
    Process.kill("KILL", @rabbitmq_server_pid)
  end
  if @chef_solr_pid
    puts "Stopping Chef Solr"
    Process.kill("INT", @chef_solr_pid)
  end
  if @chef_solr_indexer_pid
    puts "Stopping Chef Solr Indexer"
    Process.kill("INT", @chef_solr_indexer_pid)
  end
  if @nginx_pid
    puts "Stopping nginx"
    Process.kill("INT", @nginx_pid)
  end
  puts "Have a nice day!"
end

def wait_for_ctrlc
  puts "Hit CTRL-C to destroy development environment"
  trap("CHLD", "IGNORE")
  trap("INT") do
    stop_dev_environment
    exit 1
  end
  while true
    sleep 10
  end
end

desc "Run a Devel instance of Chef"
task :dev do
  start_dev_environment
  wait_for_ctrlc
end

namespace :dev do
  desc "Install a test instance of Chef for doing features against"
  task :features do
    start_dev_environment("features")
    wait_for_ctrlc
  end

  namespace :features do

    namespace :start do
      namespace :community do
        task :mysql do
          ## :TODO: BUGBUG ##
          # does not reliably kill mysqld when ctrl-C is received
          start_mysqld_safe
          wait_for_ctrlc
        end

        task :solr do
          start_community_solr
          wait_for_ctrlc
        end
        
        task :webui do
          start_community_webui("features")
          wait_for_ctrlc
        end
      end

      desc "Start CouchDB for testing"
      task :couchdb do
        start_couchdb("features")
        wait_for_ctrlc
      end

      desc "Start RabbitMQ for testing"
      task :rabbitmq do
        start_rabbitmq("features")
        configure_rabbitmq("features")
        wait_for_ctrlc
      end

      desc "Start ParkPlace for testing"
      task :parkplace do
        start_parkplace("features")
        wait_for_ctrlc
      end

      desc "Start Chef Solr for testing"
      task :chef_solr do
        start_chef_solr("features")
        wait_for_ctrlc
      end

      desc "Start Chef Solr Indexer for testing"
      task :chef_solr_indexer do
        start_chef_solr_indexer("features")
        wait_for_ctrlc
      end

      desc "Start Opscode Expander for testing"
      task :opscode_expander do
        start_opscode_expander("features")
        wait_for_ctrlc
      end

      desc "Start Chef Server for testing"
      task :chef_server do
        start_chef_server("features")
        wait_for_ctrlc
      end

      desc "Start Chef Server Webui for testing"
      task :chef_server_webui do
        start_chef_server_webui("features")
        wait_for_ctrlc
      end

      desc "Start Certificate for testing"
      task :certificate do
        start_certificate("features")
        wait_for_ctrlc
      end

      desc "Start Certgen(Erlang) for testing"
      task :cert_erlang do
        start_cert_erlang("features")
        wait_for_ctrlc
      end

      desc "Start Opscode Authz for testing"
      task :opscode_authz do
        start_opscode_authz("features")
        wait_for_ctrlc
      end

      desc "Start Opscode Account for testing"
      task :opscode_account do
        start_opscode_account("features")
        wait_for_ctrlc
      end

      desc "Start Opscode org creator for testing"
      task :opscode_org_creator do
        start_opscode_org_creator("features")
        wait_for_ctrlc
      end

      desc "Start Nginx for testing"
      task :nginx do
        start_nginx("features")
        wait_for_ctrlc
      end

    end
  end

  namespace :start do
    namespace :community do
      task :mysql do
        ## :TODO: BUGBUG ##
        # does not reliably kill mysqld when ctrl-C is received
        start_mysqld_safe
        wait_for_ctrlc
      end

      task :solr do
        start_community_solr
        wait_for_ctrlc
      end
      
      task :webui do
        start_community_webui
        wait_for_ctrlc
      end
    end
    
    desc "Start CouchDB"
    task :couchdb do
      start_couchdb
      wait_for_ctrlc
    end

    desc "Start RabbitMQ"
    task :rabbitmq do
      start_rabbitmq
      configure_rabbitmq
      wait_for_ctrlc
    end

    desc "Start ParkPlace"
    task :parkplace do
      start_parkplace
      wait_for_ctrlc
    end

    desc "Start Chef Solr"
    task :chef_solr do
      start_chef_solr
      wait_for_ctrlc
    end

    desc "Start Chef Solr Indexer"
    task :chef_solr_indexer do
      start_chef_solr_indexer
      wait_for_ctrlc
    end

    desc "Start Opscode Expander"
    task :opscode_expander do
      start_opscode_expander
      wait_for_ctrlc
    end

    desc "Start Chef Server"
    task :chef_server do
      start_chef_server
      wait_for_ctrlc
    end

    desc "Start Chef Server Webui"
    task :chef_server_webui do
      start_chef_server_webui
      wait_for_ctrlc
    end

    desc "Start Certificate"
    task :certificate do
      start_certificate
      wait_for_ctrlc
    end

    desc "Start Certgen(Erlang)"
    task :cert_erlang do
      start_cert_erlang
      wait_for_ctrlc
    end

    desc "Start Opscode Authz"
    task :opscode_authz do
      start_opscode_authz
      wait_for_ctrlc
    end

    desc "Start Opscode Account"
    task :opscode_account do
      start_opscode_account
      wait_for_ctrlc
    end

    desc "Start Opscode org creator"
    task :opscode_org_creator do
      start_opscode_org_creator
      wait_for_ctrlc
    end

    desc "Start Nginx for testing"
    task :nginx do
      start_nginx
      wait_for_ctrlc
    end

  end
end
