#!/usr/bin/env ruby

# Script called by Hudson to start a new slave builder node, using Eucalyptus.
# Note that this script requires Eucalyptus environment variables to be set, so
# you should probably "source ~/eucarc" before running it.
# It depends on:
#  EC2_URL, EC2_ACCESS_KEY, EC2_SECRET_KEY
MAXTRIES_FOR_RUNNING_STATE = 600 # how many tries (seconds) to wait for the instance to be 'running'
MAXTRIES_FOR_SSH = 60            # how many tries (seconds) to wait for ssh to work
#INSTANCE_TYPE = 'c1.xlarge'     # instance_type (size)
INSTANCE_TYPE = 'm1.large'       # instance_type (size)
SSH_USER = "ubuntu"
KEYPAIR = 'timkey'                # keypair to use to start instances
KEYPAIR_FILENAME = [ "#{ENV['HOME']}/.euca/#{KEYPAIR}.pem", "#{ENV['HOME']}/#{KEYPAIR}.pem" ].select {|fn| File.exist?(fn) }
if !KEYPAIR_FILENAME
  raise "could not determine keypair filename for ssh! where is #{KEYPAIR}.pem?"
end

def usage
  puts <<EOM
  #{$0} <emi-id>
  
  Will shut down any existing Eucalyptus instances with the given EMI, and start a
  new one up.
EOM
end

def debug(str)
  puts "DEBUG: #{str}"
end

def do_cmd(cmd)
  puts "CMD: #{cmd}"
  system cmd
end

# INSTANCE	i-37AB06AF	emi-947C0F6E	192.168.0.21	172.19.1.3	running 	timkey 	0 	c1.xlarge 	2010-09-10T00:58:06.461Z 	cluster1 	eki-F7E31108 	eri-0C671171
# INSTANCE	i-466B0810	emi-F2ED1165	0.0.0.0	0.0.0.0	pending	timkey	2010-09-14T01:35:31.795Z	eki-F7E31108	eri-0C671171
def parse_instance_line(line)
  if line =~ /INSTANCE\s+(i-[0-9A-F]+)\s+(emi-[0-9A-F]+)\s+([\d\.]+)\s+([\d\.]+)\s+(\w+)\s+(\w+)\s+(\d+\s+)?([\w\.]+\s+)?([0-9\-\.:T]+Z)\s+(\w+\s+)?(eki-[0-9A-F]+)\s+(eri-[0-9A-F]+)$/
    instance_id = $1
    emi_id = $2
    public_ip = $3
    private_ip = $4
    state = $5
    _keyname = $6
    _unknown = $7
    _instance_type = $8
    _timestamp = $9
    _region = $10
    _eki_id = $11
    _eri_id = $12
    
    { :instance_id => instance_id, :emi_id => emi_id, :public_ip => public_ip, :state => state }
  else
    nil
  end
end

# RESERVATION	r-50CE09A5	admin	default
def enumerate_instances
  result = []
  IO.popen("euca-describe-instances", "r") do |euca_proc|
    euca_proc.each_line do |line|
      if (new_result = parse_instance_line(line))
        result << new_result
      elsif line =~ /RESERVATION/
        # ignore this line.
      else
        #puts "WARN: didn't expect output from euca-describe-instances: #{line}"
      end
    end
  end
  
  debug "enumerate_instances: result = #{result.inspect}"
  result
end

def shutdown_instances_if_running(emi_id)
  # get the running instances by enumerating all instances and only including
  # those instances which have the same emi_id and are in the running state.
  debug "shutdown_instances_if_running(emi_id = #{emi_id})"
  running_instances = enumerate_instances.select do |instance| 
    puts "select, wanted #{emi_id}/running, got #{instance[:emi_id]}/#{instance[:state]}"
    instance[:emi_id] == emi_id && instance[:state] == 'running'
  end
  
  debug "shutdown_instances_if_running: running_instances = #{running_instances.inspect}"

  # terminate each of the running instances.
  running_instances.each do |running_instance|
    debug "shutdown_instances_if_running: SHUTTING DOWN instance #{running_instance[:instance_id]}"

    do_cmd "euca-terminate-instances #{running_instance[:instance_id]}"
    wait_until_instance_in_state(running_instance[:instance_id], 'terminated')
  end
