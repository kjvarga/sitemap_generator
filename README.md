# SitemapGenerator

SitemapGenerator is the easiest way to generate Sitemaps in Ruby.  Rails integration provides access to the Rails route helpers within your sitemap config file and automatically makes the rake tasks available to you.  Or if you prefer to use another framework, you can!  You can use the rake tasks provided or run your sitemap configs as plain ruby scripts.

Sitemaps adhere to the [Sitemap 0.9 protocol][sitemap_protocol] specification.

## Features

* Framework agnostic
* Supports [News sitemaps][sitemap_news], [Video sitemaps][sitemap_video], [Image sitemaps][sitemap_images], [Geo sitemaps][sitemap_geo], [Mobile sitemaps][sitemap_mobile], [PageMap sitemaps][sitemap_pagemap] and [Alternate Links][alternate_links]
* Supports read-only filesystems like Heroku via uploading to a remote host like Amazon S3
* Compatible with Rails 2, 3 & 4 and tested with Ruby REE, 1.9.2 & 1.9.3
* Adheres to the [Sitemap 0.9 protocol][sitemap_protocol]
* Handles millions of links
* Customizable sitemap compression
* Notifies search engines (Google, Bing) of new sitemaps
* Ensures your old sitemaps stay in place if the new sitemap fails to generate
* Gives you complete control over your sitemap contents and naming scheme
* Intelligent sitemap indexing

### Show Me

This is a simple standalone example.  For Rails installation see the Install section.

Install:

```
gem install sitemap_generator
```

Create `sitemap.rb`:

```ruby
require 'rubygems'
require 'sitemap_generator'

SitemapGenerator::Sitemap.default_host = 'http://example.com'
SitemapGenerator::Sitemap.create do
  add '/home', :changefreq => 'daily', :priority => 0.9
  add '/contact_us', :changefreq => 'weekly'
end
SitemapGenerator::Sitemap.ping_search_engines # Not needed if you use the rake tasks
```

Run it:

```
ruby sitemap.rb
```

Output:

```
In /Users/karl/projects/sitemap_generator-test/public/
+ sitemap.xml.gz                                           3 links /  364 Bytes
Sitemap stats: 3 links / 1 sitemaps / 0m00s

Successful ping of Google
Successful ping of Bing
```


## Contribute

Does your website use SitemapGenerator to generate Sitemaps?  Where would you be without Sitemaps?  Probably still knocking rocks together.  Consider donating to the project to keep it up-to-date and open source.

<a href='http://www.pledgie.com/campaigns/15267'><img alt='Click here to lend your support to: SitemapGenerator and make a donation at www.pledgie.com !' src='http://pledgie.com/campaigns/15267.png?skin_name=chrome' border='0' /></a>

## Deprecation Notices and Non-Backwards Compatible Changes

### Version 5.0.0

In version 5.0.0 I've removed a few deprecated methods that have been deprecated for a long time.  The reason being that they would have made some new features more difficult and complex to implement.  I never actually ouput deprecation notices from these methods, so I understand it you're a little annoyed that your config has suddenly broken.  Apologies.

Here's a list of the methods that have been removed:
* Removed options to `LinkSet::add()`: `:sitemaps_namer` and `:sitemap_index_namer` (use `:namer` option)
* Removed `LinkSet::sitemaps_namer=`, `LinkSet::sitemaps_namer` (use `LinkSet::namer=` and `LinkSet::namer`)
* Removed `LinkSet::sitemaps_index_namer=`, `LinkSet::sitemaps_index_namer` (use `LinkSet::namer=` and `LinkSet::namer`)
* Removed the `SitemapGenerator::SitemapNamer` class (use `SitemapGenerator::SimpleNamer`)
* Removed `LinkSet::add_links()` (use `LinkSet::create()`)

### Version 4.0.0

Version 4.0 introduces a new **non-backwards compatible** naming scheme.  **If you are running version 3 or earlier and you upgrade to version 4, you need to make a couple small changes to ensure that search engines can still find your sitemaps!**  Your sitemaps will still work fine, but the name of the index file has changed.

#### So what has changed?

* **The index is generated intelligently**.  SitemapGenerator now detects whether you need an index or not, and only generates one if you need it or have requested it.  So small sites (less than 50,000 links) won't have one, large sites will.  You don't have to worry about anything.  And with the `create_index` option, it's easier than ever to control index creation to suit your needs.

* **The default index file name has changed** from `sitemap_index.xml.gz` to just `sitemap.xml.gz`.  So the `_index` part has been removed.  This is a more standard naming scheme for the sitemaps. Any further sitemaps are named `sitemap1.xml.gz`, `sitemap2.xml.gz`, `sitemap3.xml.gz` etc, just as before.

* **Everyone now points search engines to the `sitemap.xml.gz` file**.  It doesn't matter whether your site has 10 links or a million links, just point to `sitemap.xml.gz`.  If your site needs an index, that is the index.  If it doesn't, then that's your sitemap.  Simple.

* **It's easier to write custom namers** because the index and the sitemaps share the same namer instance (which is now a `SitemapGenerator::SimpleNamer` instance).

* **Groups share the new naming convention**.  So the files in your `geo` group will be named `geo.xml.gz`, `geo1.xml.gz`, `geo2.xml.gz` etc.  Pre-version 4 these files would have been named `geo1.xml.gz`, `geo2.xml.gz`, `geo3.xml.gz` etc.

#### I don't want it!  How can I keep everything as it was?

You don't care, you just want to get on with your day.  To resort to pre-version 4 behaviour add the following to your sitemap config:

```ruby
SitemapGenerator::Sitemap.create_index = true
SitemapGenerator::Sitemap.namer = SitemapGenerator::SimpleNamer.new(:sitemap, :zero => '_index')
```

This tells SitemapGenerator to always create an index file and to name it `sitemap_index.xml.gz`.  If you are already using custom namers, you don't need to set `namer`; your old namers should still work as before.  If you are using named groups, setting the sitemap namer in this way won't affect your groups, which will still be using the new naming scheme.  If this is an issue for you, you may have to create namers for your groups.

#### I want it!  What do I need to do?

1. Update your `robots.txt` file and make sure it points to `sitemap.xml.gz`.
2. Generate your sitemaps to create the new `sitemap.xml.gz` file.
3. Optionally remove the old `sitemap_index.xml.gz` file (or link it to the new file if you want to make sure that search engines can find it while you update them.)
4. Go to your Google Webmaster tools and other places where you've pointed search engines to your sitemaps and point them to your new `sitemap.xml.gz` file.

That's it!  Welcome to the future!

## Changelog

