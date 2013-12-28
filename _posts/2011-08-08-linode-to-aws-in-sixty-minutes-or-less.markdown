---
layout: post
title: "Linode to AWS in Sixty Minutes or Less"
date: 2011-08-08 23:14
comments: true
categories: devops
---

So, [linode bailed](http://yfrog.com/kkrk4p) while I was in the middle of
working on the [band website](http://www.thebonscotts.com).

That annoyed me somewhat.

Here's what I did to move it off linode in under one hour:

 1. Logged in to my (already extant) AWS account
 1. Created an elastic IP
 1. Put in a request for a `t1.micro` spot instance in `ap-southeast-1` (have found it to have the least latency for .au clients)
 1. Logged in to linode
 1. Pointed the thebonscotts.com / www.thebonscotts.com A records to the new elastic IP
 1. Waited ~5min for the spot instance to come up
 1. Associated the elastic IP with the spot instance

I then logged in to the instance, ran `ssh-keygen` to create a ssh
key, and added that key to my github project's deploy keyset.

I then ran these commands:

``` bash
sudo apt-get update
sudo apt-get install git-core
wget http://rubyenterpriseedition.googlecode.com/files/ruby-enterprise_1.8.7-2011.03_amd64_ubuntu10.04.deb
sudo dpkg --install ruby-enterprise_1.8.7-2011.03_amd64_ubuntu10.04.deb
sudo gem update --system
sudo gem install bundler --no-rdoc --no-ri
sudo gem install passenger --no-rdoc --no-ri
sudo apt-get install apache2-prefork-dev
sudo apt-get install build-essential libcurl4-openssl-dev zlib1g-dev apache2-mpm-prefork
sudo /usr/local/bin/passenger-install-apache2-module
sudo vim /etc/apache2/sites-available/default

# above I copied in the sections from the passenger install
git clone git@github.com:<REDACTED>
sudo apt-get install memcached
sudo update-rc.d memcached defaults
sudo update-rc.d apache2 defaults
cd bonscotts/
bundle install
sudo /etc/init.d/apache2 restart
```

Easy!

Probably would have been easier if I'd had a puppet or chef recipe.

--

### Postscript

I didn't create a snapshot of the instance. A month later, when the AWS spot instance price exceeded my maximum bid, the instance was terminated and I had to repeat the above process.

Fortunately I had the above instructions archived on [github](http://gist.github.com).