end

def is_instance_in_state?(instance_id, state)
  result = nil
  
  debug "is_instance_in_state?(instance_id = #{instance_id}, state = #{state})"
  
  enumerate_instances.each do |instance|
    debug "is_instance_in_state(instance_id = #{instance_id}, state = #{state}): current enumerated is #{instance[:instance_id]}/#{instance[:state]}"
    if instance_id == instance[:instance_id] && instance[:state] == state
      result = instance
    end
  end
  
  puts "is_instance_in_state?: result = #{result.inspect}"
  
  result
end

def wait_until_instance_in_state(instance_id, state)
  num_tries = 1

  debug "wait_until_instance_in_state(instance_id = #{instance_id}, state = #{state})"
  result_instance = nil
  while !(result_instance = is_instance_in_state?(instance_id, state)) && num_tries < MAXTRIES_FOR_RUNNING_STATE
    debug "instance wasn't #{state} on try #{num_tries}/#{MAXTRIES_FOR_RUNNING_STATE}: trying again"
    sleep 1
    num_tries += 1
  end
  if result_instance
    debug "wait_until_instance_in_state: DONE: state is now #{result_instance[:state]}"
  else
    debug "wait_until_instance_in_state: DONE: instance never reached desired state #{state}!"
  end
  
  result_instance
end
  
def run_instance(emi_id)
  new_instance_id = nil

  run_cmd = "euca-run-instances #{emi_id} -k #{KEYPAIR} -t #{INSTANCE_TYPE}"
  debug "run_instance(emi_id = #{emi_id})"
  debug "run_instance: run_cmd = #{run_cmd}"
  IO.popen(run_cmd, "r") do |run_proc|
    run_proc.each_line do |line|
      new_instance = parse_instance_line(line)
      if new_instance
        new_instance_id = new_instance[:instance_id]
      elsif line =~ /RESERVATION/
        # ignore.
      else
        raise "couldn't start instance with emi_id #{emi_id}: got unexpected line #{line}"
      end
    end
  end
  
  if !new_instance_id
    raise "couldn't start instance with emi_id #{emi_id}: empty result from euca-run-instances"
  end
  
  running_instance = wait_until_instance_in_state(new_instance_id, 'running')
  if running_instance
    debug "run_instance: running_instance state NOW = #{running_instance[:state]}"
  else
    debug "run_instance: running_instance is nil!"
  end
  
  running_instance
end

def wait_for_ssh_running(instance)
  num_tries = 1
  ssh_running = nil
  
  while !ssh_running && num_tries < MAXTRIES_FOR_SSH
    # send a blank line to netcat (nc) and then tell it to exit 1 second after
    # EOF. The remote server should respond with the SSH banner in that amount
    # of time.
    IO.popen("echo | nc #{instance[:public_ip]} 22 -q 1", "r") do |netcat_proc|
      netcat_proc.each_line do |line|
        if line =~ /SSH/
          ssh_running = true
          break
        end
      end
      puts "SSH not running on #{instance[:public_ip]} on try #{num_tries}/#{MAXTRIES_FOR_SSH}: trying again..."
      sleep 1
      num_tries += 1
    end
  end
  
  if !ssh_running
    puts "SSH not running after max tries #{MAXTRIES_FOR_SSH}!"
  end
  
  ssh_running
end

def do_on_remote(instance, cmd)
  cmd = "ssh -i #{KEYPAIR_FILENAME} #{SSH_USER}@#{instance[:public_ip]} #{cmd}"
  puts "CMD: #{cmd}"
  system cmd
end

# EMI id
if ARGV.length < 1
  usage
  exit
end

wanted_emi_id = ARGV[0]

puts "SHUTDOWN IF RUNNING:"
shutdown_instances_if_running(wanted_emi_id)

puts "RUN:"
instance = run_instance(wanted_emi_id)

if wait_for_ssh_running(instance)
  do_on_remote(instance, "'sudo hostname ubuntu-ci-slave-euca && sudo chef-client -l debug && sudo env GEM_HOME=/srv/localgems GEM_PATH=/srv/localgems PATH=/srv/localgems:$PATH java -jar slave.jar'")
else
  puts "ERROR: Not running slave JAR as ssh never responded"
end

