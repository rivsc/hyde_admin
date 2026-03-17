require 'rack/test'

RSpec.describe "Create a draft", type: :system do
  include Rack::Test::Methods

  def app
    Mid
  end

  let(:tmpdir) { Dir.mktmpdir }
  let(:drafts_dir) { File.join(tmpdir, '_drafts') }
  let(:posts_dir) { File.join(tmpdir, '_posts') }
  let(:layouts_dir) { File.join(tmpdir, '_layouts') }

  before do
    FileUtils.mkdir_p(drafts_dir)
    FileUtils.mkdir_p(posts_dir)
    FileUtils.mkdir_p(layouts_dir)
    File.write(File.join(layouts_dir, 'post.html'), '<html>{{ content }}</html>')
    FileUtils.cp(File.join(File.dirname(__FILE__), '../../bin/hyde_admin.yml'), File.join(tmpdir, 'hyde_admin.yml'))

    allow(Dir).to receive(:pwd).and_return(tmpdir)
  end

  after do
    FileUtils.remove_entry(tmpdir)
  end

  it "creates a draft file in _drafts with date prefix" do
    post "/drafts", {
      file: "",
      title: "Work in progress",
      date: "2026-04-10 14:00:00 +0200",
      tags: "draft",
      layout: "post",
      format: "md",
      content: "This is still a draft.",
      new_file: ""
    }

    expect(last_response).to be_redirect

    created_files = Dir.glob(File.join(drafts_dir, '*.md'))
    expect(created_files.size).to eq(1)

    filename = File.basename(created_files.first)
    expect(filename).to eq("2026-04-10-work-in-progress.md")

    content = File.read(created_files.first)
    headers = Mid.extract_header(content)

    expect(headers['layout']).to eq("post")
    expect(headers['title']).to eq("Work in progress")

    body = Mid.remove_header(content)
    expect(body).to include("This is still a draft.")
  end

  it "publishes a draft by moving it to _posts" do
    post "/drafts", {
      file: "",
      title: "Ready to publish",
      date: "2026-04-10 14:00:00 +0200",
      tags: "news",
      layout: "post",
      format: "md",
      content: "This draft is ready.",
      publish: "publish",
      new_file: ""
    }

    expect(Dir.glob(File.join(drafts_dir, '*'))).to be_empty
    published_files = Dir.glob(File.join(posts_dir, '*.md'))
    expect(published_files.size).to eq(1)
    expect(File.basename(published_files.first)).to eq("2026-04-10-ready-to-publish.md")
  end
end
