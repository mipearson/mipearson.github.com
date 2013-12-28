---
layout: post
title: "Tracking Nginx Error Code Frequency with Munin"
date: 2011-08-16 23:04
comments: true
categories: gist devops
---

Place this in your `/etc/munin/plugins`.

You'll need to ensure that your `/var/nginx/access.log` is readable by your `munin-node` user.

``` ruby
#!/usr/bin/env ruby

CODES = {
  '400' => 'Bad Request',
  '401' => 'Unauthorized',
  '403' => 'Forbidden',
  '404' => 'Not Found',
  '405' => 'Method Not Allowed',
  '406' => 'Not Acceptable',
  '408' => 'Request Timeout',
  '499' => 'Client Connection Terminated',
  '500' => 'Internal Server Error',
  '502' => 'Bad Gateway',
  '503' => 'Service Unavailable',
  'Other' => 'Other responses'
}

if ARGV[0] == 'config'; then
  puts "graph_title nginx Error Codes"
  puts "graph_vlabel responses per minute"
  puts "graph_category nginx"
  puts "graph_period minute"
  puts "graph_info Non-200 response codes per minute"
  CODES.each do |code, desc|
    puts "#{code}.label #{code} #{desc}"
    puts "#{code}.type DERIVE"
    puts "#{code}.min 0"
  end
else
  results = Hash[*CODES.keys.map { |k| [k, 0]}.flatten]
  File.open("/var/log/nginx/access.log").readlines.each do |line|
    if line =~ /" (\d\d\d)/
      code = $1
      if CODES.keys.include?(code)
	results[code] += 1
      elsif code.to_i >= 400
        results['Other'] += 1
      end
    end
  end
 
  results.each do |k,v|
    puts "#{k}.value #{v}"
  end 
end
```