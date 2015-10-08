# Download content from url

Puppet::Parser::Functions::newfunction(:download_content, :type => :rvalue) do |args|

	require 'net/http'
	require 'net/https'
	require 'uri'

	unless url = args[0]
		raise Puppet::ParseError, ":download_content(): requires at least one argument"
	end

	raise(Puppet::ParseError,':download_content(): cannot accept only one argument') if args.size != 1
	
	REQUEST_TYPES = {
		'get'  => Net::HTTP::Get,
		'head' => Net::HTTP::Head,
	}

	reqtype    = 'get'
	limit      = 60

	# Create the Net::HTTP connection and request objects
	request    = REQUEST_TYPES[reqtype.to_s.downcase].new(uri.request_uri)
	connection = Net::HTTP.new(uri.host,uri.port)
    
	# Configure the Net::HTTP connection object
	if uri.scheme == 'https'
		connection.use_ssl = true
	end
	if connection.use_ssl?
	       connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
	end
    
	# Configure the Net::HTTPRequest object
	if options[:headers]
		options[:headers].each {|key,value| request[key] = value }
	end

	recursive_response = nil
	response = connection.start do |http|
		http.request(request) do |resp|
			# Determine and react to the request result
			case resp
			when Net::HTTPRedirection
				next_opts = options.merge(:limit => limit - 1)
				next_loc  = URI.parse(resp['location'])
		      		recursive_response = http(next_loc, io_ready_to_write, next_opts)
			when Net::HTTPSuccess
		      		resp.read_body do |chunk|
			    		io_ready_to_write.write(chunk)
		      		end
			else
		      		raise Puppet::Error.new "Unexpected response code #{resp.code}: #{resp.read_body}"
			end
	  	end
    	end

	if response != nil and recursive_response != nil
		recursive_response || response
	else
		raise(Puppet::ParseError,':download_content(): nothing to return')
	end
end
