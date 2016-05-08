#Setting up the Development Environment#

## Introduction ##

The steps described in the document automates the setup of the development enviroment for working with the Community Code itself.

##Requirements##

- [VirtualBox][1]
- [Vagrant][2]

##How to build the VM##

It should be easy:

	host $ git clone https://github.com/recursecenter/community.git
	host $ cd community
	host $ vagrant up
	host $ vagrant ssh
	vm $ cd /vagrant
	vm $ bin/rake db:setup

You are done now!

[1]: https://www.virtualbox.org/
[2]: https://www.vagrantup.com/