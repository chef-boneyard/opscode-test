#!/usr/bin/env ruby

#timmbp-oc:~/devel/opscode tim$ ps uxaw|grep /couchdb/|grep -v grep|grep beam
#root     43591  25.3  0.6  2491568  23308 s002  R+    9:09PM   7:52.69 /usr/local/lib/erlang/erts-5.7.4/bin/beam.smp -Bd -K true -- -root /usr/local/lib/erlang -progname erl -- -home /Users/tim -- -noshell -noinput -smp auto -sasl errlog_type error -pa /usr/local/apache-couchdb-0.10.0/lib/couchdb/erlang/lib/couch-0.10.0/ebin /usr/local/apache-couchdb-0.10.0/lib/couchdb/erlang/lib/mochiweb-r97/ebin /usr/local/apache-couchdb-0.10.0/lib/couchdb/erlang/lib/ibrowse-1.5.2/ebin /usr/local/apache-couchdb-0.10.0/lib/couchdb/erlang/lib/erlang-oauth/ebin -eval application:load(ibrowse) -eval application:load(oauth) -eval application:load(crypto) -eval application:load(couch) -eval crypto:start() -eval ssl:start() -eval ibrowse:start() -eval couch_server:start([ "/usr/local/apache-couchdb-0.10.0/etc/couchdb/default.ini", "/usr/local/apache-couchdb-0.10.0/etc/couchdb/local.ini"]), receive done -> done end.

pid = nil
File.popen("ps uxaw|grep /couchdb/|grep -v grep|grep beam", "r") do |ps|
  line = ps.readline
  fields = line.split(/\s+/)
  pid_str = fields[1]
  if pid_str =~ /\d+/
    pid = pid_str.to_i
    puts line
  end
end

if pid
  cmd = "sudo kill -TERM #{pid}"
  puts "Killing couchdb process at #{pid} with SIGTERM"
  puts "CMD: #{cmd}"
  res = system cmd
  puts ".. kill returned #{res}"
else
  puts "No couchdb process found, skipping.."
end

Dir.chdir("/mnt/bamboo-ebs") do |dir|
  cmd = "couchdb >> logs/couchdb.log 2>&1 &"
  puts "CMD: #{cmd}"
  system cmd
end


