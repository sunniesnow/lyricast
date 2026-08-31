#!/usr/bin/env ruby

require 'fileutils'
require 'net/http'
require 'json'
require 'securerandom'
require 'base64'
require 'cgi/escape'
require 'yaml'

require 'sinatra/base'

require_relative 'lib/version'
require_relative 'lib/config'
require_relative 'lib/lang'
require_relative 'lib/api'
require_relative 'lib/item'
require_relative 'lib/news'
require_relative 'lib/server'

Lyricast::Server.run!
