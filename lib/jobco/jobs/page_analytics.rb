require "jobco/job"
require "garb"

class Pageviews
  extend Garb::Model

  metrics :pageviews
  dimensions :page_path
end

module JobCo
  module Jobs
    class PageAnalytics < Job
      @queue = :google_analytics

      def perform
        Garb::Session.login("elie@letitcast.com", "XXX")
        profile = Garb::Management::Profile.all.first
        filters = { :page_path.substring => '/a/' }
        analytics = Pageviews.results(profile, :filters => filters)

        @counters = {}
        analytics.each do |result|
          result.page_path =~ /\/([a-z]+)\/a\/(.*)$/
          lang, slug = $1, $2
          pageviews = result.pageviews.to_i

          @counters[slug] ||= {}
          @counters[slug][lang] = pageviews

          @counters[slug]["overall"] ||= 0
          @counters[slug]["overall"] += pageviews
        end

        rn = Redis::Namespace.new("lic_public_page_counters", :redis => Resque.redis.redis)
        @counters.each_pair { |slug, langs| rn.hset("overall_views", slug, langs["overall"]) }
      end
    end
  end
end
