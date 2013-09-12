require 'rubygems'
require 'net/http'
require 'uri'
require 'digest'
require 'anemone'
require 'open-uri'
require 'diffy'

unless ARGV[0] && ARGV[1]
  puts 'please enter two urls to spider'
  puts 'omit the http:// and trailing /'
  puts 'example: ruby compare.rb mpr.org stage.mpr.org'
  exit
end

oldDomain = 'http://' + ARGV[0];
newDomain = 'http://' + ARGV[1];

fname = 'output/compare-' + Time.new.to_s + '.html'

out = File.open(fname, 'w')

out.puts '<html>'
out.puts '<head>'
out.puts '<style>'
#colorize diffs
out.puts Diffy::CSS
#custom compare styles
out.puts '.same { color: green }'
out.puts '.different { color: red }'
out.puts 'ul.results { list-style:none; padding: 0 }'
out.puts '.fetch_error { color:white; background:red }'
out.puts 'li.fetch_error { list-style:none }'
out.puts 'span.fetch_error { list-style:none }'
out.puts 'li.comp_result { list-style:none; border-top: thin solid black}'
#override defaults
out.puts '.diff { overflow: visible }'
out.puts'</style>'
out.puts '</head>'
out.puts '<body>'

out.puts '<ul class="results">'

Anemone.crawl(oldDomain) do |anemone|
  anemone.on_every_page do |old_page|
    puts old_page.url

    old_output_hash = Digest::MD5.hexdigest(old_page.body)

    # Get secondary page.
    old_page.url
    new_url = newDomain + old_page.url.path
    if old_page.url.query
      new_url += '?' + old_page.url.query
    end
    new_page = Net::HTTP.get_response(URI(new_url))
    new_output_hash = Digest::MD5.hexdigest(new_page.body)

    out.puts '<li class="comp_result"><ul>'
    out.puts '<li>URL: <a href="' + new_url + '">' + new_url +'</a></li>'

    if new_output_hash == old_output_hash
      out.puts '<li>Status: <span class="same">Body is same</span></li>'
    else
      out.puts '<li>Status: <span class="different">Body is different</span></li>'
      out.puts '<li>Diff: ' + Diffy::Diff.new(old_page.body, new_page.body, :include_plus_and_minus_in_html => true, :context => 1, :include_diff_info => true).to_s(:html) + '</li>'
    end

    out.puts '</ul></li>'
  end
end

out.puts '</ul>'

out.puts '</body></html>'
out.close

puts 'done'
puts Time.new
