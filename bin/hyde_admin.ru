# cat config.ru
# lancer avec rackup
require "roda"
require 'yaml'
require 'fileutils'
require 'i18n'
require 'date'
require_relative '../lib/hyde_admin/version'

# TODO détecter format nouveau post (pour codemirror)

class App < Roda
  YML_FILE_NAME = "hyde_admin.yml"

  plugin :render,
    #escape: true, # Automatically escape output in erb templates using Erubi's escaping support
    views: File.join(File.expand_path(File.dirname(__FILE__)),'admin_views'), # Default views directory
    layout_opts: {template: 'admin_layout', engine: 'html.erb'},    # Default layout options
    template_opts: {default_encoding: 'UTF-8'} # Default template options
  plugin :i18n, translations: File.join(File.expand_path(File.dirname(__FILE__)), 'i18n') # gem 'roda-i18n'
  opts[:root] = Dir.pwd
  plugin :public, root: File.join(Dir.pwd, '_site') # simulate jekyll site
  plugin :static, ['/mode', '/lib', '/fslightbox', '/hyde_assets'], :root => File.join(File.expand_path(File.dirname(__FILE__)))
  plugin :http_auth
  plugin :common_logger

  def initialize(param)
    yml_in_current_dir = File.join(Dir.pwd, YML_FILE_NAME)
    yml_in_gem = File.expand_path(File.join(File.dirname(__FILE__), YML_FILE_NAME))

    # Generate default YML for hyde_admin
    if !File.exist?(yml_in_current_dir)
      FileUtils.cp(yml_in_gem, yml_in_current_dir)
    end
    @hyde_parameters ||= YAML.load(File.read(yml_in_current_dir))
    super(param)
  end

  def self.transliterate_title_for_url(title)
    I18n.config.available_locales = :en
    I18n.transliterate(title).downcase.gsub(/[^a-zA-Z ]/,'').gsub(' ','-')
  end

  def self.urlize(date_str, title, with_date = true)
    url_str = ""
    if with_date
      url_str += "#{Date.parse(date_str).strftime('%Y-%m-%d')}-"
    end
    url_str += "#{self.transliterate_title_for_url(title)}"
    url_str
  end

  def self.extract_header_str(str)
    str.scan(/---(.*?)---/m).flatten.first
  end

  def self.extract_header(str)
    headers = App.extract_header_str(str).to_s.split("\n")
    headers = headers.select{ |header| !header.empty? }.map{ |header| header.scan(/([a-zA-Z0-9]*): (.*)/).flatten }.select{ |header| !header.empty? }
    hsh_headers = {}
    if !headers.flatten.empty?
      #$stderr.puts "==============="
      #$stderr.puts headers.inspect
      hsh_headers = Hash[headers]
    end
    hsh_headers
  end

  def self.remove_header(str)
    str.gsub(/---(.*?)---/m, "")
  end

  FORMAT_DATE_FILENAME = '%Y-%m-%d'
  FORMAT_DATE_INPUT_FILENAME = '%Y-%m-%d %H:%M:%S %z'

  REGEXP_EXTRACT_DATE_FROM_FILENAME = /\d{4}-\d{2}-\d{2}-/
  REGEXP_EXTRACT_DATE_TITLE_FROM_FILENAME = /(\d{4}-\d{2}-\d{2}-)(.*)(\.[^.]*)$/

  route do |r|
    @page = r.params['page']

    if @hyde_parameters['hyde_admin_auth'].to_s == 'true'
      http_auth {|u, p| [u, p] == [@hyde_parameters['hyde_admin_user'], @hyde_parameters['hyde_admin_password']] }
    end

    # GET serve jekyll site
    r.public

    r.i18n_set_locale(@hyde_parameters['hyde_admin_language']) do

    r.root do
      r.redirect "/dashboard"
    end

    # Redirect to jekyll index site
    r.on "overview" do
      r.redirect @hyde_parameters['site_index']
    end

    # Rebuild static files
    r.on "rebuild" do
      puts Dir.pwd
      `cd #{Dir.pwd} && jekyll b`
      r.redirect "/dashboard"
    end

    r.on "deploy" do
      `#{@hyde_parameters['rsync_fullpath']} #{Dir.pwd}/_site/ #{@hyde_parameters['deploy_dest_user']}@#{@hyde_parameters['deploy_dest_address']}:#{@hyde_parameters['deploy_dest_path']}`
      r.redirect "/dashboard"
    end

    r.post "configuration" do
      r.params.each_pair do |k,v|
        @hyde_parameters[k] = v
      end
      File.open(File.join(Dir.pwd, YML_FILE_NAME),"w+") do |f|
        f.write(@hyde_parameters.to_yaml)
      end
      r.redirect "/configuration"
    end

    r.get "configuration" do
      view("configuration")
    end

    r.on "dashboard" do
      view("dashboard")
    end

    r.on "files" do
      @dir_path = r.params['dir_path'] || Dir.pwd

      # List files
      r.get "index" do
        @files = Dir[File.join(@dir_path, '*')].sort(&:casecmp).reverse
        @parent_dir = (@dir_path != Dir.pwd)
        view("files/listing")
      end

      # Upload files
      r.post "create" do
        files = [r.params['files']].flatten # 1 or more files
        files.each do |file|
          File.open(File.join(@dir_path, file[:filename]), 'wb') do |f|
            f.write(file[:tempfile].read)
          end
        end
        r.redirect "/files/index?dir_path=#{@dir_path}"
      end

      # Create directory
      r.post "create_dir" do
        Dir.mkdir(File.join(@dir_path, r.params['directory_name']))
        r.redirect "/files/index?dir_path=#{@dir_path}"
      end

      # Create file
      r.post "create_file" do
        fullpath = File.join(@dir_path, r.params['file_name'])
        File.open(fullpath, 'w+') do |f|
          f.write("")
        end
        r.redirect "/files/edit?dir_path=#{@dir_path}&file=#{fullpath}"
      end

      # Edit text files
      r.get "edit" do
        @file = r.params['file']
        @content = File.read(@file)
        @header = App.extract_header_str(@content)
        @content = App.remove_header(@content)
        @has_header = (!@header.nil? && !@header.empty?)
        @has_editor = ['.html','.md'].include?(File.extname(@file))
        view("files/edit")
      end

      # Update file
      r.post "update" do
        @file = r.params['file']
        @content = r.params['content']
        @header = r.params['header']
        File.open(@file,"w+") do |f|
          if !@header.nil? and !@header.empty?
            f.write("---")
            f.write(@header)
            f.write("---")
            f.write("")
          end
          f.write(@content)
        end
        view("files/edit")
      end

      # Delete
      r.post "delete" do
        file = r.params['file']
        File.unlink(file)
        r.redirect "/files/index?dir_path=#{@dir_path}"
      end
    end

    r.on "ajax" do
      r.post "update_path_date" do
        path = r.params['path']
        date = Date.parse(r.params['date'])
        new_path = path.gsub(REGEXP_EXTRACT_DATE_FROM_FILENAME, date.strftime("#{FORMAT_DATE_FILENAME}-"))
        response.write(new_path)
      end
      r.post "update_path_title" do
        path = r.params['path']
        title = r.params['title']
        I18n.config.available_locales = :en
        new_path = path.gsub(REGEXP_EXTRACT_DATE_TITLE_FROM_FILENAME, "\\1#{App.transliterate_title_for_url(title)}\\3")
        response.write(new_path)
      end
      r.post "update_date_today" do
        date = Time.now.strftime(FORMAT_DATE_INPUT_FILENAME)
        response.write(date)
      end
    end

    # Posts/pages/drafts
    r.on /posts|pages|drafts/ do
      # Set variable for all routes in /hello branch
      @type_file = r.matched_path.split('/').compact.select{ |elt| elt != '' }.first

      # Mkdir _pages _drafts _posts if they not exist
      FileUtils.mkdir_p(File.join(Dir.pwd, "_#{@type_file}"))

      # GET /posts/index request
      # list all posts...
      r.get "index" do
        @files = Dir[File.join(Dir.pwd, "_#{@type_file}", '*')].sort.reverse
        view("posts/listing")
      end

      r.get "new" do
        @file = ""
        @headers = {}
        @new_record = @file.empty?
        view("posts/edit")
      end

      # POST /posts/delete?file=truc request
      # save the truc post
      r.post "delete" do
        @file = r.params['file']
        File.unlink(@file)
        r.redirect "/#{@type_file}/index?dir_path=#{File.dirname(@file)}"
      end

      r.is do
        # GET /posts?file=truc request
        # edit the truc post
        r.get do
          @file = r.params['file']

          content_file = File.read(@file)
          @headers = App.extract_header(content_file)
          @content = File.read(@file).gsub(/---(.*?)---/m, "")

          # for page
          if @headers.empty?
            r.redirect "/files/edit?dir_path=#{r.params['dir_path']}&file=#{@file}"
          else
            @new_record = @file.empty?
            view("posts/edit")
          end
        end

        # POST /posts?file=truc request
        # save the truc post
        r.post do
          @file = r.params.delete('file') # in a route (new record : empty ELSE old filename)
          @content = r.params.delete('content')
          @filename = r.params.delete('filename')
          @tags = r.params.delete('tags')
          @date = r.params.delete('date')
          @meta = r.params.delete('meta')
          @format = r.params.delete('format')
          @publish = r.params.delete('publish')
          @layout = r.params.delete('layout')
          @title = r.params.delete('title')
          @new_file = r.params.delete('new_file') # form (new record : empty ELSE new filename)

          #$stderr.puts "---->"

          if @new_file.nil? || @new_file.empty?
            filename = App.urlize(@date, @title, (@type_file != 'pages'))
            @new_file = File.join(Dir.pwd,"_#{@type_file}", "#{filename}.#{@format}")
          end

          @headers = ['---']
          @headers << ['tags', @tags.split(',').map(&:strip).join(',')].join(': ')
          @headers << ['layout', @layout].join(': ')
          @headers << ['date', @date.to_s].join(': ')
          @headers << ['title', @title.to_s].join(': ')
          r.params.each do |k,v|
            if k.start_with?('header')
              @headers << [v.first, v.last.to_s].join(': ')
            else
              @headers << [k, v.to_s].join(': ')
            end
          end
          @headers << ['---']
          @headers << ['']

          File.open(@new_file, "w+") do |f|
            f.write(@headers.join("\n"))
            f.write(@content)
          end

          # Change path of file
          if !@file.to_s.empty? && @new_file.to_s != @file.to_s
            File.unlink(@file)
          end

          # publish : move draft to post
          if @publish == 'publish' && @new_file.to_s.include?('_drafts')
            FileUtils.mv(@new_file, @new_file.gsub('_drafts','_posts'))
          end

          r.redirect "/#{@type_file}/index?dir_path=#{File.dirname(@new_file)}"
        end
      end
    end
    end
  end
end

run App.freeze.app
