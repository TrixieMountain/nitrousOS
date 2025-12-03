# nitrousOS Website

This branch contains the Hugo source for [www.nitrousos.com](https://www.nitrousos.com).

## Development

### Prerequisites

- [Hugo](https://gohugo.io/) (extended version)
- Or use Nix: `nix-shell -p hugo`

### Local Development

```bash
# Start development server
hugo server -D

# Visit http://localhost:1313
```

### Build

```bash
# Build static site
hugo --gc --minify

# Output in ./public/
```

## Deployment

### GitHub Pages

The site automatically deploys via GitHub Actions when pushing to the `www` branch.

Workflow: `.github/workflows/hugo.yml`

### Cloudflare Pages

1. Connect repository to Cloudflare Pages
2. Set build command: `hugo --gc --minify`
3. Set output directory: `public`
4. Set branch: `www`
5. Add custom domain: `www.nitrousos.com`

### DNS Configuration

For Cloudflare:
```
Type    Name    Content
CNAME   www     your-project.pages.dev
```

## Structure

```
www/
├── archetypes/        # Content templates
├── content/           # Markdown content
│   ├── docs/          # Documentation
│   ├── features/      # Features page
│   └── download/      # Download page
├── static/            # Static assets
│   ├── CNAME          # GitHub Pages domain
│   ├── _headers       # Cloudflare headers
│   └── _redirects     # Cloudflare redirects
├── themes/nitrous/    # Custom theme
│   ├── layouts/       # HTML templates
│   └── static/        # Theme assets
├── hugo.toml          # Hugo configuration
└── .github/workflows/ # CI/CD
```

## Adding Content

### New Documentation Page

```bash
hugo new docs/my-page.md
```

Edit the file and set `draft: false` when ready.

### Editing Existing Pages

All content is in `content/`. Edit the Markdown files directly.

## Theme

The site uses a custom theme (`themes/nitrous/`) designed for technical documentation with:

- Dark mode by default
- Responsive design
- Code syntax highlighting
- Mobile navigation

## License

Apache 2.0 - Same as the main nitrousOS project.
