#######################################################
#
# AptlyAPI gem
# Copyright 2015, R1Soft.
# Released under the terms of the GPLv2
#
# Wrangle remote Aptly Servers over
# the Aptly API.
#
# Authors:
#  Alexander von Gluck IV <Alex.vonGluck@r1soft.com>
#
#######################################################

require 'uri'
require 'net/http'
require 'json'

module AptlyAPI
	##
	# This class represents an Aptly server running the Aptly API
	class Server
		##
		# Creates a new AptlyServer located at +url+
		def initialize(url)
			@server = URI(url)
			@http = Net::HTTP.new(@server.host, @server.port)
			@version = hget("/api/version").fetch("Version", "unknown")
		end

		##
		# Create a new repo called +name+. If the specified repo already
		# exists, simply returns the AptlyRepo for the existing repo.
		def create_repo(name, options = {})
			request_body = Hash.new
			request_body.merge!({"Name" => name})
			request_body.merge!(options)
			return true if hpost('/api/repos', request_body) == 200
			return false
		end

		##
		# Deletes an aptly repo called +name+ from the AptlyServer
		def delete_repo(name)
			return true if hdelete("/api/repos/#{name}") == 200
			return false
		end

		##
		# Get an array of all AptlyRepo's that exist on server.
		def get_repos
			repos = Array.new
			remote_repos = hget("/api/repos")
			remote_repos.each do |info|
				repos.push(Repo.new(@server, info))
			end
			return repos
		end

		##
		# Get AptlyRepo object for repo called +name+
		def get_repo(name)
			remote_repo = hget("/api/repos/#{name}")
			return Repo.new(@server, remote_repo)
		end

		##
		# Return true if repo called +name+ exists. Otherwise false
		def repo_exist?(name)
			remote_repo = hget("/api/repos/#{name}")
			return true
		end

		##
		# Compre two AptlyServer objects to see if they are identical
		def ==(r)
			r.server == server and r.version == version
		end

		attr_reader :server, :version

	protected
		##
		# Get an hash of JSON data from server +path+
		def hget(path)
			request = Net::HTTP::Get.new("#{@server.path}#{path}")
			response = @http.request(request)
			if response.code.to_i != 200
				return response.code.to_i
			end
			return JSON.parse(response.body)
		end

		##
		# Post +data+ hash to +path+ as JSON
		def hpost(path, data)
			request = Net::HTTP::Post.new("#{@server.path}#{path}")
			request.add_field('Content-Type', 'application/json')
			request.body = data.to_json
			response = @http.request(request)
			return response.code.to_i
		end

		##
		# Sends HTTP delete call to +path+
		def hdelete(path)
			request = Net::HTTP::Delete.new("#{@server.path}#{path}")
			response = @http.request(request)
			return response.code.to_i
		end
	end
end