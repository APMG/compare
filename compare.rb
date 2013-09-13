require 'rubygems'
require 'net/http'
require 'uri'
require 'digest'
require 'anemone'
require 'open-uri'
require 'diffy'

unless ARGV[0] && ARGV[1]
  puts 'Enter two URLs to spider and compare.'
  puts 'The second site will be spidered and compared to the same URL on the first site.'
  puts 'The spider will stay within the domain.'
  puts 'Example: ruby compare.rb http://mpr.org http://stage.mpr.org'
  exit
end

old_domain = ARGV[0];
new_domain = ARGV[1];

fname = 'output/compare-' + URI::parse(new_domain).host + '-' + Time.new.to_s + '.html'

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

Anemone.crawl(old_domain, :read_timeout => 100000) do |anemone|

  anemone.on_every_page do |old_page|
    puts old_page.url

    old_output_hash = Digest::MD5.hexdigest(old_page.body)

    # Get secondary page.
    old_page.url
    new_url = new_domain + old_page.url.path
    if old_page.url.query
      new_url += '?' + old_page.url.query
    end

    uri = URI(new_url)
    new_page = nil
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new(uri)
      http.read_timeout = 100000

      new_page = http.request(request)
    end

    new_output_hash = Digest::MD5.hexdigest(new_page.body)

    out.puts '<li class="comp_result"><ul>'
    out.puts '<li>URL: <a href="' + new_url + '">' + new_url +'</a></li>'

    if old_page.code.to_i == new_page.code.to_i
      if new_output_hash == old_output_hash
        out.puts '<li>Status: <span class="same">Body is same</span></li>'
      else
        out.puts '<li>Status: <span class="different">Body is different</span></li>'
        out.puts '<li>Diff: ' + Diffy::Diff.new(old_page.body, new_page.body, :include_plus_and_minus_in_html => true, :context => 1, :include_diff_info => true).to_s(:html) + '</li>'
      end
    else
      out.puts '<li>Status: <span class="different">Codes are different.</span></li>'
      out.puts '<li>Old site: ' + old_page.code.to_s + '</li>'
      out.puts '<li>New site: ' + new_page.code.to_s + '</li>'
    end

    out.puts '</ul></li>'

    # Drop document to conserve memory.
    old_page.discard_doc!
  end
end

out.puts '</ul>'

out.puts '</body></html>'
out.close

puts 'done'
puts Time.new