* v5.1.0: Require only `fog-aws` instead of `fog` for the `S3Adapter` and support using IAM profile instead of setting access key & secret directly.  Implement `respond_to?` on the `SitemapGenerator::Sitemap` pseudo class.  Make `:lang` optional on alternate links so they can be used for [AppIndexing](https://developers.google.com/app-indexing/reference/deeplinks).  Documented [Mobile Sitemaps](#internal_mobile) `:mobile` option.
* v5.0.5: Use MIT licence.  Fix deploys with Capistrano 3 ([#163](https://github.com/kjvarga/sitemap_generator/issues/163)).  Allow any Fog storage options for S3 adapter ([#167](https://github.com/kjvarga/sitemap_generator/pull/167)).
* v5.0.4: Don't include the `media` attribute on alternate links unless it's given
* v5.0.3: Add support for Video sitemaps options `:live` and ':requires_subscription'
* v5.0.2: Set maximum filesize to 10,000,000 bytes rather than 10,485,760 bytes.
* v5.0.1: Include new `SitemapGenerator::FogAdapter` ([#138](https://github.com/kjvarga/sitemap_generator/pull/138)).  Fix usage of attr_* methods in LinkSet; don't override custom getters/setters ([#144](https://github.com/kjvarga/sitemap_generator/pull/144)). Fix breaking spec in Ruby 2 ([#142](https://github.com/kjvarga/sitemap_generator/pull/142)).  Include Capistrano 3.x tasks ([#141](https://github.com/kjvarga/sitemap_generator/pull/141)).
* v5.0.0: Support new `:compress` option for customizing which files get compressed.  Remove old deprecated methods (see deprecation notices above).  Support `fog_path_style` option in the `SitemapGenerator::S3Adapter` so buckets with dots in the name work over HTTPS without SSL certificate problems.
* v4.3.1: Support integer timestamps.  Update README for new features added in last release.
* v4.3.0: Support `media` attibute on alternate links ([#125](https://github.com/kjvarga/sitemap_generator/issues/125)).  Changed `SitemapGenerator::S3Adapter` to write files in a single operation, avoiding potential permissions errors when listing a directory prior to writing ([#130](https://github.com/kjvarga/sitemap_generator/issues/130)).  Remove Sitemap Writer from ping task ([#129](https://github.com/kjvarga/sitemap_generator/issues/129)).  Support `url:expires` element ([#126](https://github.com/kjvarga/sitemap_generator/issues/126)).
* v4.2.0: Update Google ping URL.  Quote the ping URL in the output.  Support Video `video:price` element ([#117](https://github.com/kjvarga/sitemap_generator/issues/117)).  Support symbols as well as strings for most arguments to `add()` ([#113](https://github.com/kjvarga/sitemap_generator/issues/113)).  Ensure that `public_path` and `sitemaps_path` end with a slash (`/`) ([#113](https://github.com/kjvarga/sitemap_generator/issues/118)).
* v4.1.1: Support setting the S3 region.  Fixed bug where incorrect URL was being used in the ping to search engines - only affected sites with a single sitemap file and no index file.  Output the URL being pinged in the verbose output.  Test in Rails 4.
* v4.1.0: [PageMap sitemap][using_pagemaps] support.  Tested with Rails 4 pre-release.
* v4.0.1: Add a post install message regarding the naming convention change.
* **v4.0: NEW, NON-BACKWARDS COMPATIBLE CHANGES.**  See above for more info. `create_index` defaults to `:auto`.  Define `SitemapGenerator::SimpleNamer` class for simpler custom namers compatible with the new naming conventions.  Deprecate `sitemaps_namer`, `sitemap_index_namer` and their respective namer classes.  It's more just that their usage is discouraged.  Support `nofollow` option on alternate links.  Fix formatting of `publication_date` in News sitemaps.
* v3.4: Support [alternate links][alternate_links] for urls; Support configurable options in the `SitemapGenerator::S3Adapter`
* v3.3: **Support creating sitemaps with no index file**.  A big thank-you to [Eric Hochberger][ehoch] for generously paying for this feature.
* v3.2.1: Fix syntax error in SitemapGenerator::S3Adapter
* v3.2: **Support mobile tags**, **SitemapGenerator::S3Adapter** a simple S3 adapter which uses Fog and doesn't require CarrierWave; Remove Ask from the sitemap ping because the service has been shutdown; [Turn off `include_index`][include_index_change] by default; Fix the news XML namespace;  Only include autoplay attribute if present
* v3.1.1: Bugfix: Groups inherit current adapter
* v3.1.0: Add `add_to_index` method to add links to the sitemap index.  Add `sitemap` method for accessing the LinkSet instance from within `create()`.  Don't modify options hashes passed to methods.  Fix and improve `yield_sitemap` option handling.
* **v3.0.0: Framework agnostic**; fix alignment in output, show directory sitemaps are being generated into, only show sitemap compressed file size; toggle output using VERBOSE environment variable; remove tasks/ directory because it's deprecated in Rails 2;  Simplify dependencies.
* v2.2.1: Support adding new search engines to ping and modifying the default search engines.
          Allow the URL of the sitemap index to be passed as an argument to `ping_search_engines`.  See **Pinging Search Engines**.
* v2.1.8: Extend and improve Video Sitemap support.  Include sitemap docs in the README, support all element attributes, properly format values.
* v2.1.7: Improve format of float priorities; Remove Yahoo from ping - the Yahoo
          service has been shut down.
* v2.1.6: Fix the lastmod value on sitemap file links
* v2.1.5: Fix verbose setting in the rake tasks; should default to true
* v2.1.4: Allow special characters in URLs (don't use URI.join to construct URLs)
* v2.1.3: Fix calling create with both `filename` and `sitemaps_namer` options
* v2.1.2: Support multiple videos per url using the new `videos` option to `add()`.
* v2.1.1: Support calling `create()` multiple times in a sitemap config.  Support host names with path segments so you can use a `default_host` like `'http://mysite.com/subdirectory/'`.  Turn off `include_index` when the `sitemaps_host` differs from `default_host`.  Add docs about how to upload to remote hosts.
* v2.1.0: [News sitemap][sitemap_news] support
* v2.0.1.pre2: Fix uploading to the (bucket) root on a remote server
* v2.0.1.pre1: Support read-only filesystems like Heroku by supporting uploading to remote host
* v2.0.1: Minor improvements to verbose handling; prevent missing Timeout issue
* **v2.0.0: Introducing a new simpler API, Sitemap Groups, Sitemap Namers and more!**
* v1.5.0: New options `include_root`, `include_index`; Major testing & refactoring
* v1.4.0: [Geo sitemap][geo_tags] support, multiple sitemap support via CONFIG_FILE rake option
* v1.3.0: Support setting the sitemaps path
* v1.2.0: Verified working with Rails 3 stable release
* v1.1.0: [Video sitemap][sitemap_video] support
* v0.2.6: [Image Sitemap][sitemap_images] support
* v0.2.5: Rails 3 prerelease support (beta)


## Foreword

Adam Salter first created SitemapGenerator while we were working together in Sydney, Australia.  Unfortunately, he passed away in 2009.  Since then I have taken over development of SitemapGenerator.

Those who knew him know what an amazing guy he was, and what an excellent Rails programmer he was.  His passing is a great loss to the Rails community.

The canonical repository is now: [http://github.com/kjvarga/sitemap_generator][canonical_repo]


## Install

### Ruby

```
gem install 'sitemap_generator'
```

To use the rake tasks add the following to your `Rakefile`:

```ruby
require 'sitemap_generator/tasks'
```

The Rake tasks expect your sitemap to be at `config/sitemap.rb` but if you need to change that call like so: `rake sitemap:refresh CONFIG_FILE="path/to/sitemap.rb"`

### Rails

SitemapGenerator works will all versions of Rails and has been tested in Rails 2, 3 and 4.

Add the gem to your `Gemfile`:

```ruby
gem 'sitemap_generator'
```

Alternatively, if you are not using a `Gemfile` add the gem to your `config/environment.rb` file config block:

```ruby
config.gem 'sitemap_generator'
```


**Rails 1 or 2 only**, add the following code to your `Rakefile` to include the gem's Rake tasks in your project (Rails 3 does this for you automatically, so this step is not necessary):

```ruby
begin
  require 'sitemap_generator/tasks'
rescue Exception => e
  puts "Warning, couldn't load gem tasks: #{e.message}! Skipping..."
end
```

_If you would prefer to install as a plugin (deprecated) don't do any of the above.  Simply run `script/plugin install git://github.com/kjvarga/sitemap_generator.git` from your application root directory._

## Getting Started

### Preventing Output

To disable all non-essential output set the environment variable `VERBOSE=false` when calling Rake or running your Ruby script.

Alternatively you can pass the `-s` option to Rake, for example `rake -s sitemap:refresh`.

To disable output in-code use the following:

```ruby
SitemapGenerator.verbose = false
```

### Rake Tasks

* `rake sitemap:install` will create a `config/sitemap.rb` file which is your sitemap configuration and contains everything needed to build your sitemap.  See **Sitemap Configuration** below for more information about how to define your sitemap.
* `rake sitemap:refresh` will create or rebuild your sitemap files as needed.  Sitemaps are generated into the `public/` folder and by default are named `sitemap_index.xml.gz`, `sitemap1.xml.gz`, `sitemap2.xml.gz`, etc.  As you can see they are automatically gzip compressed for you.
* `rake sitemap:refresh` will output information about each sitemap that is written including its location, how many links it contains and the size of the file.


### Pinging Search Engines

Using `rake sitemap:refresh` will notify major search engines to let them know that a new sitemap is available (Google, Bing).  To generate new sitemaps without notifying search engines (for example when running in a local environment) use `rake sitemap:refresh:no_ping`.

If you want to customize the hash of search engines you can access it at:

```ruby
SitemapGenerator::Sitemap.search_engines
```

Usually you would be adding a new search engine to ping.  In this case you can modify the `search_engines` hash directly.  This ensures that when `SitemapGenerator::Sitemap.ping_search_engines` is called your new search engine will be included.

If you are calling `ping_search_engines` manually (for example if you have to wait some time or perform a custom action after your sitemaps have been regenerated) then you can pass you new search engine directly in the call as in the following example:

```ruby
SitemapGenerator::Sitemap.ping_search_engines(:newengine => 'http://newengine.com/ping?url=%s')
```

The key gives the name of the search engine as a string or symbol and the value is the full URL to ping with a string interpolation that will be replaced by the CGI escaped sitemap index URL.  If you have any literal percent characters in your URL you need to escape them with `%%`.

If you are calling `SitemapGenerator::Sitemap.ping_search_engines` from outside of your sitemap config file then you will need to set `SitemapGenerator::Sitemap.default_host` and any other options that you set in your sitemap config which affect the location of the sitemap index file.  For example:

```ruby
SitemapGenerator::Sitemap.default_host = 'http://example.com'
SitemapGenerator::Sitemap.ping_search_engines
```

Alternatively you can pass in the full URL to your sitemap index in which case we would have just the following:

```ruby
SitemapGenerator::Sitemap.ping_search_engines('http://example.com/sitemap.xml.gz')
```

### Crontab

To keep your sitemaps up-to-date, setup a cron job.  Make sure to pass the `-s` option to silence rake.  That way you will only get email if the sitemap build fails.

If you're using [Whenever](https://github.com/javan/whenever), your schedule would look something like this:

```ruby
# config/schedule.rb
every 1.day, :at => '5:00 am' do
  rake "-s sitemap:refresh"
end
```


### Robots.txt

You should add the URL of the sitemap index file to `public/robots.txt` to help search engines find your sitemaps.  The URL should be the complete URL to the sitemap index.  For example:

```
Sitemap: http://www.example.com/sitemap.xml.gz
```

### Ruby Modules

If you need to include a module (e.g. a rails helper) you can add the following line:

```ruby
SitemapGenerator::Interpreter.send :include, RoutingHelper
```

## Deployments & Capistrano

To include the capistrano tasks just add the following to your Capfile:

```ruby
require 'capistrano/sitemap_generator'
```

Available capistrano tasks:

```ruby
deploy:sitemap:create   #Create sitemaps without pinging search engines
deploy:sitemap:refresh  #Create sitemaps and ping search engines
deploy:sitemap:clean    #Clean up sitemaps in the sitemap path
```

  **Generate sitemaps into a directory which is shared by all deployments.**

  You can set your sitemaps path to your shared directory using the `sitemaps_path` option.  For example if we have a directory `public/shared/` that is shared by all deployments we can have our sitemaps generated into that directory by setting:

```ruby
SitemapGenerator::Sitemap.sitemaps_path = 'shared/'
```

### Sitemaps with no Index File

The sitemap index file is created for you on-demand, meaning that if you have a large site with more than one sitemap file, you will have a sitemap index file to reference those sitemap files.  If however you have a small site with only one sitemap file, you don't require an index and so no index will be created.  In both cases the index and sitemap file's name, respectively, is `sitemap.xml.gz`.

You may want to always create an index, even if you only have a small site.  Or you may never want to create an index.  For these cases, you can use the `create_index` option to control index creation.  You can read about this option in the Sitemap Options section below.

To always create an index:

```ruby
SitemapGenerator::Sitemap.create_index = true
```

To never create an index:

```ruby
SitemapGenerator::Sitemap.create_index = false
```
Your sitemaps will still be called `sitemap.xml.gz`, `sitemap1.xml.gz`, `sitemap2.xml.gz`, etc.

And the default "intelligent" behaviour:

```ruby
SitemapGenerator::Sitemap.create_index = :auto
```

### Upload Sitemaps to a Remote Host using Adapters

_This section needs better documentation.  Please consider contributing._

#### Supported Adapters
* `SitemapGenerator::FileAdapter`

  Standard adapter, writes out to a file

* `SitemapGenerator::FogAdapter`

  Uses `fog` to upload to any service supported by Fog.

* `SitemapGenerator::S3Adapter`

  Uses `fog-aws` to upload to Amazon S3 storage.

* `SitemapGenerator::WaveAdapter`

  Uses `carrierwave` to upload to any service supported by CarrierWave.

Some documentation exists [on the wiki page][remote_hosts].

Sometimes it is desirable to host your sitemap files on a remote server and point robots
and search engines to the remote files.  For example if you are using a host like Heroku
which doesn't allow writing to the local filesystem.  You still require *some* write access
because the sitemap files need to be written out before uploading, so generally a host will
give you write access to a temporary directory.  On Heroku this is `tmp/` in your application
directory.

Sitemap Generator uses CarrierWave to support uploading to Amazon S3 store, Rackspace Cloud Files store, and MongoDB's GridF - whatever CarrierWave supports.

1. Please see [this wiki page][remote_hosts] for more information about setting up CarrierWave, SitemapGenerator and Rails.

2. Once you have CarrierWave setup and configured all you need to do is set some options in your sitemap config, such as

     ```ruby
     # Your website's host name
     SitemapGenerator::Sitemap.default_host = "http://www.example.com"

     # The remote host where your sitemaps will be hosted
     SitemapGenerator::Sitemap.sitemaps_host = "http://s3.amazonaws.com/sitemap-generator/"

     # The directory to write sitemaps to locally
     SitemapGenerator::Sitemap.public_path = 'tmp/'

     # Set this to a directory/path if you don't want to upload to the root of your `sitemaps_host`
     SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'

     # Instance of `SitemapGenerator::WaveAdapter`
     SitemapGenerator::Sitemap.adapter = SitemapGenerator::WaveAdapter.new
     ```

3. Update your `robots.txt` file to point robots to the remote sitemap index file, e.g:

    ```
    Sitemap: http://s3.amazonaws.com/sitemap-generator/sitemaps/sitemap_index.xml.gz
    ```

    You generate your sitemaps as usual using `rake sitemap:refresh`.

    Note that SitemapGenerator will automatically turn off `include_index` in this case because
    the `sitemaps_host` does not match the `default_host`.  The link to the sitemap index file
    that would otherwise be included would point to a different host than the rest of the links
    in the sitemap, something that the sitemap rules forbid.  (Since version 3.2 this is no
    longer an issue because [`include_index` is off by default][include_index_change].)

4. Verify to google that you own the s3 url

    In order for Google to use your sitemap, you need to prove you own the s3 bucket through [google webmaster tools](https://www.google.com/webmasters/tools/home?hl=en).  In the example above, you would add the site `http://s3.amazonaws.com/sitemap-generator/sitemaps`.  Once you have verified you own the directory then add your `sitemap.xml.gz` to this list of sitemaps for the site.

### Generating Multiple Sitemaps

Each call to `create` creates a new sitemap index and associated sitemaps.  You can call `create` as many times as you want within your sitemap configuration.

You must remember to use a different filename or location for each set of sitemaps, otherwise they will
overwrite each other.  You can use the `filename`, `namer` and `sitemaps_path` options for this.

In the following example we generate three sitemaps each in its own subdirectory:

```ruby
%w(google bing apple).each do |subdomain|
  SitemapGenerator::Sitemap.default_host = "https://#{subdomain}.mysite.com"
  SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/#{subdomain}"
  SitemapGenerator::Sitemap.create do
    add '/home'
  end
end
```

Outputs:

```
+ sitemaps/google/sitemap1.xml.gz             2 links /  822 Bytes /  328 Bytes gzipped
+ sitemaps/google/sitemap.xml.gz           1 sitemaps /  389 Bytes /  217 Bytes gzipped
Sitemap stats: 2 links / 1 sitemaps / 0m00s
+ sitemaps/bing/sitemap1.xml.gz               2 links /  820 Bytes /  330 Bytes gzipped
+ sitemaps/bing/sitemap.xml.gz             1 sitemaps /  388 Bytes /  217 Bytes gzipped
Sitemap stats: 2 links / 1 sitemaps / 0m00s
+ sitemaps/apple/sitemap1.xml.gz              2 links /  820 Bytes /  330 Bytes gzipped
+ sitemaps/apple/sitemap.xml.gz            1 sitemaps /  388 Bytes /  214 Bytes gzipped
Sitemap stats: 2 links / 1 sitemaps / 0m00s
```

If you don't want to have to generate all the sitemaps at once, or you want to refresh some more often than others, you can split them up into their own configuration files.  Using the above example we would have:

```ruby
# config/google_sitemap.rb
SitemapGenerator::Sitemap.default_host = "https://google.mysite.com"
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/google"
SitemapGenerator::Sitemap.create do
  add '/home'
end

# config/apple_sitemap.rb
SitemapGenerator::Sitemap.default_host = "https://apple.mysite.com"
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/apple"
SitemapGenerator::Sitemap.create do
  add '/home'
end

# config/bing_sitemap.rb
SitemapGenerator::Sitemap.default_host = "https://bing.mysite.com"
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/bing"
SitemapGenerator::Sitemap.create do
  add '/home'
end
```


To generate each one specify the configuration file to run by passing the `CONFIG_FILE` option to `rake sitemap:refresh`, e.g.:

```
rake sitemap:refresh CONFIG_FILE="config/google_sitemap.rb"
rake sitemap:refresh CONFIG_FILE="config/apple_sitemap.rb"
rake sitemap:refresh CONFIG_FILE="config/bing_sitemap.rb"
```

## Sitemap Configuration

A sitemap configuration file contains all the information needed to generate your sitemaps.  By default SitemapGenerator looks for a configuration file in  `config/sitemap.rb` - relative to your application root or the current working directory.  (Run `rake sitemap:install` to have this file generated for you if you have not done so already.)

If you want to use a non-standard configuration file, or have multiple configuration files, you can specify which one to run by passing the `CONFIG_FILE` option like so:

```
rake sitemap:refresh CONFIG_FILE="config/geo_sitemap.rb"
```


### A Simple Example

So what does a sitemap configuration look like?  Let's take a look at a simple example:

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create do
  add '/welcome'
end
```

A few things to note:

* `SitemapGenerator::Sitemap` is a lazy-initialized sitemap object provided for your convenience.
* Every sitemap must set `default_host`.  This is the hostname that is used when building links to add to the sitemap (and all links in a sitemap must belong to the same host).
* The `create` method takes a block with calls to `add` to add links to the sitemap.
* The sitemaps are written to the `public/` directory in the directory from which the script is run.  You can specify a custom location using the `public_path` or `sitemaps_path` option.

Now let's see what is output when we run this configuration with `rake sitemap:refresh:no_ping`:

```
In /Users/karl/projects/sitemap_generator-test/public/
+ sitemap.xml.gz                                           2 links /  347 Bytes
Sitemap stats: 2 links / 1 sitemaps / 0m00s
```

Weird!  The sitemap has two links, even though we only added one!  This is because SitemapGenerator adds the root URL `/` for you by default.  (Note that prior to version 3.2 the  URL of the sitemap index file was also added to the sitemap by default but [this behaviour has been changed][include_index_change] because of Google complaining about nested indexing.  This also doesn't make sense anymore because indexes are not always needed.)  You can change the default behaviour by setting the `include_root` or `include_index` option.

Now let's take a look at the file that was created.  After uncompressing and XML-tidying the contents we have:


* `public/sitemap.xml.gz`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1" xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:video="http://www.google.com/schemas/sitemap-video/1.1" xmlns:geo="http://www.google.com/geo/schemas/sitemap/1.0" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
  <url>
    <loc>http://www.example.com/</loc>
    <lastmod>2011-05-21T00:03:38+00:00</lastmod>
    <changefreq>always</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>http://www.example.com/welcome</loc>
    <lastmod>2011-05-21T00:03:38+00:00</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.5</priority>
  </url>
</urlset>
```

The sitemaps conform to the [Sitemap 0.9 protocol][sitemap_protocol].  Notice the value for `priority` and `changefreq` on the root link, the one that was added for us?  The values tell us that this link is the highest priority and should be checked regularly because it are constantly changing.  You can specify your own values for these options in your call to `add`.

In this example no sitemap index was created because we have so few links, so none was needed.  If we run the same example above and set `create_index = true` we can take a look at what an index file looks like:

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create_index = true
SitemapGenerator::Sitemap.create do
  add '/welcome'
end
```

And the output:

```
In /Users/karl/projects/sitemap_generator-test/public/
+ sitemap1.xml.gz                                          2 links /  347 Bytes
+ sitemap.xml.gz                                        1 sitemaps /  228 Bytes
Sitemap stats: 2 links / 1 sitemaps / 0m00s
```

Now if we look at the uncompressed and formatted contents of `sitemap.xml.gz` we can see that it is a sitemap index and `sitemap1.xml.gz` is a sitemap:

* `public/sitemap.xml.gz`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9/siteindex.xsd">
  <sitemap>
    <loc>http://www.example.com/sitemap1.xml.gz</loc>
    <lastmod>2013-05-01T18:10:26-07:00</lastmod>
  </sitemap>
</sitemapindex>
```

### Adding Links

You call `add` in the block passed to `create` to add a **path** to your sitemap.  `add` takes a string path and optional hash of options, generates the URL and adds it to the sitemap.  You only need to pass a **path** because the URL will be built for us using the `default_host` we specified.  However, if we want to use a different host for a particular link, we can pass the `:host` option to `add`.

Let's see another example:

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create do
  add '/contact_us'
  Content.find_each do |content|
    add content_path(content), :lastmod => content.updated_at
  end
end
```

In this example first we add the `/contact_us` page to the sitemap and then we iterate through the Content model's records adding each one to the sitemap using the `content_path` helper method to generate the path for each record.

The **Rails URL/path helper methods are automatically made available** to us in the `create` block.  This keeps the logic for building our paths out of the sitemap config and in the Rails application where it should be.  You use those methods just like you would in your application's view files.

In the example about we pass a `lastmod` (last modified) option with the value of the record's `updated_at` attribute so that search engines know to only re-index the page when the record changes.

Looking at the output from running this sitemap, we see that we have a few more links than before:

```
+ sitemap.xml.gz                   12 links /     2.3 KB /  365 Bytes gzipped
Sitemap stats: 12 links / 1 sitemaps / 0m00s
```

From this example we can see that:

* The `create` block can contain Ruby code
* The Rails URL/path helper methods are made available to us, and
* The basic syntax for adding paths to the sitemap using `add`

You can read more about `add` in the [XML Specification](http://www.sitemaps.org/protocol.html#xmlTagDefinitions).

### Supported Options to `add`

For other options be sure to check out the **Sitemap Extensions** section below.

* `changefreq` - Default: `'weekly'` (String).

  Indicates how often the content of the page changes.  One of `'always'`, `'hourly'`, `'daily'`, `'weekly'`, `'monthly'`, `'yearly'` or `'never'`.  Example:

```ruby
add '/contact_us', :changefreq => 'monthly'
```

* `lastmod` - Default: `Time.now` (Integer, Time, Date, DateTime, String).

  The date and time of last modification.  Example:

```ruby
add content_path(content), :lastmod => content.updated_at
```

* `host` - Default: `default_host` (String).

  Host to use when building the URL.  It's not technically valid to specify a different host for a link in a sitemap according to the spec, but this facility exists in case you have a need.  Example:

```ruby
add '/login', :host => 'https://securehost.com'
```

* `priority` - Default: `0.5` (Float).

  The priority of the URL relative to other URLs on a scale from 0 to 1.   Example:

```ruby
add '/about', :priority => 0.75
```

* `expires` - Optional (Integer, Time, Date, DateTime, String)

  [Request removal of this URL from search engines' indexes][expires].   Example (uses ActiveSupport):

```ruby
add '/about', :expires => Time.now + 2.weeks
```

### Adding Links to the Sitemap Index

Sometimes you may need to manually add some links to the sitemap index file.  For example if you are generating your sitemaps incrementally you may want to create a sitemap index which includes the files which have already been generated.  To achieve this you can use the `add_to_index` method which works exactly the same as the `add` method described above.

It supports the same options as `add`, namely:

* `changefreq`
* `lastmod`
* `host`

  The value for `host` defaults to whatever you have set as your `sitemaps_host`.  Remember that the `sitemaps_host` is the host where your sitemaps reside.  If your sitemaps are on the same host as your `default_host`, then the value for `default_host` is used.  Example:

```ruby
add_to_index '/mysitemap1.xml.gz', :host => 'http://sitemaphostingserver.com'
```

* `priority`

An example:

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create do
  add_to_index '/mysitemap1.xml.gz'
  add_to_index '/mysitemap2.xml.gz'
  # ...
end
```

When you add links in this way, an index is always created, unless you've explicitly set `create_index` to `false`.

### Accessing the LinkSet instance

Sometimes you need to mess with the internals to do custom stuff.  If you need access to the LinkSet instance from within `create()` you can use the `sitemap` method to do so.

In this example, say we have already pre-generated three sitemap files: `sitemap1.xml.gz`, `sitemap2.xml.gz`, `sitemap3.xml.gz`.  Now we want to start the sitemap generation at `sitemap4.xml.gz` and create a bunch of new sitemaps.  There are a few ways we can do this, but this is an easy way:

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.namer = SitemapGenerator::SimpleNamer.new(:sitemap, :start => 4)
SitemapGenerator::Sitemap.create do
  (1..3).each do |i|
    add_to_index "sitemap#{i}.xml.gz"
  end
  add '/home'
  add '/another'
end
```

The output looks something like this:

```
In /Users/karl/projects/sitemap_generator-test/public/
+ sitemap4.xml.gz                                          3 links /  355 Bytes
+ sitemap.xml.gz                                        4 sitemaps /  242 Bytes
Sitemap stats: 3 links / 4 sitemaps / 0m00s
```

### Speeding Things Up

For large ActiveRecord collections with thousands of records it is advisable to iterate through them in batches to avoid loading all records into memory at once.  For this reason in the example above we use `Content.find_each` which is a batched iterator available since Rails 2.3.2, rather than `Content.all`.


## Customizing your Sitemaps

SitemapGenerator supports a number of options which allow you to control every aspect of your sitemap generation.  How they are named, where they are stored, the contents of the links and the location that the sitemaps will be hosted from can all be set.

The options can be set in the following ways.

On `SitemapGenerator::Sitemap`:

```ruby
SitemapGenerator::Sitemap.default_host = 'http://example.com'
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'
```

These options will apply to all sitemaps.  This is how you set most options.

Passed as options in the call to `create`:

```ruby
SitemapGenerator::Sitemap.create(
    :default_host => 'http://example.com',
    :sitemaps_path => 'sitemaps/') do
  add '/home'
end
```

This is useful if you are setting a lot of options.

Finally, passed as options in a call to `group`:

```ruby
SitemapGenerator::Sitemap.create(:default_host => 'http://example.com') do
  group(:filename => :somegroup, :sitemaps_path => 'sitemaps/') do
    add '/home'
  end
end
```

The options passed to `group` only apply to the links and sitemaps generated in the group.  Sitemap Groups are useful to group links into specific sitemaps, or to set options that you only want to apply to the links in that group.

### Sitemap Options

The following options are supported.

* `:create_index` - Supported values: `true`, `false`, `:auto`.  Default: `true`. Whether to create a sitemap index file.  If `true` an index file is always created regardless of how many sitemap files are generated.  If `false` an index file is never created.  If `:auto` an index file is created only when you have more than one sitemap file (i.e. you have added more than 50,000 - `SitemapGenerator::MAX_SITEMAP_LINKS` - links).

* `:default_host` - String.  Required.  **Host including protocol** to use when building a link to add to your sitemap.  For example `http://example.com`.  Calling `add '/home'` would then generate the URL `http://example.com/home` and add that to the sitemap.  You can pass a `:host` option in your call to `add` to override this value on a per-link basis.  For example calling `add '/home', :host => 'https://example.com'` would generate the URL `https://example.com/home`, for that link only.

* `:filename` - Symbol.  The **base name for the files** that will be generated.  The default value is `:sitemap`.  This yields files with names like `sitemap.xml.gz`, `sitemap1.xml.gz`, `sitemap2.xml.gz`, `sitemap3.xml.gz` etc.  If we now set the value to `:geo` the files would be named `geo.xml.gz`, `geo1.xml.gz`, `geo2.xml.gz`, `geo3.xml.gz` etc.

* `:include_index` - Boolean.  Whether to **add a link pointing to the sitemap index** to the current sitemap.  This points search engines to your Sitemap Index to include it in the indexing of your site.  2012-07: This is now turned off by default because Google may complain about there being 'Nested Sitemap indexes'.  Default is `false`.  Turned off when `sitemaps_host` is set or within a `group()` block.

* `:include_root` - Boolean.  Whether to **add the root** url i.e. '/' to the current sitemap.  Default is `true`.  Turned off within a `group()` block.

* `:public_path` - String.  A **full or relative path** to the `public` directory or the directory you want to write sitemaps into.  Defaults to `public/` under your application root or relative to the current working directory.

* `:sitemaps_host` - String.  **Host including protocol** to use when generating a link to a sitemap file i.e. the hostname of the server where the sitemaps are hosted.  The value will differ from the hostname in your sitemap links.  For example: `'http://amazon.aws.com/'`.  Note that `include_index` is
automatically turned off when the `sitemaps_host` does not match `default_host`.
Because the link to the sitemap index file that would otherwise be added would point to a different host than the rest of the links in the sitemap.  Something that the sitemap rules forbid.

* `:namer` - A `SitemapGenerator::SimpleNamer` instance **for generating sitemap names**.  You can read about Sitemap Namers by reading the API docs.  Allows you to set the name, extension and number sequence for sitemap files, as well as modify the name of the first file in the sequence, which is often the index file.  A simple example if we want to generate files like 'newname.xml.gz', 'newname1.xml.gz', etc is `SitemapGenerator::SimpleNamer.new(:newname)`.

* `:sitemaps_path` - String. A **relative path** giving a directory under your `public_path` at which to write sitemaps.  The difference between the two options is that the `sitemaps_path` is used when generating a link to a sitemap file.  For example, if we set `SitemapGenerator::Sitemap.sitemaps_path = 'en/'` and use the default `public_path` sitemaps will be written to `public/en/`.  The URL to the sitemap index would then be `http://example.com/en/sitemap.xml.gz`.

* `:verbose` - Boolean.  Whether to **output a sitemap summary** describing the sitemap files and giving statistics about your sitemap.  Default is `false`.  When using the Rake tasks `verbose` will be `true` unless you pass the `-s` option.

* `:adapter` - Instance.  The default adapter is a `SitemapGenerator::FileAdapter` which simply writes files to the filesystem.  You can use a `SitemapGenerator::WaveAdapter` for uploading sitemaps to remote servers - useful for read-only hosts such as Heroku.  Or you can provide an instance of your own class to provide custom behavior.  Your class must define a write method which takes a `SitemapGenerator::Location` and raw XML data.

* `:compress` - Specifies which files to compress with gzip.  Default is `true`. Accepted values:
    * `true` - Boolean; compress all files.
    * `false` - Boolean; Do not compress any files.
    * `:all_but_first` - Symbol; leave the first file uncompressed but compress all remaining files.

  The compression setting applies to groups too.  So `:all_but_first` will have the same effect (the first file in the group will not be compressed, the rest will).  So if you require different behaviour for your groups, pass in a `:compress` option e.g. `group(:compress => false) { add('/link') }`

## Sitemap Groups

Sitemap Groups is a powerful feature that is also very simple to use.

* All options are supported except for `public_path`.  You cannot change the public path.
* Groups inherit the options set on the default sitemap.
* `include_index` and `include_root` are `false` by default in a group.
* The sitemap index file is shared by all groups.
* Groups can handle any number of links.
* Group sitemaps are finalized (written out) as they get full and at the end of each group.
* It's a good idea to name your groups

### A Groups Example

When you create a new group you pass options which will apply only to that group.  You pass a block to `group`.  Inside your block you call `add` to add links to the group.

Let's see an example that demonstrates a few interesting things about groups:

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create do
  add '/rss'

  group(:sitemaps_path => 'en/', :filename => :english) do
    add '/home'
  end

  group(:sitemaps_path => 'fr/', :filename => :french) do
    add '/maison'
  end
end
```

And the output from running the above:

```
In /Users/karl/projects/sitemap_generator-test/public/
+ en/english.xml.gz                                        1 links /  328 Bytes
+ fr/french.xml.gz                                         1 links /  329 Bytes
+ sitemap1.xml.gz                                          2 links /  346 Bytes
+ sitemap.xml.gz                                        3 sitemaps /  252 Bytes
Sitemap stats: 4 links / 3 sitemaps / 0m00s
```

So we have two sitemaps with one link each and one sitemap with two links.  The sitemaps from the groups are easy to spot by their filenames.  They are `english.xml.gz` and `french.xml.gz`.  They contain only one link each because **`include_index` and `include_root` are set to `false` by default** in a group.

On the other hand, the default sitemap which we added `/rss` to has two links.  The root url was added to it when we added `/rss`.  If we hadn't added that link `sitemap1.xml.gz` would not have been created.  So **when we are using groups, the default sitemap will only be created if we add links to it**.

**The sitemap index file is shared by all groups**.  You can change its filename by setting `SitemapGenerator::Sitemap.filename` or by passing the `:filename` option to `create`.

The options you use when creating your groups will determine which and how many sitemaps are created.  Groups will inherit the default sitemap when possible, and will continue the normal series.  However a group will often specify an option which requires the links in that group to be in their own files.  In this case, if the default sitemap were being used it would be finalized before starting the next sitemap in the series.

If you have changed your sitemaps physical location in a group, then the default sitemap will not be used and it will be unaffected by the group.  **Group sitemaps are finalized as they get full and at the end of each group.**


## Sitemap Extensions

### News Sitemaps

A news item can be added to a sitemap URL by passing a `:news` hash to `add`.  The hash must  contain tags defined by the [News Sitemap][news_tags] specification.

#### Example

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create do
  add('/index.html', :news => {
      :publication_name => "Example",
      :publication_language => "en",
      :title => "My Article",
      :keywords => "my article, articles about myself",
      :stock_tickers => "SAO:PETR3",
      :publication_date => "2011-08-22",
      :access => "Subscription",
      :genres => "PressRelease"
  })
end
```

#### Supported options

* `:news` - Hash
    * `:publication_name`
    * `:publication_language`
    * `:publication_date`
    * `:genres`
    * `:access`
    * `:title`
    * `:keywords`
    * `:stock_tickers`

### Image Sitemaps

Images can be added to a sitemap URL by passing an `:images` array to `add`.  Each item in the array must be a Hash containing tags defined by the [Image Sitemap][image_tags] specification.

#### Example

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create do
  add('/index.html', :images => [{
    :loc => 'http://www.example.com/image.png',
    :title => 'Image' }])
end
```

#### Supported options

* `:images` - Array of hashes
    * `:loc` Required, location of the image
    * `:caption`
    * `:geo_location`
    * `:title`
    * `:license`

### Video Sitemaps

A video can be added to a sitemap URL by passing a `:video` Hash to `add()`.  The Hash can contain tags defined by the [Video Sitemap specification][video_tags].

To add more than one video to a url, pass an array of video hashes using the `:videos` option.

#### Example

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create do
  add('/index.html', :video => {
    :thumbnail_loc => 'http://www.example.com/video1_thumbnail.png',
    :title => 'Title',
    :description => 'Description',
    :content_loc => 'http://www.example.com/cool_video.mpg',
    :tags => %w[one two three],
    :category => 'Category'
  })
end
```

#### Supported options

* `:video` or `:videos` - Hash or array of hashes, respectively
    * `:thumbnail_loc` - Required.  String, URL of the thumbnail image.
    * `:title` - Required.  String, title of the video.
    * `:description` - Required.  String, description of the video.
    * `:content_loc` - Depends. String, URL.  One of content_loc or player_loc must be present.
    * `:player_loc` - Depends. String, URL.  One of content_loc or player_loc must be present.
    * `:allow_embed` - Boolean, attribute of player_loc.
    * `:autoplay` - Boolean, default true.  Attribute of player_loc.
    * `:duration` - Recommended. Integer or string.  Duration in seconds.
    * `:expiration_date` - Recommended when applicable.  The date after which the video will no longer be available.
    * `:rating` - Optional
    * `:view_count` - Optional. Integer or string.
    * `:publication_date` - Optional
    * `:tags` - Optional. Array of string tags.
    * `:tag` - Optional. String, single tag.
    * `:category` - Optional
    * `:family_friendly`- Optional. Boolean
    * `:gallery_loc` - Optional. String, URL.
    * `:gallery_title` - Optional. Title attribute of the gallery location element
    * `:uploader` - Optional.
    * `:uploader_info` - Optional. Info attribute of uploader element
    * `:price` - Optional. Only one price supported at this time
        * `:price_currency` - Required.  In [ISO_4217][iso_4217] format.
        * `:price_type` - Optional. `rent` or `own`
        * `:price_resolution` - Optional. `HD` or `SD`
    * `:live` - Optional. Boolean.
    * `:requires_subscription` - Optional. Boolean.

### Geo Sitemaps

Pages with geo data can be added by passing a `:geo` Hash to `add`.  The Hash only supports one tag of `:format`.  Google provides an [example of a geo sitemap link here][geo_tags].  Note that the sitemap does not actually contain your KML or GeoRSS.  It merely links to a page that has this content.

#### Example:

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create do
  add('/stores/1234.xml', :geo => { :format => 'kml' })
end
```

#### Supported options

* `:geo` - Hash
    * `:format` - Required, string, either `'kml'` or `'georss'`

### PageMap Sitemaps

Pagemaps can be added by passing a `:pagemap` hash to `add`. The hash must contain a `:dataobjects` key with an array of dataobject hashes. Each dataobject hash contains a `:type` and `:id`, and an optional array of `:attributes`.  Each attribute hash can contain two keys: `:name` and `:value`, with string values.  For more information consult the [official documentation on PageMaps][using_pagemaps].

#### Supported options

* `:pagemap` - Hash
    * `:dataobjects` - Required, array of hashes
        * `:type` - Required, string, type of the object
        * `:id` - String, ID of the object
        * `:attributes` - Array of hashes
            * `:name` - Required, string, name of the attribute.
            * `:value` - String, value of the attribute.

#### Example:

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create do
  add('/blog/post', :pagemap => {
    :dataobjects => [{
      :type => 'document',
      :id   => 'hibachi',
      :attributes => [
        { :name => 'name',   :value => 'Dragon' },
        { :name => 'review', :value => '3.5' },
      ]
    }]
  })
end
```

### Alternate Links

A useful feature for internationalization is to specify alternate links for a url.

Alternate links can be added by passing an `:alternate` Hash to `add`. You can pass more than one alternate link by passing an array of hashes using the `:alternates` option.

Check out the Google specification [here][alternate_links].

#### Example

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create do
  add('/index.html', :alternate => {
    :href => 'http://www.example.de/index.html',
    :lang => 'de',
    :nofollow => true
  })
end
```

#### Supported options

* `:alternate`/`:alternates` - Hash or array of hashes, respectively
    * `:href` - Required, string.
    * `:lang`  - Optional, string.
    * `:nofollow` - Optional, boolean. Used to mark link as "nofollow".
    * `:media` - Optional, string.  Specify [media targets for responsive design pages][media].

### <a name="internal_mobile"></a> Mobile Sitemaps

Mobile sitemaps include a specific `<mobile:mobile/>` tag.

Check out the Google specification [here][sitemap_mobile].

#### Example

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create do
  add('/index.html', :mobile => true)
end
```

#### Supported options

* `:mobile` - Presence of this option will turn on the mobile flag regardless of value.

## Raison d'être

Most of the Sitemap plugins out there seem to try to recreate the Sitemap links by iterating the Rails routes. In some cases this is possible, but for a great deal of cases it isn't.

a) There are probably quite a few routes in your routes file that don't need inclusion in the Sitemap. (AJAX routes I'm looking at you.)

and

b) How would you infer the correct series of links for the following route?

```ruby
map.zipcode 'location/:state/:city/:zipcode', :controller => 'zipcode', :action => 'index'
```

Don't tell me it's trivial, because it isn't. It just looks trivial.

So my idea is to have another file similar to 'routes.rb' called 'sitemap.rb', where you can define what goes into the Sitemap.

Here's my solution:

```ruby
Zipcode.find(:all, :include => :city).each do |z|
  add zipcode_path(:state => z.city.state, :city => z.city, :zipcode => z)
end
```

Easy hey?

## Compatibility

Tested and working on:

* **Rails** 3.0.0, 3.0.7, 4.2.3
* **Rails** 1.x - 2.3.8
* **Ruby** 1.8.6, 1.8.7, 1.8.7 Enterprise Edition, 1.9.1, 1.9.2, 2.1.3


## Known Bugs

* There's no check on the size of a URL which [isn't supposed to exceed 2,048 bytes][sitemaps_xml].
* Currently only supports one Sitemap Index file, which can contain 50,000 Sitemap files which can each contain 50,000 urls, so it _only_ supports up to 2,500,000,000 (2.5 billion) urls.


## Wishlist & Coming Soon


## Thanks (in no particular order)

I've kind of stopped maintaining the list of contributors.  To all those who have contributed code or a donation, many thanks!

Some past contributors:

* [Eric Hochberger][ehoch]
* [Rodrigo Flores](https://github.com/rodrigoflores) for News sitemaps
* [Alex Soto](http://github.com/apsoto) for Video sitemaps
* [Alexadre Bini](http://github.com/alexandrebini) for Image sitemaps
* [Dan Pickett](http://github.com/dpickett)
* [Rob Biedenharn](http://github.com/rab)
* [Richie Vos](http://github.com/jerryvos)
* [Adrian Mugnolo](http://github.com/xymbol)
* [Jason Weathered](http://github.com/jasoncodes)
* [Andy Stewart](http://github.com/airblade)
* [Brian Armstrong](https://github.com/barmstrong) for Geo sitemaps

Copyright (c) 2009 Karl Varga released under the MIT license

[canonical_repo]:http://github.com/kjvarga/sitemap_generator
[enterprise_class]:https://twitter.com/dhh/status/1631034662 "I use enterprise in the same sense the Phusion guys do - i.e. Enterprise Ruby. Please don't look down on my use of the word 'enterprise' to represent being a cut above. It doesn't mean you ever have to work for a company the size of IBM. Or constantly fight inertia, writing crappy software, adhering to change management practices and spending hours in meetings... Not that there's anything wrong with that - Wait, what?"
[sitemaps_org]:http://www.sitemaps.org/protocol.html "http://www.sitemaps.org/protocol.html"
[sitemaps_xml]:http://www.sitemaps.org/protocol.html#xmlTagDefinitions "XML Tag Definitions"
[sitemap_generator_usage]:http://wiki.github.com/adamsalter/sitemap_generator/sitemapgenerator-usage "http://wiki.github.com/adamsalter/sitemap_generator/sitemapgenerator-usage"
[sitemap_images]:http://www.google.com/support/webmasters/bin/answer.py?answer=178636
[sitemap_video]:https://support.google.com/webmasters/answer/80471?hl=en&ref_topic=4581190
[sitemap_news]:https://support.google.com/news/publisher/topic/2527688?hl=en&ref_topic=4359874
[sitemap_geo]:#
[sitemap_mobile]:http://support.google.com/webmasters/bin/answer.py?hl=en&answer=34648
[sitemap_pagemap]:https://developers.google.com/custom-search/docs/structured_data#addtositemap
[sitemap_protocol]:http://www.sitemaps.org/protocol.html
[video_tags]:http://www.google.com/support/webmasters/bin/answer.py?hl=en&answer=80472#4
[image_tags]:http://www.google.com/support/webmasters/bin/answer.py?hl=en&answer=178636
[geo_tags]:http://www.google.com/support/webmasters/bin/answer.py?hl=en&answer=94555
[news_tags]:http://www.google.com/support/news_pub/bin/answer.py?answer=74288
[remote_hosts]:https://github.com/kjvarga/sitemap_generator/wiki/Generate-Sitemaps-on-read-only-filesystems-like-Heroku
[include_index_change]:https://github.com/kjvarga/sitemap_generator/issues/70
[ehoch]:https://github.com/ehoch
[alternate_links]:http://support.google.com/webmasters/bin/answer.py?hl=en&answer=2620865
[using_pagemaps]:https://developers.google.com/custom-search/docs/structured_data#pagemaps
[iso_4217]:http://en.wikipedia.org/wiki/ISO_4217
[media]:https://developers.google.com/webmasters/smartphone-sites/details
[expires]:https://support.google.com/customsearch/answer/2631051?hl=en
