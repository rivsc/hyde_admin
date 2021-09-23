# cat config.ru
# lancer avec rackup
require "roda"
require 'yaml'
require 'fileutils'
require 'i18n'
require 'date'

class App < Roda
  YML_FILE_NAME = "hyde_admin.yml"

  plugin :render,
    #escape: true, # Automatically escape output in erb templates using Erubi's escaping support
    views: File.join(File.expand_path(File.dirname(__FILE__)),'admin_views'), # Default views directory
    layout_opts: {template: 'admin_layout', engine: 'html.erb'},    # Default layout options
    template_opts: {default_encoding: 'UTF-8'} # Default template options

    plugin :i18n, translations: File.join(File.expand_path(File.dirname(__FILE__)), 'i18n') # gem 'roda-i18n'

    opts[:root] = Dir.pwd

    plugin :public, root: Dir.pwd #(begin "#{YAML.load(File.read(File.join(Dir.pwd, YML_FILE_NAME)))['path_to_jekyll_src']}/_site" rescue '' end) # permet de simuler le serveur jekyll

  # TODO load option (default_layout, deploy_dest_address, deploy_dest_path, path_to_jekyll_src, rsync_fullpath)
  # expliquer dans la doc le hyde.yml (voir une commande pour le prégénérer)

  def initialize(param)
    puts "============> #{Dir.pwd}"
    yml_in_current_dir = File.join(Dir.pwd, YML_FILE_NAME)
    yml_in_gem = File.expand_path(File.join(File.dirname(__FILE__), YML_FILE_NAME))

    puts yml_in_current_dir
    puts yml_in_gem

    # Generate default YML for hyde_admin
    if !File.exist?(yml_in_current_dir)
      puts "Make default YML"
      FileUtils.cp(yml_in_gem, yml_in_current_dir)
    end
    @hyde_parameters ||= YAML.load(File.read(yml_in_current_dir))
    super(param)
  end

  def self.urlize(date, title)
    I18n.config.available_locales = :en
    "#{Date.parse(@date).strftime('%Y-%m-%d')}-#{I18n.transliterate(@title).downcase.gsub(/[^a-zA-Z ]/,'').gsub(' ','-')}"
  end

  route do |r|
    # GET serve jekyll site
    r.public

    r.root do
      r.redirect "/dashboard"
    end

    r.on "overview" do
      r.redirect @hyde_parameters['site_index']
    end

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
      File.open("hyde.yml","w+") do |f|
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

run App.freeze.app
