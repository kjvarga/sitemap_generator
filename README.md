SitemapGenerator
================

SitemapGenerator generates Sitemaps for your Rails application.  The Sitemaps adhere to the [Sitemap 0.9 protocol][sitemap_protocol] specification.  You specify the contents of your Sitemap using a configuration file, à la Rails Routes.  A set of rake tasks is included to help you manage your Sitemaps.

Features
-------

- Supports [News sitemaps][sitemap_news], [Video sitemaps][sitemap_video], [Image sitemaps][sitemap_images], and [Geo sitemaps][sitemap_geo]
- Supports read-only filesystems like Heroku via uploading to a remote host like Amazon S3
- Compatible with Rails 2 & 3
- Adheres to the [Sitemap 0.9 protocol][sitemap_protocol]
- Handles millions of links
- Automatically compresses your sitemaps
- Notifies search engines (Google, Bing, Ask, SitemapWriter) of new sitemaps
- Ensures your old sitemaps stay in place if the new sitemap fails to generate
- Gives you complete control over your sitemaps and their content

Contribute
-------

Does your website use SitemapGenerator to generate Sitemaps?  Where would you be without Sitemaps?  Probably still knocking rocks together.  Consider donating to the project to keep it up-to-date and open source.

<a href='http://www.pledgie.com/campaigns/15267'><img alt='Click here to lend your support to: SitemapGenerator and make a donation at www.pledgie.com !' src='http://pledgie.com/campaigns/15267.png?skin_name=chrome' border='0' /></a>

Changelog
-------

- v2.1.7: Improve format of float priorities; Remove Yahoo from ping - the Yahoo
          service has been shut down.
