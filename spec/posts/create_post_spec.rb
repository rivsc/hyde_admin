require 'rack/test'

RSpec.describe "Create a post", type: :system do
  include Rack::Test::Methods

  def app
    Mid
  end

  let(:tmpdir) { Dir.mktmpdir }
  let(:posts_dir) { File.join(tmpdir, '_posts') }
  let(:layouts_dir) { File.join(tmpdir, '_layouts') }

  before do
    FileUtils.mkdir_p(posts_dir)
    FileUtils.mkdir_p(layouts_dir)
    File.write(File.join(layouts_dir, 'post.html'), '<html>{{ content }}</html>')
    File.write(File.join(layouts_dir, 'default.html'), '<html>{{ content }}</html>')
    FileUtils.cp(File.join(File.dirname(__FILE__), '../../bin/hyde_admin.yml'), File.join(tmpdir, 'hyde_admin.yml'))

    allow(Dir).to receive(:pwd).and_return(tmpdir)
  end

  after do
    FileUtils.remove_entry(tmpdir)
  end

  it "creates a post file with correct date, format, layout and content" do
    post "/posts", {
      file: "",
      title: "Mon premier article",
      date: "2026-03-17 10:30:00 +0100",
      tags: "ruby,jekyll",
      layout: "post",
      format: "md",
      content: "Ceci est le contenu de mon article.",
      new_file: ""
    }

    expect(last_response).to be_redirect

    created_files = Dir.glob(File.join(posts_dir, '*.md'))
    expect(created_files.size).to eq(1)

    filename = File.basename(created_files.first)
    expect(filename).to eq("2026-03-17-mon-premier-article.md")

    content = File.read(created_files.first)

    expect(content).to start_with("---\n")
    expect(content).to match(/^---\n.*^---$/m)

    headers = Mid.extract_header(content)

    expect(headers['date']).to eq("2026-03-17 10:30:00 +0100")
    expect(headers['layout']).to eq("post")
    expect(headers['title']).to eq("Mon premier article")
    expect(headers['tags']).to eq("ruby,jekyll")

    body = Mid.remove_header(content)
    expect(body).to include("Ceci est le contenu de mon article.")
  end

  it "creates a post in html format" do
    post "/posts", {
      file: "",
      title: "Article HTML",
      date: "2026-01-15 08:00:00 +0100",
      tags: "web",
      layout: "default",
      format: "html",
      content: "<p>Some HTML content</p>",
      new_file: ""
    }

    created_files = Dir.glob(File.join(posts_dir, '*.html'))
    expect(created_files.size).to eq(1)
    expect(File.basename(created_files.first)).to eq("2026-01-15-article-html.html")

    headers = Mid.extract_header(File.read(created_files.first))
    expect(headers['layout']).to eq("default")
  end

  it "creates a post with accented title" do
    post "/posts", {
      file: "",
      title: "Écrire un résumé",
      date: "2026-06-01 12:00:00 +0200",
      tags: "french",
      layout: "post",
      format: "md",
      content: "Some accented content.",
      new_file: ""
    }

    created_files = Dir.glob(File.join(posts_dir, '*.md'))
    expect(created_files.size).to eq(1)
    expect(File.basename(created_files.first)).to eq("2026-06-01-ecrire-un-resume.md")
  end
end
