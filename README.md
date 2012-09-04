## JobCo

JobCo is a Resque distribution.

It provides an easy to use Resque package, that include plugins (rails loader, status), CLI tools () and some integration with the `resque-scheduler` plugin, into one easy to use package.

JobCo is open source software, licensed under the terms of the 3-clause BSD license, with an additional disclaimer. See LICENSE file for details.

## This is the edge

**Warning**

jobco/master (0.2+) depends on resque edge, for which the next release should be resque 2.0
in addition, it uses features and patches not yet merged in defunkt/resque
to get it jobco running, you will need to point it at mrzor/resque, branch `master_and_patches`

jobco/0.1.x branch still lives, and supports an older resque stack (1.x). you might want to check that
one out - at your own risk.

## What do I get ?

For your job running projects, rolling out with JobCo means :

* A `Jobfile`, generally project-wide, to help you define and configure
  job related stuff in a single ruby file.

* The `jobco` command line tool:
  * Wraps Resque process management (`jobco resque --help`)
  * Allows trivial job control (`jobco jobs --help`)
  * A good friend for ruby job developpers !

* The `JobCo::*` Ruby library, that provide useful primitives for writing and
  controlling jobs. It is a Resque wrapper of sorts, with some (limited) extra features
  coming along.

## Who should use JobCo

* you want/need most of the features brought on by JobCo plugins, or compatible Resque plugins
* you'd rather have a convenient, surprise-less API to work with it
* you find some interest in improvements brought forward by JobCo

## Documentation

Check it all out. Really. It's good for you.

* The original Resque documentation. You should really not miss out on this one.
* JobCo RDoc
* resque-scheduler RDoc
* `jobco --help`
* the `samples` directory in jobco's repository

## Get me started ! NOW !

Right. Don't forget about the documentation. What follows is as minimal as it gets.

First off, you need a Jobfile. It is a regular ruby file, and you should put it at the root of your project, next to your Gemfile and similar stuff.

~~~ruby
JobCo::Config.job_load_path = File::expand_path("../app/jobs", __FILE__)

# JobCo will use the Resque.redis connection when needed
# It is recommended to use a separate redis database for resque+jobco
# (so that you can flush it easily while possibly having precious data elsewhere in redis)
Resque.redis = Redis.new
~~~

Then, you need a job, in that `app/jobs` directory. Let's say this is `app/jobs/my_test_job.rb`. Here's a very simple skeleton :

~~~ruby
require "jobco"

class MyTestJob
  include JobCo::Plugins::Base

  def perform
    # Do stuff !
    puts "stuff"
  end
end
~~~

Would you like to run this job ? Thought so.

First, let's check JobCo knows about your job. Inside a shell, `cd` wherever your Jobfile is.

~~~
$ jobco jobs ls
Jobs known to JobCo:
 * MyTestJob
~~~

Looks legit. So what now ?

~~~
$ jobco jobs enqueue MyTestJob
Queued MyTestJob, ID=a029f9f029e4012f680608002749b362
~~~

So far, so good. But your stuff haven't be executed yet - Resque calls this execution the `perform` stage. To `perform` your job, we need a Resque worker to run it. Let's do this, in the foreground of our shell:

~~~
$ jobco resque worker start
*** got: (Job{jobco} | MyTestJob | [])
stuff
*** done: (Job{jobco} | MyTestJob | [])
~~~

Et voila !

## Get this in production ! QUICK !

* You might want to deploy jobco 0.1.x branch, which works for current stable 1.x resque releases. It has some limitations, and the stack is really not as good as 0.2+. If you're rolling out 0.1.x in production, let me know !

* Jobco 0.2+ (currently on master branch) is not ready to be deployed in production, because it is based on resque 2.0+, the first
release of which hasn't came out yet. I might be tempted to do a quick write up about how to run it in the wild if there's some interest. Shout me out on twitter, I'm @mr_zor there :)

In the meantime `jobco resque --help` ('--help' will work for any subcommand) should provide enough insights for %w[chef puppet capistrano monit rake bash].any enthusiasts.

## Helping out

* Feedback is good
* Issue reporting is better
* Pull requests are way better
* Awesome pull requests are *obviously awesome*
