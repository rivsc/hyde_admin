require 'rack/test'

RSpec.describe "Global search", type: :system do
  include Rack::Test::Methods

  def app
    Mid
  end

  let(:tmpdir) { Dir.mktmpdir }
  let(:posts_dir) { File.join(tmpdir, '_posts') }
  let(:pages_dir) { File.join(tmpdir, '_pages') }
  let(:drafts_dir) { File.join(tmpdir, '_drafts') }
  let(:layouts_dir) { File.join(tmpdir, '_layouts') }

  before do
    FileUtils.mkdir_p(posts_dir)
    FileUtils.mkdir_p(pages_dir)
    FileUtils.mkdir_p(drafts_dir)
    FileUtils.mkdir_p(layouts_dir)
    File.write(File.join(layouts_dir, 'default.html'), '<html>{{ content }}</html>')
    FileUtils.cp(File.join(File.dirname(__FILE__), '../../bin/hyde_admin.yml'), File.join(tmpdir, 'hyde_admin.yml'))

    File.write(File.join(posts_dir, '2026-03-17-hello-world.md'),
      "---\ntitle: Hello World\ntags: ruby,test\nlayout: default\n---\nThis is the body of hello world.")
    File.write(File.join(posts_dir, '2026-03-16-another-post.md'),
      "---\ntitle: Another Post\ntags: jekyll\nlayout: default\n---\nSomething else entirely.")
    File.write(File.join(pages_dir, 'about.html'),
      "---\ntitle: About Me\ntags: info\nlayout: default\n---\n<p>About page content</p>")
    File.write(File.join(drafts_dir, '2026-03-17-draft-idea.md'),
      "---\ntitle: Draft Idea\ntags: draft\nlayout: default\n---\nWork in progress content.")

    allow(Dir).to receive(:pwd).and_return(tmpdir)
  end

  after do
    FileUtils.remove_entry(tmpdir)
  end

  it "returns matching posts by title" do
    get "/search", q: "Hello"

    expect(last_response).to be_ok
    expect(last_response.body).to include("Hello World")
    expect(last_response.body).not_to include("Another Post")
  end

  it "returns matching posts by tag" do
    get "/search", q: "jekyll"

    expect(last_response).to be_ok
    expect(last_response.body).to include("Another Post")
    expect(last_response.body).not_to include("Hello World")
  end

  it "returns matching posts by body content" do
    get "/search", q: "entirely"

    expect(last_response).to be_ok
    expect(last_response.body).to include("Another Post")
  end

  it "searches across posts, pages and drafts" do
    get "/search", q: "content"

    expect(last_response).to be_ok
    expect(last_response.body).to include("About Me")
    expect(last_response.body).to include("Draft Idea")
  end

  it "searches case-insensitively" do
    get "/search", q: "hello"

    expect(last_response).to be_ok
    expect(last_response.body).to include("Hello World")
  end

  it "returns no results for unknown query" do
    get "/search", q: "zzzznotfound"

    expect(last_response).to be_ok
    expect(last_response.body).to include("0")
  end

  it "ignores queries shorter than 2 characters" do
    get "/search", q: "a"

    expect(last_response).to be_ok
    expect(last_response.body).not_to include("Hello World")
    expect(last_response.body).not_to include("About Me")
  end
end
