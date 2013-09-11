require 'rubygems'
require 'net/http'
require 'uri'
require 'digest'
require 'nokogiri'
require 'open-uri'
require 'diffy'

unless ARGV[0] && ARGV[1]
  puts 'please enter two urls to spider'
  puts 'omit the http:// and trail /'
  puts 'example: ruby compare.rb mpr.org stage.mpr.org'
  exit
end

$oldDomain = 'http://' + ARGV[0];
$newDomain = 'http://' + ARGV[1];
$allowedDomain = ARGV[1];

pages = [
  '/',
]

$results = {};

$results[:errors] = {};

fname = 'compare-' + ARGV[0] + '-to-' + ARGV[1] + '-' + Time.new.to_s + '.html'

$out = File.open(fname, 'w')

$out.puts '<html>'
$out.puts '<head>'
$out.puts '<style>'
#colorize diffs
$out.puts Diffy::CSS
#custom compare styles
$out.puts '.same { color: green }'
$out.puts '.different { color: red }'
$out.puts 'ul.results { list-style:none; padding: 0 }'
$out.puts '.fetch_error { color:white; background:red }'
$out.puts 'li.fetch_error { list-style:none }'
$out.puts 'span.fetch_error { list-style:none }'
$out.puts 'li.comp_result { list-style:none; border-top: thin solid black}'
#override defaults
$out.puts '.diff { overflow: visible }'
$out.puts'</style>'
$out.puts '</head>'
$out.puts '<body>'

def comparePage(old_url, new_url)
  unless $results[new_url]
    $results[new_url] = {}
  end

  unless $results[new_url][:status]
    $results[new_url][:status] = 'pending'
    $results[new_url][:old_url] = old_url

    print "."

    begin
      old_page = Net::HTTP.get_response(URI(old_url))
      old_output_hash = Digest::MD5.hexdigest(old_page.body)

      new_page = Net::HTTP.get_response(URI(new_url))
      new_output_hash = Digest::MD5.hexdigest(new_page.body)

    rescue
      $results[new_url][:status] = '<span class="fetch_error">unfetchable by Net::HTTP</span>'
      return
    end

    processLinks(new_url)

    if new_output_hash == old_output_hash
      $results[new_url][:status] = '<span class="same">Body is same</span>'
    else
      $results[new_url][:status] = '<span class="different">Body is different</span>'
      $results[new_url][:diff] = Diffy::Diff.new(old_page.body, new_page.body, :include_plus_and_minus_in_html => true, :context => 1, :include_diff_info => true).to_s(:html)
    end

  end

end

def processLinks(parse_url)

  begin
    new_noko = Nokogiri::HTML(open(parse_url))
  rescue
    $results[parse_url][:status] = '<span class="fetch_error">unfetchable by Nokogiri</span>'
    return
  end

  new_noko.css('a').each do |link|

    target_ref = link.attribute('href')

    if target_ref

      target = target_ref.content

      unless target =~ /mailto/

        linkbits = target.split('/')

        case linkbits[0]
        when nil
          #no-op for back to root node

        when 'http:'
          if linkbits[2] == $allowedDomain
            $results[:errors][target] = '<span class="fetch_error">fully qualified domain</span>'
          end

        when 'https:'
            if linkbits[2] == $allowedDomain
              $results[:errors][target] = '<span class="fetch_error">secure fully qualified domain</span>'
            end

        else
          new_target = $newDomain + target
          unless $results[new_target] || new_target == parse_url
            $results[new_target] = { :referer => parse_url }
            comparePage($oldDomain + target, $newDomain + target)
          end

        end

      end
    end
  end
end

# here we go
puts Time.new
print "processing"

pages.each do |page|
  comparePage($oldDomain + page, $newDomain + page)
end

$out.puts '<ul class="results">'
$results.each do |key, val|
  if key == :errors
    $out.puts '<li class="errors"><ul>'
    val.each do |ekey, eval|
      $out.puts "<li class='fetch_error'><a href='#{ekey}'>#{ekey}</a>: #{eval}</li>"
    end
    $out.puts '</li></ul>'
  else

    $out.puts '<li class="comp_result"><ul>'
    $out.puts '<li>URL: <a href="' + key + '">' + key +'</a></li>'
    if (val[:referer])
      $out.puts '<li>Ref: <a href="' + val[:referer] + '">' + val[:referer] + '</a></li>'
    end
    $out.puts '<li>Status:' + val[:status] + '</li>'
    if (val[:diff])
      $out.puts '<li>Diff: ' + val[:diff] + '</li>'
    end
    $out.puts '</ul></li>'

  end

end
$out.puts '</ul>'

$out.puts '</body></html>'
$out.close

puts 'done'
puts Time.new
