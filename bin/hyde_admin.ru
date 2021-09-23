# cat config.ru
# lancer avec rackup
require "roda"
require 'yaml'

class App < Roda
  YML_FILE_NAME = "hyde_admin.yml"

  plugin :render,
    #escape: true, # Automatically escape output in erb templates using Erubi's escaping support
    views: 'admin_views', # Default views directory
    layout_opts: {template: 'admin_layout', engine: 'html.erb'},    # Default layout options
    template_opts: {default_encoding: 'UTF-8'} # Default template options

    plugin :i18n, translations: './i18n'  # gem 'roda-i18n'

    opts[:root] = Dir.pwd

    plugin :public, root: "#{YAML.load(File.read(YML_FILE_NAME))['path_to_jekyll_src']}/_site" # permet de simuler le serveur jekyll

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
      File.cp(yml_in_gem, yml_in_current_dir)
    end
    @hyde_parameters ||= YAML.load(File.read(yml_in_current_dir))
    super(param)
  end

  route do |r|
    # GET serve static blog (chercher l'url index.html dans le navigateur
    r.public

    r.root do
      r.redirect "/dashboard"
    end

    r.on "overview" do
      r.redirect @hyde_parameters['site_index']
    end
    
    # need to install jekyll (version bundlé avec le site
    r.on "rebuild" do
      puts @hyde_parameters['path_to_jekyll_src']
      `cd #{@hyde_parameters['path_to_jekyll_src']} && jekyll b && sleep 10`
      r.redirect "/dashboard"
    end

    r.on "deploy" do
      `#{@hyde_parameters['rsync_fullpath']} #{@hyde_parameters['path_to_jekyll_src']}/_site/ #{@hyde_parameters['deploy_dest_user']}@#{@hyde_parameters['deploy_dest_address']}:#{@hyde_parameters['deploy_dest_path']}`
      r.redirect "/dashboard"
    end

    r.on "configuration" do
      File.open("hyde.yml","w+") do |f|
        f.write(@hyde_parameters.to_yaml)
      end
      r.redirect "/dashboard"
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
        @files = Dir[File.join(@hyde_parameters['path_to_jekyll_src'], "_#{@type_file}", '*')].sort
        view("listing")
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
          @format = r.params['format']
          @publish = r.params['publish']
          @layout = r.params['layout']

          @headers = ['---']
          @headers << ['tags', @tags.join(',')].join(': ')
          @headers << ['layout', @layout].join(': ')
          @headers << ['date', @date.to_s].join(': ')
          #@headers << ['meta', @tags.join(',')].join(': ')
          @headers << ['---']

          File.open(File.join(@hyde_parameters['path_to_jekyll_src'], "#{@file}.#{@format}"), "w+") do |f|
            f.write(@headers.join("\n"))
            f.write("")
            f.write(content)
          end
        end

        # POST /posts/delete?file=truc request
        # save the truc post
        r.post "delete" do
          @file = r.params['file']
          File.unlink(File.join(@hyde_parameters['path_to_jekyll_src'],@file))
        end
      end
    end

    # TODO faire un jekyll serve
  end
end

run App.freeze.app