- v2.1.6: Fix the lastmod value on sitemap file links
- v2.1.5: Fix verbose setting in the rake tasks; should default to true
- v2.1.4: Allow special characters in URLs (don't use URI.join to construct URLs)
- v2.1.3: Fix calling create with both `filename` and `sitemaps_namer` options
- v2.1.2: Support multiple videos per url using the new `videos` option to `add()`.
- v2.1.1: Support calling `create()` multiple times in a sitemap config.  Support host names with path segments so you can use a `default_host` like `'http://mysite.com/subdirectory/'`.  Turn off `include_index` when the `sitemaps_host` differs from `default_host`.  Add docs about how to upload to remote hosts.
- v2.1.0: [News sitemap][sitemap_news] support
- v2.0.1.pre2: Fix uploading to the (bucket) root on a remote server
- v2.0.1.pre1: Support read-only filesystems like Heroku by supporting uploading to remote host
- v2.0.1: Minor improvements to verbose handling; prevent missing Timeout issue
- **v2.0.0: Introducing a new simpler API, Sitemap Groups, Sitemap Namers and more!**
- v1.5.0: New options `include_root`, `include_index`; Major testing & refactoring
- v1.4.0: [Geo sitemap][geo_tags] support, multiple sitemap support via CONFIG_FILE rake option
- v1.3.0: Support setting the sitemaps path
- v1.2.0: Verified working with Rails 3 stable release
- v1.1.0: [Video sitemap][sitemap_video] support
- v0.2.6: [Image Sitemap][sitemap_images] support
- v0.2.5: Rails 3 prerelease support (beta)

Foreword
-------

Adam Salter first created SitemapGenerator while we were working together in Sydney, Australia.  Unfortunately, he passed away in 2009.  Since then I have taken over development of SitemapGenerator.

Those who knew him know what an amazing guy he was, and what an excellent Rails programmer he was.  His passing is a great loss to the Rails community.

The canonical repository is now: [http://github.com/kjvarga/sitemap_generator][canonical_repo]

Install for Rails
=======

Rails 3
-------

Add the gem to your `Gemspec`:

    gem 'sitemap_generator'

Then run `bundle`.

Rails 2 Gem
--------

1.  Follow the Rails 3 install if you are using a `Gemfile`.

    If you are not using a `Gemfile` add the gem to your `config/environment.rb` configuration block with:

        config.gem 'sitemap_generator'

    Then run `rake gems:install`.

2. Include the gem's Rake tasks in your `Rakefile`:

        begin
          require 'sitemap_generator/tasks'
        rescue Exception => e
          puts "Warning, couldn't load gem tasks: #{e.message}! Skipping..."
        end

Rails 2 Plugin
----------

Run `script/plugin install git://github.com/kjvarga/sitemap_generator.git` from your application's root directory.

Getting Started
======

Rake Tasks
-----

Run `rake sitemap:install` to create a `config/sitemap.rb` file which is your sitemap configuration and contains everything needed to build your sitemap.  See **Sitemap Configuration** below for more information about how to define your sitemap.

Run `rake sitemap:refresh` as needed to create or rebuild your sitemap files.  Sitemaps are generated into the `public/` folder and by default are named `sitemap_index.xml.gz`, `sitemap1.xml.gz`, `sitemap2.xml.gz`, etc.  As you can see they are automatically gzip compressed for you.

`rake sitemap:refresh` will output information about each sitemap that is written including its location, how many links it contains and the size of the file.

**To disable all non-essential output from `rake` run the tasks passing a `-s` option.**  For example: `rake -s sitemap:refresh`.

Search Engine Notification
-----

Using `rake sitemap:refresh` will notify major search engines to let them know that a new sitemap is available (Google, Bing, Ask, SitemapWriter).  To generate new sitemaps without notifying search engines (for example when running in a local environment) use `rake sitemap:refresh:no_ping`.

Crontab
-----

To keep your sitemaps up-to-date, setup a cron job.  Make sure to pass the `-s` option to silence rake.  That way you will only get email if the sitemap build fails.

If you're using Whenever, your schedule would look something like this:

    # config/schedule.rb
    every 1.day, :at => '5:00 am' do
      rake "-s sitemap:refresh"
    end

Robots.txt
----------

You should add the URL of the sitemap index file to `public/robots.txt` to help search engines find your sitemaps.  The URL should be the complete URL to the sitemap index.  For example:

    Sitemap: http://www.example.com/sitemap_index.xml.gz

Deployments & Capistrano
----------

To ensure that your application's sitemaps are available after a deployment you can do one of the following:

1.  **Generate sitemaps into a directory which is shared by all deployments.**

    You can set your sitemaps path to your shared directory using the `sitemaps_path` option.  For example if we have a directory `public/shared/` that is shared by all deployments we can have our sitemaps generated into that directory by setting:

        SitemapGenerator::Sitemap.sitemaps_path = 'shared/'

2.  **Copy the sitemaps from the previous deploy over to the new deploy:**

    (You will need to customize the task if you are using custom sitemap filenames or locations.)

        after "deploy:update_code", "deploy:copy_old_sitemap"
        namespace :deploy do
          task :copy_old_sitemap do
            run "if [ -e #{previous_release}/public/sitemap_index.xml.gz ]; then cp #{previous_release}/public/sitemap* #{current_release}/public/; fi"
          end
        end


3.  **Regenerate your sitemaps after each deployment:**

        after "deploy", "refresh_sitemaps"
        task :refresh_sitemaps do
          run "cd #{latest_release} && RAILS_ENV=#{rails_env} rake sitemap:refresh"
        end

Upload Sitemaps to a Remote Host
----------

Sometimes it is desirable to host your sitemap files on a remote server and point robots
and search engines to the remote files.  For example if you are using a host like Heroku
which doesn't allow writing to the local filesystem.  You still require *some* write access
because the sitemap files need to be written out before uploading, so generally a host will
give you write access to a temporary directory.  On Heroku this is `tmp/` in your application
directory.

Sitemap Generator uses CarrierWave to support uploading to Amazon S3 store, Rackspace Cloud Files store, and MongoDB's GridF - whatever CarrierWave supports.

1. Please see [this wiki page][remote_hosts] for more information about setting up CarrierWave, SitemapGenerator and Rails.

2. Once you have CarrierWave setup and configured all you need to do is set some options in your sitemap config, such as:

   * `default_host` - your website host name
   * `sitemaps_host` - the remote host where your sitemaps will be hosted
   * `public_path` - the directory to write sitemaps to locally e.g. `tmp/`
   * `sitemaps_path` - set to a directory/path if you don't want to upload to the root of your `sitemaps_host`
   * `adapter` - instance of `SitemapGenerator::WaveAdapter`

   For Example:

        SitemapGenerator::Sitemap.default_host = "http://www.example.com"
        SitemapGenerator::Sitemap.sitemaps_host = "http://s3.amazonaws.com/sitemap-generator/"
        SitemapGenerator::Sitemap.public_path = 'tmp/'
        SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'
        SitemapGenerator::Sitemap.adapter = SitemapGenerator::WaveAdapter.new

3. Update your `robots.txt` file to point robots to the remote sitemap index file, e.g:

        Sitemap: http://s3.amazonaws.com/sitemap-generator/sitemaps/sitemap_index.xml.gz

You generate your sitemaps as usual using `rake sitemap:refresh`.

Note that SitemapGenerator will automatically turn off `include_index` in this case because
the `sitemaps_host` does not match the `default_host`.  The link to the sitemap index file
that would otherwise be included would point to a different host than the rest of the links
in the sitemap, something that the sitemap rules forbid.

Generating Multiple Sitemaps
----------

Each call to `create` creates a new sitemap index and associated sitemaps.  You can call `create` as many times as you want within your sitemap configuration.

You must remember to use a different filename or location for each set of sitemaps, otherwise they will
overwrite each other.  You can use the `filename`, `sitemaps_namer` and `sitemaps_path` options for this.

In the following example we generate three sitemaps each in its own subdirectory:

    %w(google bing apple).each do |subdomain|
      SitemapGenerator::Sitemap.default_host = "https://#{subdomain}.mysite.com"
      SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/#{subdomain}"
      SitemapGenerator::Sitemap.create do
        add '/home'
      end
    end

Outputs:

    + sitemaps/google/sitemap1.xml.gz             2 links /  822 Bytes /  328 Bytes gzipped
    + sitemaps/google/sitemap_index.xml.gz          1 sitemaps /  389 Bytes /  217 Bytes gzipped
    Sitemap stats: 2 links / 1 sitemaps / 0m00s
    + sitemaps/bing/sitemap1.xml.gz             2 links /  820 Bytes /  330 Bytes gzipped
    + sitemaps/bing/sitemap_index.xml.gz          1 sitemaps /  388 Bytes /  217 Bytes gzipped
    Sitemap stats: 2 links / 1 sitemaps / 0m00s
    + sitemaps/apple/sitemap1.xml.gz             2 links /  820 Bytes /  330 Bytes gzipped
    + sitemaps/apple/sitemap_index.xml.gz          1 sitemaps /  388 Bytes /  214 Bytes gzipped
    Sitemap stats: 2 links / 1 sitemaps / 0m00s

If you don't want to have to generate all the sitemaps at once, or you want to refresh some more often than others, you can split them up into their own configuration files.  Using the above example we would have:

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

To generate each one specify the configuration file to run by passing the `CONFIG_FILE` option to `rake sitemap:refresh`, e.g.:

    rake sitemap:refresh CONFIG_FILE="config/google_sitemap.rb"
    rake sitemap:refresh CONFIG_FILE="config/apple_sitemap.rb"
    rake sitemap:refresh CONFIG_FILE="config/bing_sitemap.rb"

Sitemap Configuration
======

A sitemap configuration file contains all the information needed to generate your sitemaps.  By default SitemapGenerator looks for a configuration file in  `config/sitemap.rb` - relative to your application root or the current working directory.  (Run `rake sitemap:install` to have this file generated for you if you have not done so already.)

If you want to use a non-standard configuration file, or have multiple configuration files, you can specify which one to run by passing the `CONFIG_FILE` option like so:

    rake sitemap:refresh CONFIG_FILE="config/geo_sitemap.rb"

A Simple Example
-------

So what does a sitemap configuration look like?  Let's take a look at a simple example:

    SitemapGenerator::Sitemap.default_host = "http://www.example.com"
    SitemapGenerator::Sitemap.create do
      add '/welcome'
    end

A few things to note:

* `SitemapGenerator::Sitemap` is a lazy-initialized sitemap object provided for your convenience.
* Every sitemap must set `default_host`.  This is the hostname that is used when building links to add to the sitemap.
* The `create` method takes a block with calls to `add` to add links to the sitemap.
* The sitemaps are written to the `public/` directory, which is the default location.  You can specify a custom location using the `public_path` or `sitemaps_path` option.

Now let's see what is output when we run this configuration with `rake sitemap:refresh:no_ping`:

    + sitemap1.xml.gz                   3 links /  923 Bytes /  329 Bytes gzipped
    + sitemap_index.xml.gz           1 sitemaps /  364 Bytes /  199 Bytes gzipped
    Sitemap stats: 3 links / 1 sitemaps / 0m00s

Weird!  The sitemap has three links, even though only added one!  This is because SitemapGenerator adds the root URL `/` and the URL of the sitemap index file to your sitemap by default.  (You can change the default behaviour by setting the `include_root` or `include_index` option.)

Now let's take a look at the files that were created.  After uncompressing and XML-tidying the contents we have:

* `public/sitemap_index.xml.gz`

        <?xml version="1.0" encoding="UTF-8"?>
        <sitemapindex xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/siteindex.xsd">
          <sitemap>
            <loc>http://www.example.com/sitemap1.xml.gz</loc>
          </sitemap>
        </sitemapindex>

* `public/sitemap1.xml.gz`

        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1" xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:video="http://www.google.com/schemas/sitemap-video/1.1" xmlns:geo="http://www.google.com/geo/schemas/sitemap/1.0" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
          <url>
            <loc>http://www.example.com/</loc>
            <lastmod>2011-05-21T00:03:38+00:00</lastmod>
            <changefreq>always</changefreq>
            <priority>1.0</priority>
          </url>
          <url>
            <loc>http://www.example.com/sitemap_index.xml.gz</loc>
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

The sitemaps conform to the [Sitemap 0.9 protocol][sitemap_protocol].  Notice the values for `priority` and `changefreq` on the root and sitemap index links, the ones that were added for us?  The values tell us that these links are the highest priority and should be checked regularly because they are constantly changing.  You can specify your own values for these options in your call to `add`.

Adding Links
----------

You call `add` in the block passed to `create` to add a **path** to your sitemap.  `add` takes a string path and optional hash of options, generates the URL and adds it to the sitemap.  You only need to pass a **path** because the URL will be built for us using the `default_host` we specified.  However, if we want to use a different host for a particular link, we can pass the `:host` option to `add`.

Let's see another example:

    SitemapGenerator::Sitemap.default_host = "http://www.example.com"
    SitemapGenerator::Sitemap.create do
      add '/contact_us'
      Content.find_each do |content|
        add content_path(content), :lastmod => content.updated_at
      end
    end

In this example first we add the `/contact_us` page to the sitemap and then we iterate through the Content model's records adding each one to the sitemap using the `content_path` helper method to generate the path for each record.

The **Rails URL/path helper methods are automatically made available** to us in the `create` block.  This keeps the logic for building our paths out of the sitemap config and in the Rails application where it should be.  You use those methods just like you would in your application's view files.

In the example about we pass a `lastmod` (last modified) option with the value of the record's `updated_at` attribute so that search engines know to only re-index the page when the record changes.

Looking at the output from running this sitemap, we see that we have a few more links than before:

    + sitemap1.xml.gz                  12 links /     2.3 KB /  365 Bytes gzipped
    + sitemap_index.xml.gz           1 sitemaps /  364 Bytes /  199 Bytes gzipped
    Sitemap stats: 12 links / 1 sitemaps / 0m00s

From this example we can see that:

* The `create` block can contain Ruby code
* The Rails URL/path helper methods are made available to us, and
* The basic syntax for adding paths to the sitemap using `add`

You can read more about `add` in the [XML Specification](http://sitemaps.org/protocol.php#xmlTagDefinitions).

### Supported Options to `add`

* `changefreq` - Default: `'weekly'` (String).

  Indicates how often the content of the page changes.  One of `'always'`, `'hourly'`, `'daily'`, `'weekly'`, `'monthly'`, `'yearly'` or `'never'`.  Example:

        add '/contact_us', :changefreq => 'monthly'

* `lastmod` - Default: `Time.now` (Time).

  The date and time of last modification.  Example:

        add content_path(content), :lastmod => content.updated_at

* `host` - Default: `default_host` (String).

  Host to use when building the URL.  Example:

        add '/login', :host => 'https://securehost.com/login'

* `priority` - Default: `0.5` (Float).

  The priority of the URL relative to other URLs on a scale from 0 to 1.   Example:

        add '/about', :priority => 0.75


Speeding Things Up
----------

For large ActiveRecord collections with thousands of records it is advisable to iterate through them in batches to avoid loading all records into memory at once.  For this reason in the example above we use `Content.find_each` which is a batched iterator available since Rails 2.3.2, rather than `Content.all`.

Customizing your Sitemaps
=======

SitemapGenerator supports a number of options which allow you to control every aspect of your sitemap generation.  How they are named, where they are stored, the contents of the links and the location that the sitemaps will be hosted from can all be set.

The options can be set in the following ways.

On `SitemapGenerator::Sitemap`:

    SitemapGenerator::Sitemap.default_host = 'http://example.com'
    SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'

These options will apply to all sitemaps.  This is how you set most options.

Passed as options in the call to `create`:

    SitemapGenerator::Sitemap.create(
        :default_host => 'http://example.com',
        :sitemaps_path => 'sitemaps/') do
      add '/home'
    end

This is useful if you are setting a lot of options.

Finally, passed as options in a call to `group`:

    SitemapGenerator::Sitemap.create do
      group(:default_host => 'http://example.com',
            :sitemaps_path => 'sitemaps/') do
        add '/home'
      end
    end

The options passed to `group` only apply to the links and sitemaps generated in the group.  Sitemap Groups are useful to group links into specific sitemaps, or to set options that you only want to apply to the links in that group.

Sitemap Options
-------

The following options are supported:

* `default_host` - String.  Required.  **Host including protocol** to use when building a link to add to your sitemap.  For example `http://example.com`.  Calling `add '/home'` would then generate the URL `http://example.com/home` and add that to the sitemap.  You can pass a `:host` option in your call to `add` to override this value on a per-link basis.  For example calling `add '/home', :host => 'https://example.com'` would generate the URL `https://example.com/home`, for that link only.

* `filename` - Symbol.  The **base name for the files** that will be generated.  The default value is `:sitemap`.  This yields sitemaps with names like `sitemap1.xml.gz`, `sitemap2.xml.gz`, `sitemap3.xml.gz` etc, and a sitemap index named `sitemap_index.xml.gz`.  If we now set the value to `:geo` the sitemaps would be named `geo1.xml.gz`, `geo2.xml.gz`, `geo3.xml.gz` etc, and the sitemap index would be named `geo_index.xml.gz`.

* `include_index` - Boolean.  Whether to **add a link to the sitemap index** to the current sitemap.  This points search engines to your Sitemap Index to include it in the indexing of your site.  Default is `true`.  Turned off when `sitemaps_host` is set or within a `group()` block.

* `include_root` - Boolean.  Whether to **add the root** url i.e. '/' to the current sitemap.  Default is `true`.  Turned off within a `group()` block.

* `public_path` - String.  A **full or relative path** to the `public` directory or the directory you want to write sitemaps into.  Defaults to `public/` under your application root or relative to the current working directory.

* `sitemaps_host` - String.  **Host including protocol** to use when generating a link to a sitemap file i.e. the hostname of the server where the sitemaps are hosted.  The value will differ from the hostname in your sitemap links.  For example: `'http://amazon.aws.com/'`.  Note that `include_index` is
automatically turned off when the `sitemaps_host` does not match `default_host`.
Because the link to the sitemap index file that would otherwise be added would point to a
different host than the rest of the links in the sitemap.  Something that the sitemap rules forbid.

* `sitemaps_namer` - A `SitemapGenerator::SitemapNamer` instance **for generating sitemap names**.  You can read about Sitemap Namers by reading the API docs.  Sitemap Namers don't apply to the sitemap index.  You can only modify the name of the index file using the `filename` option.  Sitemap Namers allow you to set the name, extension and number sequence for sitemap files.

* `sitemaps_path` - String. A **relative path** giving a directory under your `public_path` at which to write sitemaps.  The difference between the two options is that the `sitemaps_path` is used when generating a link to a sitemap file.  For example, if we set `SitemapGenerator::Sitemap.sitemaps_path = 'en/'` and use the default `public_path` sitemaps will be written to `public/en/`.  And when the sitemap index is added to our sitemap it would have a URL like `http://example.com/en/sitemap_index.xml.gz`.

* `verbose` - Boolean.  Whether to **output a sitemap summary** describing the sitemap files and giving statistics about your sitemap.  Default is `false`.  When using the Rake tasks `verbose` will be `true` unless you pass the `-s` option.

* `adapter` - Instance.  The default adapter is a `SitemapGenerator::FileAdapter`
  which simply writes files to the filesystem.  You can use a `SitemapGenerator::WaveAdapter`
  for uploading sitemaps to remote servers - useful for read-only hosts such as Heroku.  Or
  you can provide an instance of your own class to provide custom behavior.  Your class must
  define a write method which takes a `SitemapGenerator::Location` and raw XML data.

Sitemap Groups
=======

Sitemap Groups is a powerful feature that is also very simple to use.

* All options are supported except for `public_path`.  You cannot change the public path.
* Groups inherit the options set on the default sitemap.
* `include_index` and `include_root` are `false` by default in a group.
* The sitemap index file is shared by all groups.
* Groups can handle any number of links.
* Group sitemaps are finalized (written out) as they get full and at the end of each group.

A Groups Example
----------------

When you create a new group you pass options which will apply only to that group.  You pass a block to `group`.  Inside your block you call `add` to add links to the group.

Let's see an example that demonstrates a few interesting things about groups:

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

And the output from running the above:

    + en/english1.xml.gz                1 links /  612 Bytes /  296 Bytes gzipped
    + fr/french1.xml.gz                 1 links /  614 Bytes /  298 Bytes gzipped
    + sitemap1.xml.gz                   3 links /  919 Bytes /  328 Bytes gzipped
    + sitemap_index.xml.gz           3 sitemaps /  505 Bytes /  221 Bytes gzipped
    Sitemap stats: 5 links / 3 sitemaps / 0m00s

So we have two sitemaps with one link each and one sitemap with three links.  The sitemaps from the groups are easy to spot by their filenames.  They are `english1.xml.gz` and `french1.xml.gz`.  They contain only one link each because **`include_index` and `include_root` are set to `false` by default** in a group.

On the other hand, the default sitemap which we added `/rss` to has three links.  The sitemap index and root url were added to it when we added `/rss`.  If we hadn't added that link `sitemap1.xml.gz` would not have been created.  So **when we are using groups, the default sitemap will only be created if we add links to it**.

**The sitemap index file is shared by all groups**.  You can change its filename by setting `SitemapGenerator::Sitemap.filename` or by passing the `:filename` option to `create`.

The options you use when creating your groups will determine which and how many sitemaps are created.  Groups will inherit the default sitemap when possible, and will continue the normal series.  However a group will often specify an option which requires the links in that group to be in their own files.  In this case, if the default sitemap were being used it would be finalized before starting the next sitemap in the series.

If you have changed your sitemaps physical location in a group, then the default sitemap will not be used and it will be unaffected by the group.  **Group sitemaps are finalized as they get full and at the end of each group.**

Sitemap Extensions
===========

News Sitemaps
-----------

A news item can be added to a sitemap URL by passing a `:news` hash to `add`.  The hash must  contain tags defined by the [News Sitemap][news_tags] specification.  For example:

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

Supported news options include:

* `publication_name`
* `publication_language`
* `publication_date`
* `genres`
* `access`
* `title`
* `keywords`
* `stock_tickers`

Image Sitemaps
-----------

Images can be added to a sitemap URL by passing an `:images` array to `add`.  Each item in the array must be a Hash containing tags defined by the [Image Sitemap][image_tags] specification.  For example:

    SitemapGenerator::Sitemap.create do
      add('/index.html', :images => [{
        :loc => 'http://www.example.com/image.png',
        :title => 'Image' }])
    end

Supported image options include:

* `loc` Required, location of the image
* `caption`
* `geo_location`
* `title`
* `license`

Video Sitemaps
-----------

A video can be added to a sitemap URL by passing a `:video` Hash to `add`.  The Hash can contain tags defined by the [Video Sitemap specification][video_tags].

To add more than one video to a url, pass an array of video hashes using the `:videos` option.

To associate more than one `tag` with a video, pass the tags as an array with the key `:tags`.

Example:

    add('/index.html', :video => {
      :thumbnail_loc => 'http://www.example.com/video1_thumbnail.png',
      :title => 'Title',
      :description => 'Description',
      :content_loc => 'http://www.example.com/cool_video.mpg',
      :tags => %w[one two three],
      :category => 'Category'
    })

Supported video options include:

* `thumbnail_loc` Required
* `title` Required
* `description` Required
* `content_loc` Depends.  At least one of `player_loc` or `content_loc` is required
* `player_loc` Depends. At least one of `player_loc` or `content_loc` is required
* `expiration_date` Recommended
* `duration` Recommended
* `rating`
* `view_count`
* `publication_date`
* `family_friendly`
* `tags` A list of tags if more than one tag.
* `tag` A single tag.  See `tags`
* `category`
* `gallery_loc`
* `uploader` (use `uploader_info` to set the info attribute)



Geo Sitemaps
-----------

Pages with geo data can be added by passing a `:geo` Hash to `add`.  The Hash only supports one tag of `:format`.  Google provides an [example of a geo sitemap link here][geo_tags].  Note that the sitemap does not actually contain your KML or GeoRSS.  It merely links to a page that has this content.

    add('/stores/1234.xml', :geo => { :format => 'kml' })

Supported geo options include:

* `format` Required, either 'kml' or 'georss'

Raison d'être
=======

Most of the Sitemap plugins out there seem to try to recreate the Sitemap links by iterating the Rails routes. In some cases this is possible, but for a great deal of cases it isn't.

a) There are probably quite a few routes in your routes file that don't need inclusion in the Sitemap. (AJAX routes I'm looking at you.)

and

b) How would you infer the correct series of links for the following route?

    map.zipcode 'location/:state/:city/:zipcode', :controller => 'zipcode', :action => 'index'

