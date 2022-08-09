# SitemapGenerator

[![CircleCI](https://circleci.com/gh/kjvarga/sitemap_generator/tree/master.svg?style=shield)](https://circleci.com/gh/kjvarga/sitemap_generator/tree/master)

SitemapGenerator is the easiest way to generate Sitemaps in Ruby.  Rails integration provides access to the Rails route helpers within your sitemap config file and automatically makes the rake tasks available to you.  Or if you prefer to use another framework, you can!  You can use the rake tasks provided or run your sitemap configs as plain ruby scripts.

Sitemaps adhere to the [Sitemap 0.9 protocol][sitemap_protocol] specification.

## Features

* Framework agnostic
* Supports [News sitemaps][sitemap_news], [Video sitemaps][sitemap_video], [Image sitemaps][sitemap_images], [Mobile sitemaps][sitemap_mobile], [PageMap sitemaps][sitemap_pagemap] and [Alternate Links][alternate_links]
* Supports read-only filesystems like Heroku via uploading to a remote host like Amazon S3
* Compatible with all versions of Rails and Ruby
* Adheres to the [Sitemap 0.9 protocol][sitemap_protocol]
* Handles millions of links
* Customizable sitemap compression
* Notifies search engines (Google) of new sitemaps
* Ensures your old sitemaps stay in place if the new sitemap fails to generate
* Gives you complete control over your sitemap contents and naming scheme
* Intelligent sitemap indexing

### Show Me

This is a simple standalone example.  For Rails installation see the [Rails instructions](#rails) in the [Install](#installation) section.

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
```

## Contents

- [SitemapGenerator](#sitemapgenerator)
  - [Features](#features)
    - [Show Me](#show-me)
  - [Contents](#contents)
  - [Contribute](#contribute)
  - [Foreword](#foreword)
  - [Installation](#installation)
    - [Ruby](#ruby)
    - [Rails](#rails)
  - [Getting Started](#getting-started)
    - [Preventing Output](#preventing-output)
    - [Rake Tasks](#rake-tasks)
    - [Pinging Search Engines](#pinging-search-engines)
    - [Crontab](#crontab)
    - [Robots.txt](#robotstxt)
    - [Ruby Modules](#ruby-modules)
    - [Deployments & Capistrano](#deployments--capistrano)
    - [Sitemaps with no Index File](#sitemaps-with-no-index-file)
    - [Upload Sitemaps to a Remote Host using Adapters](#upload-sitemaps-to-a-remote-host-using-adapters)
      - [Supported Adapters](#supported-adapters)
        - [`SitemapGenerator::FileAdapter`](#sitemapgeneratorfileadapter)
        - [`SitemapGenerator::FogAdapter`](#sitemapgeneratorfogadapter)
        - [`SitemapGenerator::S3Adapter`](#sitemapgenerators3adapter)
        - [`SitemapGenerator::AwsSdkAdapter`](#sitemapgeneratorawssdkadapter)
        - [`SitemapGenerator::WaveAdapter`](#sitemapgeneratorwaveadapter)
        - [`SitemapGenerator::GoogleStorageAdapter`](#sitemapgeneratorgooglestorageadapter)
      - [An Example of Using an Adapter](#an-example-of-using-an-adapter)
    - [Generating Multiple Sitemaps](#generating-multiple-sitemaps)
  - [Sitemap Configuration](#sitemap-configuration)
    - [A Simple Example](#a-simple-example)
    - [Adding Links](#adding-links)
    - [Supported Options to `add`](#supported-options-to-add)
    - [Adding Links to the Sitemap Index](#adding-links-to-the-sitemap-index)
    - [Accessing the LinkSet instance](#accessing-the-linkset-instance)
    - [Speeding Things Up](#speeding-things-up)
  - [Customizing your Sitemaps](#customizing-your-sitemaps)
    - [Sitemap Options](#sitemap-options)
  - [Sitemap Groups](#sitemap-groups)
    - [A Groups Example](#a-groups-example)
    - [Using `group` without a block](#using-group-without-a-block)
  - [Sitemap Extensions](#sitemap-extensions)
    - [News Sitemaps](#news-sitemaps)
      - [Example](#example)
      - [Supported options](#supported-options)
    - [Image Sitemaps](#image-sitemaps)
      - [Example](#example-1)
      - [Supported options](#supported-options-1)
    - [Video Sitemaps](#video-sitemaps)
      - [Example](#example-2)
      - [Supported options](#supported-options-2)
    - [PageMap Sitemaps](#pagemap-sitemaps)
      - [Supported options](#supported-options-3)
      - [Example:](#example-3)
    - [Alternate Links](#alternate-links)
      - [Example](#example-4)
      - [Supported options](#supported-options-4)
      - [Alternates Example](#alternates-example)
    - [Mobile Sitemaps](#mobile-sitemaps)
      - [Example](#example-5)
      - [Supported options](#supported-options-5)
  - [Compatibility](#compatibility)
  - [Licence](#licence)

## Contribute

Does your website use SitemapGenerator to generate Sitemaps?  Where would you be without Sitemaps?  Probably still knocking rocks together.  Consider donating to the project to keep it up-to-date and open source.

<a href='http://www.pledgie.com/campaigns/15267'><img alt='Click here to lend your support to: SitemapGenerator and make a donation at www.pledgie.com !' src='http://pledgie.com/campaigns/15267.png?skin_name=chrome' border='0' /></a>


## Foreword

Adam Salter first created SitemapGenerator while we were working together in Sydney, Australia.  Unfortunately, he passed away in 2009.  Since then I have taken over development of SitemapGenerator.

Those who knew him know what an amazing guy he was, and what an excellent Rails programmer he was.  His passing is a great loss to the Rails community.

The canonical repository is: [http://github.com/kjvarga/sitemap_generator][canonical_repo]


## Installation

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

SitemapGenerator works with all versions of Rails and has been tested in Rails 2, 3 and 4.

Add the gem to your `Gemfile`:

```ruby
gem 'sitemap_generator'
```

Alternatively, if you are not using a `Gemfile` add the gem to your `config/application.rb` file config block:

```ruby
config.gem 'sitemap_generator'
```

Note: SitemapGenerator automatically loads its Rake tasks when used with Rails. You **do not need** to require the `sitemap_generator/tasks` file.

## Getting Started

### Preventing Output

To disable all non-essential output you can pass the `-s` option to Rake, for example `rake -s sitemap:refresh`, or set the environment variable `VERBOSE=false` when calling as a Ruby script.

To disable output in-code use the following:

```ruby
SitemapGenerator.verbose = false
```

### Rake Tasks

* `rake sitemap:install` will create a `config/sitemap.rb` file which is your sitemap configuration
  and contains everything needed to build your sitemap.  See
  [**Sitemap Configuration**](#sitemap-configuration) below for more information about how to
  define your sitemap.

* `rake sitemap:refresh` will create or rebuild your sitemap files as needed.  Sitemaps are
  generated into the `public/` folder and by default are named `sitemap.xml.gz`, `sitemap1.xml.gz`,
  `sitemap2.xml.gz`, etc.  As you can see, they are automatically GZip compressed for you.  In this case,
  `sitemap.xml.gz` is your sitemap "index" file.

  `rake sitemap:refresh` will output information about each sitemap that is written including its
  location, how many links it contains, and the size of the file.

### Pinging Search Engines

Using `rake sitemap:refresh` will notify Google to let them know that a new sitemap
is available.  To generate new sitemaps without notifying search engines, use `rake sitemap:refresh:no_ping`.

If you want to customize the hash of search engines you can access it at:

```ruby
SitemapGenerator::Sitemap.search_engines
```

Usually you would be adding a new search engine to ping.  In this case you can modify
the `search_engines` hash directly.  This ensures that when
`SitemapGenerator::Sitemap.ping_search_engines` is called, your new search engine will be included.

If you are calling `ping_search_engines` manually, then you can pass your new search engine
directly in the call, as in the following example:

```ruby
SitemapGenerator::Sitemap.ping_search_engines(newengine: 'http://newengine.com/ping?url=%s')
```

The key gives the name of the search engine, as a string or symbol, and the value is the full URL to ping, with a string interpolation that will be replaced by the CGI escaped sitemap index URL.  If you have any literal percent characters in your URL you need to escape them with `%%`.

If you are calling `SitemapGenerator::Sitemap.ping_search_engines` from outside of your sitemap config file, then you will need to set `SitemapGenerator::Sitemap.default_host` and any other options that you set in your sitemap config which affect the location of the sitemap index file.  For example:

```ruby
SitemapGenerator::Sitemap.default_host = 'http://example.com'
SitemapGenerator::Sitemap.ping_search_engines
```

Alternatively, you can pass in the full URL to your sitemap index, in which case we would have just the following:

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

If you need to include a module (e.g. a rails helper), you must include it in the sitemap interpreter
class.  The part of your sitemap configuration that defines your sitemaps is run within an instance
of the `SitemapGenerator::Interpreter`:

```ruby
SitemapGenerator::Interpreter.send :include, RoutingHelper
```

### Deployments & Capistrano

To include the capistrano tasks just add the following to your Capfile:

```ruby
require 'capistrano/sitemap_generator'
```

Configurable options:

```ruby
set :sitemap_roles, :web # default
```

Available capistrano tasks:

```ruby
sitemap:create   #Create sitemaps without pinging search engines
sitemap:refresh  #Create sitemaps and ping search engines
sitemap:clean    #Clean up sitemaps in the sitemap path
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

Sometimes it is desirable to host your sitemap files on a remote server, and point robots
and search engines to the remote files.  For example, if you are using a host like Heroku,
which doesn't allow writing to the local filesystem.  You still require *some* write access,
because the sitemap files need to be written out before uploading.  So generally a host will
give you write access to a temporary directory.  On Heroku this is `tmp/` within your application
directory.

#### Supported Adapters

##### `SitemapGenerator::FileAdapter`

  Standard adapter, writes out to a file.

##### `SitemapGenerator::FogAdapter`

  Uses `Fog::Storage` to upload to any service supported by Fog.

  You must `require 'fog'` in your sitemap config before using this adapter,
  or `require` another library that defines `Fog::Storage`.

##### `SitemapGenerator::S3Adapter`

  Uses `Fog::Storage` to upload to Amazon S3 storage.

  You must `require 'fog-aws'` in your sitemap config before using this adapter.

  An example of using this adapter in your sitemap configuration:

  ```ruby
  SitemapGenerator::Sitemap.adapter = SitemapGenerator::S3Adapter.new(options)
  ```

  Where `options` is a Hash with any of the following keys:
* `aws_access_key_id` [String] Your AWS access key id
* `aws_secret_access_key` [String] Your AWS secret access key
* `fog_provider` [String]
* `fog_directory` [String]
* `fog_region` [String]
* `fog_path_style` [String]
* `fog_storage_options` [Hash] Other options to pass to `Fog::Storage`
* `fog_public` [Boolean] Whether the file is publicly accessible

Alternatively you can use an environment variable to configure each option (except `fog_storage_options`).  The environment variables have the same
name but capitalized, e.g. `FOG_PATH_STYLE`.

##### `SitemapGenerator::AwsSdkAdapter`

  Uses `Aws::S3::Resource` to upload to Amazon S3 storage.  Includes automatic detection of your AWS
  credentials and region.

  You must `require 'aws-sdk-s3'` in your sitemap config before using this adapter,
  or `require` another library that defines `Aws::S3::Resource` and `Aws::Credentials`.

  An example of using this adapter in your sitemap configuration:

  ```ruby
  SitemapGenerator::Sitemap.adapter = SitemapGenerator::AwsSdkAdapter.new('s3_bucket',
    acl: 'public-read', # Optional. This is the default.
    cache_control: 'private, max-age=0, no-cache', # Optional. This is the default.
    access_key_id: 'AKIAI3SW5CRAZBL4WSTA',
    secret_access_key: 'asdfadsfdsafsadf',
    region: 'us-east-1',
    endpoint: 'https://sfo2.digitaloceanspaces.com'
  )
  ```

  Where the first argument is the S3 bucket name, and the rest are keyword argument options.  Options `:acl` and `:cache_control` configure access and caching of the uploaded files; all other options are passed directly to the AWS client.

  See [the `SitemapGenerator::AwsSdkAdapter` docs](https://github.com/kjvarga/sitemap_generator/blob/master/lib/sitemap_generator/adapters/aws_sdk_adapter.rb), and [https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/S3/Client.html#initialize-instance_method](https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/S3/Client.html#initialize-instance_method) for the full list of supported options.

##### `SitemapGenerator::WaveAdapter`

  Uses `CarrierWave::Uploader::Base` to upload to any service supported by CarrierWave, for example,
  Amazon S3, Rackspace Cloud Files, and MongoDB's GridF.

  You must `require 'carrierwave'` in your sitemap config before using this adapter,
  or `require` another library that defines `CarrierWave::Uploader::Base`.

  Some documentation exists [on the wiki page][remote_hosts].

##### `SitemapGenerator::GoogleStorageAdapter`

  Uses [`Google::Cloud::Storage`][google_cloud_storage_gem] to upload to Google Cloud storage.

  You must `require 'google/cloud/storage'` in your sitemap config before using this adapter.

  An example of using this adapter in your sitemap configuration with options:

  ```ruby
  SitemapGenerator::Sitemap.adapter = SitemapGenerator::GoogleStorageAdapter.new(
    acl: 'public', # Optional.  This is the default value.
    bucket: 'name_of_bucket'
    credentials: 'path/to/keyfile.json',
    project_id: 'google_account_project_id',
  )
  ```
  Also, inline with Google Authentication options, it can also pick credentials from environment variables. All [supported environment variables][google_cloud_storage_authentication] can be used, for example: `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_CREDENTIALS`.  An example of using this adapter with the environment variables is:

  ```ruby
  SitemapGenerator::Sitemap.adapter = SitemapGenerator::GoogleStorageAdapter.new(
    bucket: 'name_of_bucket'
  )
  ```

  All options other than the `:bucket` and `:acl` options are passed to the `Google::Cloud::Storage.new` initializer giving you maximum configurability.  See the [Google Cloud Storage initializer][google_cloud_storage_initializer] for supported options.

#### An Example of Using an Adapter

1. Please see [this wiki page][remote_hosts] for more information about setting up SitemapGenerator to upload to a
   remote host.

2. This example uses the CarrierWave adapter.  It shows some common settings that are used when the hostname hosting
   the sitemaps differs from the hostname of the sitemap links.

     ```ruby
     # Your website's host name
     SitemapGenerator::Sitemap.default_host = "http://www.example.com"

     # The remote host where your sitemaps will be hosted
     SitemapGenerator::Sitemap.sitemaps_host = "http://s3.amazonaws.com/sitemap-generator/"

     # The directory to write sitemaps to locally
     SitemapGenerator::Sitemap.public_path = 'tmp/'

     # Set this to a directory/path if you don't want to upload to the root of your `sitemaps_host`
     SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'

     # The adapter to perform the upload of sitemap files.
     SitemapGenerator::Sitemap.adapter = SitemapGenerator::WaveAdapter.new
     ```

3. Update your `robots.txt` file to point robots to the remote sitemap index file, e.g:

    ```
    Sitemap: http://s3.amazonaws.com/sitemap-generator/sitemaps/sitemap.xml.gz
    ```

    You generate your sitemaps as usual using `rake sitemap:refresh`.

    Note that SitemapGenerator will automatically turn off `include_index` in this case because
    the `sitemaps_host` does not match the `default_host`.  The link to the sitemap index file
    that would otherwise be included would point to a different host than the rest of the links
    in the sitemap, something that the sitemap rules forbid.

4. Verify to Google that you own the S3 url

    In order for Google to use your sitemap, you need to prove you own the S3 bucket through [google webmaster tools](https://www.google.com/webmasters/tools/home?hl=en).  In the example above, you would add the site `http://s3.amazonaws.com/sitemap-generator/sitemaps`.  Once you have verified you own the directory, then add your
    sitemap index to the list of sitemaps for the site.

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

Weird!  The sitemap has two links, even though we only added one!  This is because SitemapGenerator adds the root URL `/` for you by default.  You can change the default behaviour by setting the `include_root` or `include_index` option.

Now let's take a look at the file that was created.  After uncompressing and XML-tidying the contents we have:


* `public/sitemap.xml.gz`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1" xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:video="http://www.google.com/schemas/sitemap-video/1.1" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
  <url>
    <loc>http://www.example.com/</loc>
    <lastmod>2011-05-21T00:03:38+00:00</lastmod>
    <changefreq>weekly</changefreq>
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
<sitemapindex xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/siteindex.xsd">
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

* `:create_index` - Supported values: `true`, `false`, `:auto`.  Default: `:auto`. Whether to create a sitemap index file.  If `true` an index file is always created regardless of how many sitemap files are generated.  If `false` an index file is never created.  If `:auto` an index file is created only when you have more than one sitemap file (i.e. you have added more than 50,000 - `SitemapGenerator::MAX_SITEMAP_LINKS` - links).

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

* `:max_sitemap_links` - Integer. The maximum number of links to put in each sitemap.  Default is `SitemapGenerator::MAX_SITEMAPS_LINKS`, or 50,000.

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

### Using `group` without a block

In some circumstances you may need to conditionally add records to a group or perform some other more complicated logic.  In these cases you can instantiate a group instance, add links to it and finalize it manually.

When called with a block, any partial sitemaps are automatically written out for you when the block terminates.  Because this does not happen when instantiating manually, you must call `finalize!` on your group to ensure that it is written out and gets included in the sitemap index file.  Note that group sitemaps will still automatically be finalized (written out) as they become full; calling `finalize!` is to handle the case when a sitemap is not full.

An example:

```ruby
SitemapGenerator::Sitemap.verbose = true
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create do
  odds = group(:filename => :odds)
  evens = group(:filename => :evens)

  (1..20).each do |i|
    if (i % 2) == 0
      evens.add i.to_s
    else
      odds.add i.to_s
    end
  end

  odds.finalize!
  evens.finalize!
end
```

And the output from running the above:

```
In '/Users/kvarga/Projects/sitemap_generator-test/public/':
+ odds.xml.gz                                             10 links /  371 Bytes
+ evens.xml.gz                                            10 links /  371 Bytes
+ sitemap.xml.gz                                        2 sitemaps /  240 Bytes
Sitemap stats: 20 links / 2 sitemaps / 0m00s
```

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

#### Alternates Example

```ruby
SitemapGenerator::Sitemap.default_host = "http://www.example.com"
SitemapGenerator::Sitemap.create do
 add('/index.html', :alternates => [
        {
            :href => 'http://www.example.de/index.html',
            :lang => 'de',
            :nofollow => true
        },
        {
            :href => 'http://www.example.es/index.html',
            :lang => 'es',
            :nofollow => true
        }
    ])
end
```

### Mobile Sitemaps

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

## Compatibility

Compatible with all versions of Rails and Ruby.  Tested up to Ruby 3.1 and Rails 7.0.
Ruby 1.9.3 support was dropped in Version 6.0.0.

## Licence

Released under the MIT License.  See the (MIT-LICENSE)[MIT-LICENSE] file.

MIT. See the LICENSE.md file.

Copyright (c) Karl Varga released under the MIT license

[canonical_repo]:http://github.com/kjvarga/sitemap_generator
[sitemap_images]:http://www.google.com/support/webmasters/bin/answer.py?answer=178636
[sitemap_video]:https://support.google.com/webmasters/answer/80471?hl=en&ref_topic=4581190
[sitemap_news]:https://support.google.com/news/publisher/topic/2527688?hl=en&ref_topic=4359874
[sitemap_mobile]:http://support.google.com/webmasters/bin/answer.py?hl=en&answer=34648
[sitemap_pagemap]:https://developers.google.com/custom-search/docs/structured_data#addtositemap
[sitemap_protocol]:http://www.sitemaps.org/protocol.html
[video_tags]:http://www.google.com/support/webmasters/bin/answer.py?hl=en&answer=80472#4
[image_tags]:http://www.google.com/support/webmasters/bin/answer.py?hl=en&answer=178636
[news_tags]:http://www.google.com/support/news_pub/bin/answer.py?answer=74288
[remote_hosts]:https://github.com/kjvarga/sitemap_generator/wiki/Generate-Sitemaps-on-read-only-filesystems-like-Heroku
[alternate_links]:http://support.google.com/webmasters/bin/answer.py?hl=en&answer=2620865
[using_pagemaps]:https://developers.google.com/custom-search/docs/structured_data#pagemaps
[iso_4217]:http://en.wikipedia.org/wiki/ISO_4217
[media]:https://developers.google.com/webmasters/smartphone-sites/details
[expires]:https://support.google.com/customsearch/answer/2631051?hl=en
[google_cloud_storage_gem]:https://rubygems.org/gems/google-cloud-storage
[google_cloud_storage_authentication]:https://googleapis.dev/ruby/google-cloud-storage/latest/file.AUTHENTICATION.html
[google_cloud_storage_initializer]:https://github.com/googleapis/google-cloud-ruby/blob/master/google-cloud-storage/lib/google/cloud/storage.rb
