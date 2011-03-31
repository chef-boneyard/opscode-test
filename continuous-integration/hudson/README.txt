A set of scripts for Hudson master node (where Hudson runs):

start-euca-vm.rb
	This is the startup script used by Hudson to boot a new
	Eucalyptus VM. Takes EMI to boot and if Hudson itself is
	running within Eucalyptus, should be run with '-private',
	which causes the SSH connections between Hudson master and VM
	to use the VM's private address instead of public.

	After booting up the slave VM, it runs
	slave/start-hudson-slave.sh on the slave.

