#!/usr/bin/env ruby

require 'rubygems'
require 'time'
require 'cgi'
require 'hmac'
require 'hmac-sha2'
require 'base64'

config = YAML.load(File.read("config.yml"))

def get_signed_url(key, secret_key, action, params)
  base_url = "monitoring.amazonaws.com"
  
  url_params = params.clone
  url_params['AWSAccessKeyId'] = key
  url_params['Action'] = action
  url_params['SignatureMethod'] = 'HmacSHA256'
  url_params['SignatureVersion'] = '2'
  url_params['Version'] = '2010-08-01'
  url_params['Timestamp'] = Time.now.iso8601

  canonical_querystring = url_params.sort.collect { |key, value| [CGI.escape(key.to_s), CGI.escape(value.to_s)].join('=') }.join('&')
  string_to_sign = "GET\n#{base_url}\n/\n#{canonical_querystring}"

  hmac = HMAC::SHA256.new(secret_key)
  hmac.update(string_to_sign)
  signature = Base64.encode64(hmac.digest).chomp

  url_params['Signature'] = signature
  querystring = url_params.collect { |key, value| [CGI.escape(key.to_s), CGI.escape(value.to_s)].join('=') }.join('&')
  
  "https://#{base_url}/?#{querystring}"
end

def get_signed_url_for_used_memory_percent(config)
  meminfo = `cat /proc/meminfo`

  mem_total = meminfo.scan(/^MemTotal:\s*([0-9]*)/)[0][0].to_f
  mem_free = meminfo.scan(/^MemFree:\s*([0-9]*)/)[0][0].to_f
  mem_buffers = meminfo.scan(/^Buffers:\s*([0-9]*)/)[0][0].to_f
  mem_cached = meminfo.scan(/^Cached:\s*([0-9]*)/)[0][0].to_f

  mem_used = (100 - (mem_free + mem_buffers + mem_cached) * 100 / mem_total).round(1)

  params = {
    'Namespace'                                     => 'System/Linux',
    'MetricData.member.1.MetricName'                => 'UsedMemoryPercent',
    'MetricData.member.1.Value'                     => mem_used,
    'MetricData.member.1.Unit'                      => 'Percent',
    'MetricData.member.1.Dimensions.member.1.Name'  => 'InstanceID',
    'MetricData.member.1.Dimensions.member.1.Value' => config['aws']['instance_id']
  }

  get_signed_url(config['aws']['access_key'], config['aws']['secret_key'], 'PutMetricData', params)
end

def get_signed_url_for_used_disk_percent(config)
  df = `df`
  df_root = df.match(/.*([0-9]+)%\s*\/\s*$/)[0].split(' ')
  
  root_available = df_root[1].to_f
  root_used = df_root[2].to_f

  disk_used = ((root_used / root_available) * 100).round(1)

  params = {
    'Namespace'                                     => 'System/Linux',
    'MetricData.member.1.MetricName'                => 'UsedDiskPercent',
    'MetricData.member.1.Value'                     => disk_used,
    'MetricData.member.1.Unit'                      => 'Percent',
    'MetricData.member.1.Dimensions.member.1.Name'  => 'InstanceID',
    'MetricData.member.1.Dimensions.member.1.Value' => config['aws']['instance_id']
  }

  get_signed_url(config['aws']['access_key'], config['aws']['secret_key'], 'PutMetricData', params)
end

puts `curl -X "GET" "#{get_signed_url_for_used_memory_percent(config)}"`
puts `curl -X "GET" "#{get_signed_url_for_used_disk_percent(config)}"`
