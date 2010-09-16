
A set of scripts for Hudson master and slave:

run-cucumber.sh
	Run on the slave as a convenience for running cucumber with JUnit output
	turned on, etc.
	
	TODO, tim 2010-9-15: remove GEM_PATH, GEM_HOME stuff as we're now assuming
	slave.jar is started with these environment variables set.

start-euca-vm.rb
	This is the startup script used by Hudson to boot a new Eucalyptus VM. Takes
	EMI to build and if Hudson itself is running within Eucalyptus, should be run
	with '-private', which causes the SSH connections between Hudson master and
	VM to use the VM's private address instead of public.
	
	This runs chef-client, then runs the Hudson slave jar with GEM_HOME/GEM_PATH
	set.

start-virtualbox-vm.rb
	An equivalent script for VirtualBox. Saved here for posterity, as we aren't
	using VirtualBox anymore.
	
Hudson should be set up with GEM_PATH, GEM_HOME, PATH already set to include
/srv/localgems.
