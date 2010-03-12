Before do
  c = Chef::REST.new(Chef::Config[:couchdb_url], nil, nil)

  replication_specs = get_db_list.map{|db| {:source_db=>"#{db}_integration",:target_db=>db}}
  replicate_dbs(replication_specs)
end

After do
  save_test_databases
end

def get_db_list
  db = Chef::REST.new(Chef::Config[:couchdb_url], nil, nil)
  begin
    doc = db.get_rest('test_harness_setup/dbs_to_replicate')
  rescue
    raise "Encountered exception. #{$!} \n\nAre you sure you ran 'rake setup:test' in opscode-test?"
  end 
  dbs_to_replicate = doc['source_dbs']
end 


def replicate_dbs(replication_specs, delete_source_dbs = false)
  replication_specs = [replication_specs].flatten
  Chef::Log.debug "replication_specs = #{replication_specs.inspect}, delete_source_dbs = #{delete_source_dbs}"
  c = Chef::REST.new(Chef::Config[:couchdb_url], nil, nil)
  replication_specs.each do |spec|
    source_db = spec[:source_db]
    target_db = spec[:target_db]
    
    Chef::Log.debug("Deleting #{target_db}, if exists")
    begin
      c.delete_rest("#{target_db}/")
    rescue Net::HTTPServerException => e
      raise unless e.message =~ /Not Found/
    end
    
    Chef::Log.debug("Creating #{target_db}")
    c.put_rest(target_db, nil)
    
    Chef::Log.debug("Replicating #{source_db} to #{target_db}")
    c.post_rest("_replicate", { "source" => "#{Chef::Config[:couchdb_url]}/#{source_db}", "target" => "#{Chef::Config[:couchdb_url]}/#{target_db}" })
    
    if delete_source_dbs
      Chef::Log.debug("Deleting #{source_db}")
      c.delete_rest(source_db)
    end
  end
end

# TODO: Make replication of test dbs to replica dbs configurable by ENV var or CLI flag
def save_test_databases
  #  run_id = UUIDTools::UUID.random_create.to_s.gsub(/\-/,'').downcase
  #  replication_specs = get_db_list.map{|db| {:source_db=>db,:target_db=>"replica_#{run_id}-#{db}"}}
  #  replicate_dbs(replication_specs, true)
end