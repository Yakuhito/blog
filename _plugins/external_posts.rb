# frozen_string_literal: true

# Posts that still live on blog.fireacademy.io are listed on the homepage via
# external_url, but they have no body here yet. Keep their future URLs out of
# Google until the text is ported: no HTML page, no sitemap entry, no feed entry.
# Removing external_url is what publishes the post on this site.

module Jekyll
  class ExternalPosts < Generator
    priority :high

    def generate(site)
      site.posts.docs.each do |post|
        next if post.data["external_url"].to_s.empty?

        post.data["sitemap"] = false
      end
    end
  end
end

module ExternalPostOutput
  def write?
    return false if data["external_url"]

    super
  end
end
Jekyll::Document.prepend(ExternalPostOutput)

Jekyll::Hooks.register :pages, :pre_render do |page|
  # jekyll-feed names the generated page "/feed.xml", not "feed.xml".
  next unless page.name.to_s.end_with?("feed.xml")

  needle = '{% assign posts = site[page.collection] %}'
  unless page.content.include?(needle)
    raise "feed.xml posts assign changed; external posts would be advertised again"
  end

  page.content = page.content.sub(
    needle,
    '{% assign posts = site[page.collection] | where_exp: "post", "post.sitemap != false" %}'
  )
end
