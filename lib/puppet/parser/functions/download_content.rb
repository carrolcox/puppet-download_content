# Download content from url
require 'puppet/parser/functions'
require 'net/http'
require 'net/https'
require 'uri'

Puppet::Parser::Functions::newfunction(:download_content, :type => :rvalue) do |args|

	if args.size != 2
		Puppet.crit("download_content can accept only two arguments - URL and redirections limit")
	end

	uri = URI(args[0])
	lim = args[1] || 10
	content = nil

	http = Net::HTTP.new(uri.host, uri.port)
	if uri.scheme == 'https'
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	end

	request = Net::HTTP::Get.new uri.request_uri
	http.request request do |response|
		case response
		when Net::HTTPRedirection then
			location = response['location']
			Puppet.notice("redirected to #{location}")
			download_content(location, lim - 1)
		when Net::HTTPForbidden then
			Puppet.crit("SecurityError -> Access denied")
		when Net::HTTPNotFound then
			Puppet.crit("ArgumentError -> Not found")
		when Net::HTTPError then
			if nil != http and http.started?
				http.finish()
			end
			Puppet.crit("HTTP Exception during download")
		when Net::HTTPSuccess then
			content = response.body
		else
			Puppet.crit("Unexpected state => #{response.code} - #{response.message}")
		end
	end
	return content if not nil
end
