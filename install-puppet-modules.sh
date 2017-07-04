#!/bin/bash

mkdir -p /etc/puppet/modules;
puppet module install puppetlabs-mysql --version 3.11.0
puppet module install stankevich-python --version 1.18.2
puppet module install puppet-nginx --version 0.6.0
puppet module install puppetlabs-git --version 0.5.0
