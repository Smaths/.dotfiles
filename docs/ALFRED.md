# Alfred workflows

## Obsidian Search

Source: `config/alfred/workflows/obsidian-search/` (`info.plist` and `search.py`).
This is a copy of the installed **Obsidian Search** workflow, not an automatic
bootstrap link. It requires Alfred 5 with Powerpack, Obsidian at
`/Applications/Obsidian.app`, and macOS Spotlight indexing for the chosen vault.
The default folder is the Snarfum iCloud Obsidian vault.

To import on another Mac, package only the two source files at the archive root:

```sh
cd ~/.dotfiles/config/alfred/workflows/obsidian-search
package_dir=$(mktemp -d)
zip -q "$package_dir/Obsidian Search.alfredworkflow" info.plist search.py
open "$package_dir/Obsidian Search.alfredworkflow"
```

If the workflow is already installed, importing the same bundle ID can replace
its definition; review Alfred's import prompt before accepting. Nothing is
installed by `install/bootstrap.sh`.

In Alfred Preferences → Workflows → **Obsidian Search** → **Configure Workflow…**,
choose **Vault folder**. Type `o <part of a note filename>`, select a result,
and press Return to open it in Obsidian. Result subtitles show vault-relative
paths for notes with similar names. An empty query or no matches shows a
non-actionable hint. The search uses Spotlight's filename and Markdown content
type metadata (`net.daringfireball.markdown`), not note contents, aliases, or
headings. It has no Obsidian plugin or separate index. Alfred's native File
Filter was tried first, but its static scope does not resolve the workflow's
configurable vault folder; the Script Filter calls the built-in `mdfind` instead.
If a note is missing, check the selected vault folder, its iCloud availability,
Markdown type, and Alfred File Search Troubleshooting before changing Spotlight
index settings.

`prefs.plist` is intentionally not copied: Alfred stores the selected vault and
other per-machine values there. Do not commit it or link this source folder
into Alfred's live synced preferences. To refresh this backup after changing
the live workflow, compare and copy only reviewed `info.plist` and `search.py`.
