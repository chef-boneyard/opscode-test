#!/usr/bin/env ruby

VBOXMANAGE = "VBoxManage"

def usage
  puts <<EOM
  #{$0} <vm_name> <ip_address> [snapshot_name]
  
  Will kill any existing VirtualBox instances with the given name, then start up the given
  VM at the (if specified) given snapshot. Copies 
  
EOM
end

def do_vbox(args)
  cmd = "#{VBOXMANAGE} #{args}"
  puts "CMD: #{cmd}"
  system cmd
end

def is_vbox_running?(name)
  running = false
  IO.popen("#{VBOXMANAGE} list vms", "r") do |vbox|
    vbox.each_line do |line|
      if line =~ /\"#{name}\" \{.+\}$/
        running = true
      end
    end
  end
  puts "is_vbox_running?: running = #{running}"
  running
end

def do_on_remote(ip_address, cmd)
  cmd = "ssh #{ip_address} #{cmd}"
  puts "CMD: #{cmd}"
  system cmd
end


# vm name
# snapshot name
if ARGV.length < 2
  usage
  exit
end

vm_name = ARGV[0]
ip_address = ARGV[1]
snapshot_name = ARGV[2]

if is_vbox_running?(vm_name)
  if false
    puts "shutdown via ACPI:"
    do_vbox "controlvm '#{vm_name}' acpipowerbutton"
  
    num_tries = 0
    begin
      sleep 2
      num_tries += 1
      puts "num_tries = #{num_tries}"
    end while (is_vbox_running?(vm_name) && num_tries < 5)
  end
  
  if is_vbox_running?(vm_name)
    puts "shutdown via Power Off:"
    do_vbox "controlvm '#{vm_name}' poweroff"
  end
end

if snapshot_name
  do_vbox "snapshot '#{vm_name}' restore '#{snapshot_name}'"
end

do_vbox "startvm '#{vm_name}'"

sleep 10

#do_on_remote(ip_address, "sudo ntpdate tick.pnap.net")
#do_on_remote(ip_address, "sudo chef-client -l debug")
#do_on_remote(ip_address, "sudo ntpdate tick.pnap.net && sudo env GEM_HOME=/srv/localgems GEM_PATH=/srv/localgems PATH=/srv/localgems:\\$PATH chef-client -l debug && java -jar slave.jar")
do_on_remote(ip_address, "./start-hudson-slave.sh")
