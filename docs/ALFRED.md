# Alfred

Import files in `config/alfred/` manually; bootstrap does not install or link
them into Alfred's synced preferences.

## Obsidian Search

The workflow source is in `config/alfred/workflows/obsidian-search/`. It needs
Alfred 5 with Powerpack, Obsidian at `/Applications/Obsidian.app`, macOS
Spotlight indexing, and `/usr/bin/python3`. Its default vault is the Snarfum
iCloud Obsidian vault.

### Import

Package `info.plist` and `search.py` at the archive root, then open the package:

```sh
cd ~/.dotfiles/config/alfred/workflows/obsidian-search
package_dir=$(mktemp -d)
zip -q "$package_dir/Obsidian Search.alfredworkflow" info.plist search.py
open "$package_dir/Obsidian Search.alfredworkflow"
```

Review Alfred's prompt before replacing a workflow with the same bundle ID.
If `o` is taken, change the keyword rather than deleting the other workflow.

### Search

In Alfred Preferences, open Workflows → Obsidian Search → Configure Workflow
and choose **Vault folder**. Type `o <part of a note filename>`, select a result,
and press Return. Alfred opens the file in Obsidian without changing the
system-wide Markdown association. Result subtitles show vault-relative paths;
empty or unmatched queries show non-actionable hints.

The Script Filter calls macOS `mdfind` with the chosen folder and the Markdown
content type `net.daringfireball.markdown`. It searches filenames, not aliases,
headings, or note contents. There is no separate index or Obsidian plugin.
The Script Filter is needed because Alfred's File Filter cannot use the
configured vault folder.

If a note is missing, confirm the chosen folder, iCloud availability, and the
file's Markdown content type. Then use [Alfred File Search Troubleshooting](https://www.alfredapp.com/help/troubleshooting/indexing/)
to check Spotlight indexing. Do not rebuild the whole macOS index first.

### Keep the copy current

Alfred stores the selected vault in its live `prefs.plist`; the repository
ignores that file. After changing the live workflow, compare and copy only the
reviewed `info.plist` and `search.py` back into this folder. Do not link the
repository folder into Alfred's live synced preferences.

## Snarfum Industries theme

Open `config/alfred/snarfum-industries.alfredappearance` to import the theme.
Alfred keeps the installed copy in its synced preferences. To update the
repository copy after editing the theme in Alfred, export it and review the
replacement file before committing it.