Don't tell me it's trivial, because it isn't. It just looks trivial.

So my idea is to have another file similar to 'routes.rb' called 'sitemap.rb', where you can define what goes into the Sitemap.

Here's my solution:

    Zipcode.find(:all, :include => :city).each do |z|
      add zipcode_path(:state => z.city.state, :city => z.city, :zipcode => z)
    end

Easy hey?

Compatibility
=======

Tested and working on:

- **Rails** 3.0.0, 3.0.7
- **Rails** 1.x - 2.3.8
- **Ruby** 1.8.6, 1.8.7, 1.8.7 Enterprise Edition, 1.9.1, 1.9.2

Known Bugs
========

- There's no check on the size of a URL which [isn't supposed to exceed 2,048 bytes][sitemaps_xml].
- Currently only supports one Sitemap Index file, which can contain 50,000 Sitemap files which can each contain 50,000 urls, so it _only_ supports up to 2,500,000,000 (2.5 billion) urls.

Wishlist & Coming Soon
========

- Rails framework agnosticism; support for other frameworks like Merb

Thanks (in no particular order)
========

- [Rodrigo Flores](https://github.com/rodrigoflores) for News sitemaps
- [Alex Soto](http://github.com/apsoto) for Video sitemaps
- [Alexadre Bini](http://github.com/alexandrebini) for Image sitemaps
- [Dan Pickett](http://github.com/dpickett)
- [Rob Biedenharn](http://github.com/rab)
- [Richie Vos](http://github.com/jerryvos)
- [Adrian Mugnolo](http://github.com/xymbol)
- [Jason Weathered](http://github.com/jasoncodes)
- [Andy Stewart](http://github.com/airblade)
- [Brian Armstrong](https://github.com/barmstrong) for Geo sitemaps

Copyright (c) 2009 Karl Varga released under the MIT license

[canonical_repo]:http://github.com/kjvarga/sitemap_generator
[enterprise_class]:https://twitter.com/dhh/status/1631034662 "I use enterprise in the same sense the Phusion guys do - i.e. Enterprise Ruby. Please don't look down on my use of the word 'enterprise' to represent being a cut above. It doesn't mean you ever have to work for a company the size of IBM. Or constantly fight inertia, writing crappy software, adhering to change management practices and spending hours in meetings... Not that there's anything wrong with that - Wait, what?"
[sitemaps_org]:http://www.sitemaps.org/protocol.php "http://www.sitemaps.org/protocol.php"
[sitemaps_xml]:http://www.sitemaps.org/protocol.php#xmlTagDefinitions "XML Tag Definitions"
[sitemap_generator_usage]:http://wiki.github.com/adamsalter/sitemap_generator/sitemapgenerator-usage "http://wiki.github.com/adamsalter/sitemap_generator/sitemapgenerator-usage"
[sitemap_images]:http://www.google.com/support/webmasters/bin/answer.py?answer=178636
[sitemap_video]:http://www.google.com/support/webmasters/bin/topic.py?topic=10079
[sitemap_news]:http://www.google.com/support/webmasters/bin/topic.py?hl=en&topic=10078
[sitemap_geo]:http://www.google.com/support/webmasters/bin/topic.py?hl=en&topic=14688
[sitemap_protocol]:http://sitemaps.org/protocol.php
[video_tags]:http://www.google.com/support/webmasters/bin/answer.py?hl=en&answer=80472#4
[image_tags]:http://www.google.com/support/webmasters/bin/answer.py?hl=en&answer=178636
[geo_tags]:http://www.google.com/support/webmasters/bin/answer.py?hl=en&answer=94555
[news_tags]:http://www.google.com/support/news_pub/bin/answer.py?answer=74288
[remote_hosts]:https://github.com/kjvarga/sitemap_generator/wiki/Generate-Sitemaps-on-read-only-filesystems-like-Heroku
