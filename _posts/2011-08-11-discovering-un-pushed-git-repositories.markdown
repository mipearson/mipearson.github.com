---
layout: post
title: "Discover Un-Pushed git Repositories"
date: 2011-08-18 23:04
comments: true
categories: gist 
---

A small script to discover any repositories in the current directory with an un-pushed current branch:

``` ruby
#!/usr/bin/env ruby

pwd = ARGV[0] || '.'
debug = ARGV[1] == '-d'

Dir[File.join(pwd, '**', '.git')].each do |repo|
  repo.gsub!(/\.git$/, '')
  $stderr.puts "in #{repo}" if debug
  if `cd #{repo}; git status`.include?("Your branch is ahead of") 
    puts repo
  end
end
```