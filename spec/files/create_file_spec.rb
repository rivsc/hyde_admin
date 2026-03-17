require 'rack/test'

RSpec.describe "Create files and directories", type: :system do
  include Rack::Test::Methods

  def app
    Mid
  end

  let(:tmpdir) { Dir.mktmpdir }

  before do
    FileUtils.cp(File.join(File.dirname(__FILE__), '../../bin/hyde_admin.yml'), File.join(tmpdir, 'hyde_admin.yml'))
    allow(Dir).to receive(:pwd).and_return(tmpdir)
  end

  after do
    FileUtils.remove_entry(tmpdir)
  end

  describe "directory creation" do
    it "creates a new directory" do
      post "/files/create_dir?dir_path=#{tmpdir}", {
        directory_name: "my_new_folder"
      }

      expect(last_response).to be_redirect

      new_dir = File.join(tmpdir, 'my_new_folder')
      expect(File.directory?(new_dir)).to be true
    end

    it "creates a nested directory inside an existing one" do
      parent = File.join(tmpdir, 'parent')
      FileUtils.mkdir_p(parent)

      post "/files/create_dir?dir_path=#{parent}", {
        directory_name: "child"
      }

      expect(File.directory?(File.join(parent, 'child'))).to be true
    end
  end

  describe "file creation" do
    it "creates an empty file" do
      post "/files/create_file?dir_path=#{tmpdir}", {
        file_name: "new_page.html"
      }

      expect(last_response).to be_redirect

      new_file = File.join(tmpdir, 'new_page.html')
      expect(File.exist?(new_file)).to be true
      expect(File.read(new_file)).to eq("")
    end

    it "creates a file inside a subdirectory" do
      subdir = File.join(tmpdir, 'assets')
      FileUtils.mkdir_p(subdir)

      post "/files/create_file?dir_path=#{subdir}", {
        file_name: "style.css"
      }

      new_file = File.join(subdir, 'style.css')
      expect(File.exist?(new_file)).to be true
    end
  end

  describe "file upload" do
    it "uploads a file" do
      tempfile = Tempfile.new(['upload', '.txt'])
      tempfile.write("file content here")
      tempfile.rewind

      uploaded_file = Rack::Test::UploadedFile.new(tempfile.path, "text/plain", false)

      post "/files/create?dir_path=#{tmpdir}", {
        files: uploaded_file
      }

      expect(last_response).to be_redirect

      uploaded = File.join(tmpdir, File.basename(tempfile.path))
      expect(File.exist?(uploaded)).to be true
      expect(File.read(uploaded)).to eq("file content here")

      tempfile.close!
    end
  end
end
