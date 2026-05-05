# 0.0.14

Security:
- Use YAML.safe_load instead of YAML.load
- Prevent path traversal on file operations
- Escape shell arguments in rebuild and deploy commands
- Escape HTML output in post/draft templates to prevent XSS

Features:
- Add preview & SFTP settings
- Add search, improved filenames for posts, UI improvements, autosave/recovery
- Add flash notice messages after rebuild, deploy and configuration save
- Add posts/drafts/pages counters to dashboard

Improvements:
- Remove jQuery dependency, use vanilla JS and fetch API
- Update Bootstrap from 5.1.1 to 5.3.8
- Update Font Awesome from 5.15.4 to 6.7.2
- Relax gem dependency version constraints

Bugfixes:
- Fix deploy/rebuild JS handler not working
- Fix image upload duplicate rename producing wrong filenames
- Frontmatter parser now supports keys with dashes and underscores
- Handle directory deletion safely in file browser
- Remove typo in french translation for previous_images

# 0.0.13

Add code highlighting

# 0.0.12

Add liquid code highlighter in wysiwyg editor
Add new option to maximize text editor

# 0.0.11

Add logo hyde admin
Increase image window size
Add dependency to avoid to set them in jekyll site gemfile

# 0.0.9

Hide deploy button if 'deploy_dest_address' is empty.
hyde_admin_config allow you to install the latest default config file.

# 0.0.8

Resize image at upload with ImageProcessing (MiniMagick)

# 0.0.7

Post edit : bugfix, keep layout & format when we don't show input.
CodeMirror editor : form-control style
Locales shows possible value for config.

# 0.0.6

Form upload image + style images selector
Menu follows workflow
Configuration remove beforeSend
Rsync params
Publish only for drafts

# 0.0.5

Sometimes no tags

# 0.0.4

Correct images selector
Some refactoring
Escape translations

# 0.0.3

Bugfix (see commits)

# 0.0.2

First usable version

# 0.0.1

PoC