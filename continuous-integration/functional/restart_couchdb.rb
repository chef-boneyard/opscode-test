#!/usr/bin/env ruby

class << @self
  require "#{File.dirname(__FILE__)}/cmdutil"
end

#timmbp-oc:~/devel/opscode tim$ ps uxaw|grep /couchdb/|grep -v grep|grep beam
#root     43591  25.3  0.6  2491568  23308 s002  R+    9:09PM   7:52.69 /usr/local/lib/erlang/erts-5.7.4/bin/beam.smp -Bd -K true -- -root /usr/local/lib/erlang -progname erl -- -home /Users/tim -- -noshell -noinput -smp auto -sasl errlog_type error -pa /usr/local/apache-couchdb-0.10.0/lib/couchdb/erlang/lib/couch-0.10.0/ebin /usr/local/apache-couchdb-0.10.0/lib/couchdb/erlang/lib/mochiweb-r97/ebin /usr/local/apache-couchdb-0.10.0/lib/couchdb/erlang/lib/ibrowse-1.5.2/ebin /usr/local/apache-couchdb-0.10.0/lib/couchdb/erlang/lib/erlang-oauth/ebin -eval application:load(ibrowse) -eval application:load(oauth) -eval application:load(crypto) -eval application:load(couch) -eval crypto:start() -eval ssl:start() -eval ibrowse:start() -eval couch_server:start([ "/usr/local/apache-couchdb-0.10.0/etc/couchdb/default.ini", "/usr/local/apache-couchdb-0.10.0/etc/couchdb/local.ini"]), receive done -> done end.

pid = nil
File.popen("ps uxaw|grep /couchdb/|grep -v grep|grep beam", "r") do |ps|
  ps.each_line do |line|
    fields = line.split(/\s+/)
    pid_str = fields[1]
    if pid_str =~ /\d+/
      pid = pid_str.to_i
      puts line
    end
  end
end

if pid
  cmd = "sudo kill -TERM #{pid}"
  puts "Killing couchdb process at #{pid} with SIGTERM"
  run cmd
else
  puts "No couchdb process found, skipping.."
end

Dir.chdir("/mnt/bamboo-ebs") do |dir|
  # third argument is true so that we append to the couchdb log instead
  # of overwriting it.
  run_server "couchdb", nil, true
end


