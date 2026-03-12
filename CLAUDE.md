# Hyde Admin - CLAUDE.md

## Project Overview
Hyde Admin is a Ruby gem providing a web-based administration interface for Jekyll static sites. It allows managing pages, posts, drafts, files, images, and site configuration through a browser UI.

## Tech Stack
- **Language**: Ruby
- **Web framework**: Roda (lightweight Ruby web framework)
- **Server**: Puma (via Rack)
- **Templates**: ERB (in `bin/admin_views/`)
- **Frontend**: Bootstrap 5.3, jQuery 3.6, Font Awesome 5.15, CodeMirror (code editor), FSLightbox
- **Assets**: Served as static files (no asset pipeline), CDN for Bootstrap/jQuery/Font Awesome
- **Distribution**: Ruby gem (`hyde_admin.gemspec`)

## Project Structure
```
bin/
  hyde_admin.ru          # Main Roda application (routes, plugins, logic)
  hyde_admin             # CLI executable
  hyde_admin_config      # Config installer script
  admin_views/           # ERB templates
    admin_layout.html.erb  # Main layout (CDN links, sidebar, modals)
    partials/            # Reusable template fragments
  hyde_assets/           # Custom CSS (hyde_admin.css) and JS (hyde_admin.js)
  lib/                   # CodeMirror editor library
  mode/                  # CodeMirror language modes
  fslightbox/            # Lightbox library
  i18n/                  # Locale files (YAML)
  img/                   # Images (logo)
lib/
  hyde_admin/version.rb  # Gem version constant
```

## Key Commands
```bash
# Build the gem
gem build hyde_admin.gemspec

# Install locally
gem install hyde_admin-*.gem

# Run the admin server (from a Jekyll site directory)
hyde_admin

# Install/update config file
hyde_admin_config
```

## Development Notes
- All frontend dependencies (Bootstrap, jQuery, Font Awesome) are loaded via CDN in `admin_layout.html.erb`
- CodeMirror and FSLightbox are bundled locally in `bin/`
- The app uses `roda-i18n` for internationalization, locale files are in `bin/i18n/`
- Image upload uses `image_processing` + `mini_magick` for resizing
- Deployment uses rsync (configurable via `hyde_admin.yml`)
- No test suite currently exists
- Version is defined in `lib/hyde_admin/version.rb`
