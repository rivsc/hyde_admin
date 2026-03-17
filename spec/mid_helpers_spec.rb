RSpec.describe Mid do
  describe ".transliterate_title_for_url" do
    it "converts a simple title to a URL-friendly slug" do
      expect(Mid.transliterate_title_for_url("Mon article")).to eq("mon-article")
    end

    it "removes trailing hyphens" do
      expect(Mid.transliterate_title_for_url("Mon fichier !")).to eq("mon-fichier")
    end

    it "removes leading and trailing spaces" do
      expect(Mid.transliterate_title_for_url("  Hello World  ")).to eq("hello-world")
    end

    it "collapses multiple spaces into a single hyphen" do
      expect(Mid.transliterate_title_for_url("Hello    World")).to eq("hello-world")
    end

    it "handles accented characters" do
      expect(Mid.transliterate_title_for_url("Écrire un résumé")).to eq("ecrire-un-resume")
    end

    it "preserves numbers" do
      expect(Mid.transliterate_title_for_url("Article 2026")).to eq("article-2026")
    end

    it "handles titles with only special characters" do
      expect(Mid.transliterate_title_for_url("!!!")).to eq("")
    end

    it "handles titles ending with special characters" do
      expect(Mid.transliterate_title_for_url("Mon titre...")).to eq("mon-titre")
    end

    it "removes punctuation" do
      expect(Mid.transliterate_title_for_url("Hello, World!")).to eq("hello-world")
    end
  end

  describe ".urlize" do
    it "generates a filename with date for posts" do
      expect(Mid.urlize("2026-03-17", "Mon article", true)).to eq("2026-03-17-mon-article")
    end

    it "generates a filename without date for pages" do
      expect(Mid.urlize("2026-03-17", "Ma page", false)).to eq("ma-page")
    end

    it "does not produce trailing hyphens" do
      result = Mid.urlize("2026-03-17", "Mon fichier !", true)
      expect(result).to eq("2026-03-17-mon-fichier")
      expect(result).not_to end_with("-")
    end
  end

  describe ".extract_header_str" do
    it "extracts YAML front matter" do
      content = "---\ntitle: Hello\nlayout: post\n---\nBody content"
      expect(Mid.extract_header_str(content)).to eq("\ntitle: Hello\nlayout: post\n")
    end

    it "returns nil when no front matter" do
      expect(Mid.extract_header_str("No front matter here")).to be_nil
    end
  end

  describe ".extract_header" do
    it "parses front matter into a hash" do
      content = "---\ntitle: Hello\nlayout: post\n---\nBody"
      result = Mid.extract_header(content)
      expect(result).to eq({ "title" => "Hello", "layout" => "post" })
    end

    it "returns empty hash for content without front matter" do
      expect(Mid.extract_header("No front matter")).to eq({})
    end
  end

  describe ".remove_header" do
    it "removes YAML front matter from content" do
      content = "---\ntitle: Hello\n---\nBody content"
      expect(Mid.remove_header(content).strip).to eq("Body content")
    end
  end

  describe ".extract_tags" do
    it "parses comma-separated tags" do
      expect(Mid.extract_tags("ruby,jekyll,web")).to eq(["ruby", "jekyll", "web"])
    end

    it "handles bracketed tags" do
      expect(Mid.extract_tags("[ruby,jekyll]")).to eq(["ruby", "jekyll"])
    end
  end

  describe ".safe_path?" do
    it "accepts paths within the working directory" do
      expect(Mid.safe_path?(File.join(Dir.pwd, "some_file.md"))).to be true
    end

    it "rejects paths outside the working directory" do
      expect(Mid.safe_path?("/etc/passwd")).to be false
    end
  end
end
