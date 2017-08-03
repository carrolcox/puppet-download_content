# Download content from url
module Puppet::Parser::Functions:
    newfunction(:download_content, :type => :rvalue) do |args|

        require 'puppet/parser/functions'
        require 'net/http'
        require 'net/https'
        require 'uri'

        unless args.size = 2
            raise Puppet::ParseError, ("download_content can accept only two arguments -> URL and redirections limit")
        end

        uri = URI(args[0])
        lim = args[1] || 20
        content = nil

        http = Net::HTTP.new(uri.host, uri.port)

        if uri.scheme == 'https'
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        request = Net::HTTP::Get.new uri.request_uri
        http.request(request) do |response|
            case response
            when Net::HTTPRedirection then
                location = response['location']
                raise Puppet::Notice("redirected to #{location}")
                download_content(location, lim - 1)
            when Net::HTTPForbidden then
                raise Puppet::ParseError, ("SecurityError -> Access denied")
            when Net::HTTPNotFound then
                raise Puppet::ParseError, ("ArgumentError -> Not found")
            when Net::HTTPError then
                if nil != http and http.started?
                    http.finish()
                end
                raise Puppet::ParseError, ("HTTP Exception during download -> #{ehttp.inspect}")
            when Net::HTTPSuccess then
                response.read_body do |chunk|
                    io_ready_to_write.write(chunk)
                end
                content = chunk
            else
                raise Puppet::ParseError, ("Unexpected state => #{response.code} - #{response.message}")
            end
        end
        return content if not nil
    end
end
