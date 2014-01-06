#!/usr/bin/env ruby
# encoding: UTF-8

require 'sinatra'

get '/cookbooks' do
  content_type :json
  "{}"
end
