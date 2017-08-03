# Download content from url. Ruby API (modern)
Puppet::Functions.create_new(:download_content) do
    dispatch :download_content do
        required_param 'String', :url
        optional_param 'Integer', :lim
        return_type 'NotUndef'
    end

    def :download_content(url, lim = 10)
        
        content = nil
        uri = URI(url)

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

