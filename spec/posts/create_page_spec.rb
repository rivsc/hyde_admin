require 'rack/test'

RSpec.describe "Create a page", type: :system do
  include Rack::Test::Methods

  def app
    Mid
  end

  let(:tmpdir) { Dir.mktmpdir }
  let(:pages_dir) { File.join(tmpdir, '_pages') }
  let(:layouts_dir) { File.join(tmpdir, '_layouts') }

  before do
    FileUtils.mkdir_p(pages_dir)
    FileUtils.mkdir_p(layouts_dir)
    File.write(File.join(layouts_dir, 'default.html'), '<html>{{ content }}</html>')
    FileUtils.cp(File.join(File.dirname(__FILE__), '../../bin/hyde_admin.yml'), File.join(tmpdir, 'hyde_admin.yml'))

    allow(Dir).to receive(:pwd).and_return(tmpdir)
  end

  after do
    FileUtils.remove_entry(tmpdir)
  end

  it "creates a page file without date prefix in filename" do
    post "/pages", {
      file: "",
      title: "About me",
      date: "2026-03-17 10:00:00 +0100",
      tags: "info",
      layout: "default",
      format: "html",
      content: "This is the about page.",
      new_file: ""
    }

    expect(last_response).to be_redirect

    created_files = Dir.glob(File.join(pages_dir, '*'))
    expect(created_files.size).to eq(1)

    filename = File.basename(created_files.first)
    expect(filename).to eq("about-me.html")
    expect(filename).not_to match(/^\d{4}-\d{2}-\d{2}/)

    content = File.read(created_files.first)
    headers = Mid.extract_header(content)

    expect(headers['layout']).to eq("default")
    expect(headers['title']).to eq("About me")
    expect(headers['date']).to eq("2026-03-17 10:00:00 +0100")

    body = Mid.remove_header(content)
    expect(body).to include("This is the about page.")
  end

  it "creates a page in markdown format" do
    post "/pages", {
      file: "",
      title: "Contact",
      date: "2026-05-01 09:00:00 +0200",
      tags: "",
      layout: "default",
      format: "md",
      content: "# Contact\n\nSend me an email.",
      new_file: ""
    }

    created_files = Dir.glob(File.join(pages_dir, '*.md'))
    expect(created_files.size).to eq(1)
    expect(File.basename(created_files.first)).to eq("contact.md")
  end
end
