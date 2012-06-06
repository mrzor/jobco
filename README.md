## JobCo

JobCo is a Resque distribution.

It wraps Resque, alongside the `JobWithStatus` and `Scheduler` plugins,
into one easy to use package.

JobCo is open source software, licensed under the terms of the 3-clause BSD license, with an additional disclaimer. See LICENSE file for details.

## This is early stage software

**Warning**

0.1.0 is the first release of JobCo, and its API should *not* be considered stable.
As a matter of fact, 0.1.0 won't be publicly released because it depends on resque-status 0.2.3, which have been superceded.
This tag is here for the convenience of timeline hackers.

**But still...**

We put it in production, and it mostly works beautifully, because it's built on top of Resque, which definitely does work beautifully.

## What do I get ?

For your job running projects, rolling out with JobCo means :

* A `Jobfile`, generally project-wide, to help you define and configure
  job related stuff in a single (ruby) file.

* The `jobco` command line tool:
  * Wraps Resque process management (`jobco resque --help`)
  * Allows trivial job control (`jobco jobs --help`)
  * A good friend for ruby job developpers !

* The `JobCo::*` Ruby library, that provide useful primitives for writing and
  controlling jobs. It is a Resque wrapper of sorts, with some (limited) extra features
  coming along.

## Who should use JobCo

* you want/need most of the features brought on by the Resque+Status+Scheduler combo
* you'd rather have a convenient, surprise-less API to work with it
* you find some interest in improvements brought forward by JobCo

## Documentation

Check it all out. Really. It's good for you.

* The original Resque documentation. You should really not miss out on this one.
* JobCo RDoc
* resque-scheduler RDoc
* resque-status RDoc
* `jobco --help`
* samples/ directory

## Get me started ! NOW !

Right. Don't forget about the documentation. What follows is as minimal as it gets.

First off, you need a Jobfile.

~~~ruby
job_load_path File.expand_path("../app/jobs", __FILE__)

jobconf "resque_redis", {port: 6379}
~~~

Then, you need a job, in that `app/jobs` directory. Let's say this is `app/jobs/my_test_job.rb`. Here's a very simple skeleton :

~~~ruby
require "jobco/job"

class MyTestJob < JobCo::Job
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

So far, so good. But your stuff ain't executed yet. That is because we need a Resque worker to run it. Let's do this, in the foreground of our shell:

~~~
$ jobco resque worker start
*** got: (Job{jobco} | MyTestJob | ["a029f9f029e4012f680608002749b362"])
stuff
*** done: (Job{jobco} | MyTestJob | ["a029f9f029e4012f680608002749b362"])
~~~

Et voila !

## Get this in production ! QUICK !

We did it. It can be done. The documentation will come later.
In the meantime `jobco resque --help` ('--help' will work for any subcommand) should provide enough insights for %w[chef puppet capistrano monit rake bash].any enthusiasts.

## Helping out

* Feedback is good
* Issue reporting is better
* Pull requests are way better
* Awesome pull requests are *obviously awesome*
