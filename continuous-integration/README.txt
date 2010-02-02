Herein lie scripts and other supporting files for Opscode's continuous
integration with Bamboo.

Continuous integration is broken into two parts, both in terms of the tests
run and the system environments the tests are run within.

Unit (a.k.a. "spec") testing happens directly on the Bamboo builder box. For
a given Ruby project, it uses a "GEM sandbox" to install all dependencies of
that project. Then it runs 'rake spec' once the sandbox has been created.

Functional (a.k.a. "features") testing happens on an EC2 instance. This
instance is started by Bamboo. As Bamboo does not support starting EC2
instances on demand (when a build needs it), we have it configured to start
EC2 instances on a schedule. Then, the functional builds are scheduled to run
at times shortly thereafter. Bamboo projects are configured to require a
'capability' that only the EC2 elastic instance builders can provide,
"opscode-aws-ci=true". The EC2 instances start with a snapshot mounted. This
snapshot contains the code repositories for which tests are being run, as
well as snapshots for this project, 'opscode-test'.

unit
    contains files related to unit testing, which runs on the Bamboo builder
    machine itself. This directory contains the GEM sandboxing module which
    is invoked by Bamboo's 'ruby' builder.

functional
    contains files related to functional tests, which run on an EC2 Elastic
    Instance.
    