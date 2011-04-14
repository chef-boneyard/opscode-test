A set of scripts for Hudson builder slave (where Hudson does tests):

start-hudson-slave.sh
	Run by Hudson (start-euca-vm.rb) via SSH to run chef-client,
	setup the database, then run the slave jar. The hudson slave
	jar is run with GEM_HOME/GEM_PATH set.

run-cucumber.sh
	Run on the slave as a convenience for running cucumber with JUnit 
	output turned on, etc.

run-rake.sh
	Run on the slave as a convenience for running rake with JUnit output
	turned on, etc.

run-with-project-branches.rb
	Runs run-cucumber.sh/run-rake.sh after changing project
	branches. Unused for the platform as of 2011/3/30 as platform
	projects are bundler-ized.

shutdown-idle-slave.sh
	Run by cron on the slave node to shut it down after a period of
	inactivity from Hudson.

touch-files.rb
	Used by run-rake.sh and run-cucumber.sh to touch JUnit XML
	output files after a rake/cucumber run. This is to deal with
	timing differences between the slave node (the node this
	script is run on) and the NFS server holding /srv. If this
	script isn't run, Hudson may ignore the JUnit XML output files
	as being too old or too new, based on when the Hudson master
	node ran the script.


