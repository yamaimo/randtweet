require "randtweet/version"

require 'pathname'
require 'yaml'
require 'twitter'

module RandTweet

  class Config
    File = Pathname.new("config.yml")
    Template = <<~END_OF_TEMPLATE
      consumer_key:         YOUR_CONSUMER_KEY
      consumer_secret:      YOUR_CONSUMER_SECRET
      access_token:         YOUR_ACCESS_TOKEN
      access_token_secret:  YOUR_ACCESS_SECRET
      files:
        - {path: filepath1, weight: 20}
        - {path: filepath2, weight: 10}
    END_OF_TEMPLATE

    def self.create_template(dir=nil)
      basedir = dir.nil? ? Pathname.pwd : Pathname.new(dir)
      basedir.mkpath
      template = basedir + File
      template.write(Template)
      template
    end

    def initialize(dir=nil)
      basedir = dir.nil? ? Pathname.pwd : Pathname.new(dir)
      config_file = basedir + File
      config = YAML.load_file(config_file)
      @consumer_key = config['consumer_key']
      @consumer_secret = config['consumer_secret']
      @access_token = config['access_token']
      @access_token_secret = config['access_token_secret']
      @files = []
      @total_weight = 0
      files = config['files']
      files.each do |file|
        path = basedir + Pathname.new(file['path'])
        weight = file['weight']
        @files.push({path: path, weight: weight})
        @total_weight += weight
      end
    end

    attr_reader :consumer_key, :consumer_secret, :access_token, :access_token_secret
    attr_reader :files, :total_weight
  end

  def select_content(config)
    total = config.total_weight
    value = Random.rand(total)  # generate a value in [0, total).

    selected_path = nil
    upper = 0
    config.files.each do |file|
      upper += file[:weight]
      if value < upper
        selected_path = file[:path]
        break
      end
    end
    if selected_path.nil?
      raise "File is not selected."
    end

    lines = selected_path.readlines(chomp: true)
    lines.delete_if(&:empty?)
    if lines.empty?
      raise "File #{selected_path} is empty."
    end

    lines.sample
  end

  def tweet(config, content)
    if content.nil? || content.empty?
      raise "Content is empty."
    end
    client = Twitter::REST::Client.new do |client_config|
      client_config.consumer_key        = config.consumer_key
      client_config.consumer_secret     = config.consumer_secret
      client_config.access_token        = config.access_token
      client_config.access_token_secret = config.access_token_secret
    end
    client.update(content)
  end

  module_function :select_content, :tweet
end
