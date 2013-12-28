---
layout: post
title: "Reducing Asset Precompilation Time"
date: 2012-03-18 21:10
comments: true
categories: 
---

We deploy to our test environment generally between five and twenty times a day. As we like our test environment to provide a solid indicator of production-readiness, we try to match our test environment as close to production as we can.

This, of course, means using the same Rails asset precompilation on a test deploy as on a production deploy. Unfortunately, this can take a while:

    $ time rake assets:precompile
    ...
    real  4m14.866s
    user  5m52.794s
    sys   0m31.324s

Last week I found, fixed and resolved a bug in the time it took for a deployment to complete. This annoyed me, so I set out to see if I could reduce our asset precompilation time, and by extension our deployment time.

First I look in `rails/actionpack/lib/sprockets/assets.rake` and find one huge smell: the compilation is run twice! It's run once for assets, appending a digest path, and then again without a digest path.

Doing a bit of digging on this I find this isn't necessary for our case: everything in `public/assets` is called using one of the asset helpers, which will read `manifest.yml` and determine the correct (digested) path for the asset. Unless we start using assets from a 'static' source (eg, from an email) we're safe to turn off the 'nondigest' run. In fact, it looks like there's a [movement to make this the default](https://github.com/rails/rails/pull/5379).

Unfortunately, running `rake assets:precompile:primary` gives us an error about a missing `bootstrap-dropdown.js`. Investigating further I find that `rake assets:precompile` does some set up for us. It:

  * sets the Rails environment to `production`,
  * ensures that Bundler loads the `assets` group and
  * re-invokes rake to apply these changes.
  
Appending `RAILS_ENV=production RAILS_GROUPS=assets` to our `rake assets:precompile:primary` command fixes the missing file error.

This halves our precompilation time:

    real  2m0.908s
    user  2m51.986s
    sys   0m14.973s

Now, let's see where Sprockets is spending all of its time. I overrode the `Sprockets::StaticCompiler#compile` method to print out how long Sprockets spent with each file:

``` ruby
if ENV['TRACK_PRECOMPILE_ASSETS']
  module Sprockets
    class StaticCompiler
      def compile
        manifest = {}
        start_process = Time.now
        total_time_taken = 0
        env.each_logical_path do |logical_path|
          next unless compile_path?(logical_path)
          start_file = Time.now
          if asset = env.find_asset(logical_path)
            post_find = Time.now
            manifest[logical_path] = write_asset(asset)
            post_write = Time.now
            time_taken = post_write - start_file
            percent_in_write = (post_write - post_find) / time_taken
            total_time_taken += time_taken
            time_taken_s = sprintf "%0.2f", time_taken * 1000
            percent_in_write_s = sprintf "%0.2f", percent_in_write * 100
            $stderr.puts "#{logical_path}: #{time_taken_s} #{percent_in_write_s}%"
          end
        end
        write_manifest(manifest) if @manifest
        $stderr.puts "TOTAL: #{Time.now - start_process} #{total_time_taken} "
      end
    end
  end
end
```

Messy as hell, but it's done the job for me.

It showed me something interesting: each file that actually needs precompilation (rather than simply copying, as is the case for images) takes between 0.5 seconds and 3 seconds depending on how complex it is.

The gem `ckeditor_rails` has about 100 or so Javascript files that are being individually compiled. Removing this gem reduces our precompilation time significantly:

    real  0m35.728s
    user  0m45.032s
    sys   0m2.792s

So, I've taken the time from four minutes to thirty seconds. Let's see how that affects our deployment time.

Firstly, we'll set a baseline by running chef without a pending deploy:

    real  0m24.555s
    user  0m1.940s
    sys   0m0.560s

Next a deploy without the above optimisations:

    real  4m6.257s
    user  3m46.870s
    sys   0m24.190s

Finally, use `asset:precompile:primary` and remove `ckeditor_rails`:
    real  1m30.535s
    user  0m49.960s
    sys  0m5.690s
    
Four minutes down a much more reasonable one minute thirty! There's still work to be done, but this is much better than we started with.