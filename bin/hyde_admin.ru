# cat config.ru
# lancer avec rackup
require "roda"
require 'yaml'
require 'fileutils'
require 'i18n'
require 'date'

# TODO roda-http-auth (set user/pass in yml)

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
  plugin :static, ['/mode', '/lib', '/fslightbox'], :root => File.join(File.expand_path(File.dirname(__FILE__)))

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

  def self.urlize(date_str, title)
    "#{Date.parse(date_str).strftime('%Y-%m-%d')}-#{self.transliterate_title_for_url(title)}"
  end

  route do |r|
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
      `cd #{Dir.pwd} && jekyll b && sleep 10`
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
      File.open(File.join(Dir.pwd, "hyde_admin.yml"),"w+") do |f|
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
        @files = Dir[File.join(@dir_path, '*')].sort.reverse
        view("browse")
      end

      # Upload files
      r.post "create" do
        files = [r.params['files']].flatten # 1 or more files
        files.each do |file|
          File.open(File.join(@dir_path, file.filename)) do |f|
            f.write(file.read)
          end
        end
        r.redirect "/files/index?dir_path=#{@dir_path}"
      end

      # Create directory
      r.post "create_dir" do
        Dir.mkdir(File.join(@dir_path, r.params['directory_name']))
        r.redirect "/files/index?dir_path=#{@dir_path}"
      end

      # Edit text files
      r.get "edit" do
        @file = r.params['file']
        @content = File.read(@file)
        view("edit_text_file")
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
        new_path = path.gsub(/\d{4}-\d{2}-\d{2}-/, date.strftime("%Y-%m-%d-"))
        response.write(new_path)
      end
      r.post "update_path_title" do
        path = r.params['path']
        title = r.params['title']
        I18n.config.available_locales = :en
        new_path = path.gsub(/(\d{4}-\d{2}-\d{2}-)(.*)(\.[^.]*)$/, "\\1#{App.transliterate_title_for_url(title)}\\3")
        response.write(new_path)
      end
      r.post "update_date_today" do
        date = Time.now.strftime('%Y-%m-%d %H:%M:%S %z')
        response.write(date)
      end
    end

    # Posts/pages/drafts
    r.on /posts|pages|drafts/ do
      # Set variable for all routes in /hello branch
      @type_file = r.matched_path.split('/').compact.select{ |elt| elt != '' }.first

      # GET /posts/index request
      # list all posts...
      r.get "index" do
        @files = Dir[File.join(Dir.pwd, "_#{@type_file}", '*')].sort.reverse
        view("listing")
      end

      r.get "new" do
        @file = ""
        @headers = {}
        view("edit")
      end

      r.is do
        # GET /posts?file=truc request
        # edit the truc post
        r.get do
          @file = r.params['file']

          content_file = File.read(@file)
          @headers = content_file.scan(/---(.*?)---/m).flatten.first.split("\n")
          @headers = @headers.select{ |header| !header.empty? }.map{ |header| header.scan(/([a-zA-Z]*): (.*)/).flatten }
          pp @headers
          @headers = Hash[@headers]
          @content = File.read(@file).gsub(/---(.*?)---/m, "")
          
          view("edit")
        end

        # POST /posts?file=truc request
        # save the truc post
        r.post do
          @file = r.params['file']
          @content = r.params['content']
          @filename = r.params['filename']
          @tags = r.params['tags']
          @content = r.params['content']
          @date = r.params['date']
          @meta = r.params['meta']
          @format = r.params['format'] # TODO default format (md/html)
          @publish = r.params['publish']
          @layout = r.params['layout']
          @title = r.params['title']

          if @file.nil? || @file.empty?
            filename = App.urlize(@date, @title)
            @file = File.join(Dir.pwd,"_#{@type_file}", "#{filename}.#{@format}")
          end

          @headers = ['---']
          @headers << ['tags', @tags.join(',')].join(': ')
          @headers << ['layout', @layout].join(': ')
          @headers << ['date', @date.to_s].join(': ')
          #@headers << ['meta', @tags.join(',')].join(': ')
          @headers << ['---']

          File.open(File.join(Dir.pwd, @file), "w+") do |f|
            f.write(@headers.join("\n"))
            f.write(@content)
          end
        end

        # POST /posts/delete?file=truc request
        # save the truc post
        r.post "delete" do
          @file = r.params['file']
          File.unlink(File.join(Dir.pwd, @file))
        end
      end
    end
    end
  end
end

run App.freeze.app
