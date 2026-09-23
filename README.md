# macs

A minimal, opinionated Emacs 31 build and config, packaged as a Nix flake.

The Emacs binary and the Lisp config are built together into one derivation, so
the whole editor is reproducible. Features that a programming workflow does not
use (mail, systemd, dbus, sqlite, gpm, selinux, Xinput2) are compiled out, and
the UI is trimmed to a start screen, a file explorer, terminals, and LSP.

The flake is consumed as an input. It exposes a package, an overlay, a NixOS
module, and a home-manager module.

- GitHub: `github:h4rldev/macs`
- Codeberg: `git+https://codeberg.org/h4rl/macs`

## Usage

Add the flake as an input:

```nix
{
  inputs.macs.url = "github:h4rldev/macs";
}
```

NixOS:

```nix
{
  imports = [ inputs.macs.nixosModules.default ];
  programs.macs.enable = true;
}
```

home-manager:

```nix
{
  imports = [ inputs.macs.homeManagerModules.default ];
  programs.macs.enable = true;
}
```

Or use the overlay:

```nix
{
  nixpkgs.overlays = [ inputs.macs.overlays.default ];
  environment.systemPackages = [ pkgs.macs ];
}
```

`programs.macs` options:

| Option | Type | Default | Meaning |
| --- | --- | --- | --- |
| `enable` | bool | `false` | Install macs. |
| `package` | package | `macs.packages.<system>.default` | Which macs build to install. |
| `config` | path or string | `null` | Replace the default config. |
| `appendConfig` | path or string | `null` | Loaded after the base config. |
| `earlyInit` | path or string | `null` | `~/.emacs.d/early-init.el` (home-manager only). |

### path vs string

Both `config` and `appendConfig` accept a path or a string of elisp.

- A **string** is baked into the derivation. Editing it means editing the Nix
  expression and rebuilding.
- A **path** is symlinked. Editing the file's *contents* needs no rebuild
  because the symlink target is mutable. Editing the path itself (moving,
  renaming) is still a Nix change and needs a rebuild.
- A path **inside the flake source** is copied to the store, so it is not live.
  Point at a path outside the flake for realtime edits.

Example replacing the config with an inline string:

```nix
programs.macs.config = ''
  (menu-bar-mode -1)
'';
```

Example appending a live file that sits outside the flake:

```nix
programs.macs.appendConfig = /home/you/.config/macs/extra.el;
```

## Layout

- `config/early-init.el` - runs before the first frame; primes the theme
- `config/init.el` - entry point; requires every module in `config/lisp/`
- `config/lisp/macs-ui.el` - theme, chrome, scrolling, editing defaults, keys
- `config/lisp/macs-start.el` - the `*macs*` start screen
- `config/lisp/macs-completion.el` - completion, consult, embark, zoxide
- `config/lisp/macs-explorer.el` - treemacs
- `config/lisp/macs-terminals.el` - vterm (floating, vertical, horizontal)
- `config/lisp/macs-lsp.el` - eglot

## Config loading

Emacs loads the config in two stages.

- `config/early-init.el` is installed to `~/.emacs.d/early-init.el` by the
  home-manager module. It sets the theme before the first frame is drawn to
  avoid a white flash.
- `config/init.el` is installed as `share/emacs/site-lisp/default.el` and loads
  automatically. It requires the files in `config/lisp/`, which are copied to
  `site-lisp/macs/`.

Subdirectories of `config/lisp/` are not on `load-path` by default. Add them in
`init.el` if you split files further.

## Formatters

`apheleia-global-mode` formats on save using apheleia's built-in mode table
(python to black, nix to nixfmt, rust to rustfmt, and so on). The formatter
binary must be on `PATH`, either from the system profile or from a project dev
shell loaded through `envrc-global-mode`. Node formatters (prettier, biome,
oxfmt) go through the bundled `apheleia-npx` helper and need node or a project
local `node_modules/.bin`.

`M-x apheleia-format-buffer` formats on demand. `C-c F` is bound to it.

## Keybindings

Files and search:

| Key | Command |
| --- | --- |
| `C-x C-f` | find-file |
| `C-s` | consult-line |
| `C-x b` | consult-buffer |
| `C-c s` | consult-ripgrep |
| `C-c C-f` | consult-find |
| `C-c z` | zoxide-find-file |
| `C-c C-z` | zoxide-travel |
| `C-x d` | dired |
| `C-x g` | magit |

Projects and windows:

| Key | Command |
| --- | --- |
| `C-c e` | treemacs toggle |
| `C-c E` | treemacs focus |
| `C-c <left>` / `C-c <right>` | winner-undo / winner-redo |
| `C-x p f` / `C-x p b` / `C-x p k` | project find/buffer/kill |

Terminals:

| Key | Command |
| --- | --- |
| `C-c t f` | floating terminal toggle |
| `C-c t v` | vertical terminal toggle |
| `C-c t h` | horizontal terminal toggle |

Completion and context:

| Key | Command |
| --- | --- |
| `TAB` | complete at point (corfu) |
| `C-.` | embark-act |
| `C-;` | embark-dwim (alias `C-c w`) |

Editing helpers:

| Key | Command |
| --- | --- |
| `C-c l` | toggle relative/absolute line numbers |
| `C-c F` | apheleia-format-buffer |
| `C-c a` | eglot-code-actions |
| `C-c f` | eglot-format-buffer |
| `C-c r` | eglot-rename |

Start screen keys: `r` scan, `a` all/recent, `g` refresh, `q` quit, `RET` open
the project under point.

### Aliases for a Swedish keyboard

These replace bindings that need AltGr or Shift plus a number.

| Key | Command | Replaces |
| --- | --- | --- |
| `C-c q` | query-replace | `M-%` |
| `C-c Q` | query-replace-regexp | `C-M-%` |
| `C-c u` | undo | `C-/` |
| `C-c x` | shell-command | `M-!` |
| `C-c X` | shell-command-on-region | `M-|` |
| `C-c v` | eval-expression | `M-:` |
| `C-c w` | embark-dwim | `C-;` |
| `C-c p` / `C-c P` | backward/forward-paragraph | `M-{` / `M-}` |

## Start screen

`*macs*` shows the most recently edited projects (top 10 by newest file mtime),
each a clickable button with its path. `a` toggles the full list, `r` rescans
`macs-project-roots`, `g` redraws. Opening a project sets the working directory
and roots treemacs on it.

`macs-project-roots` auto-detects among `~/projects`, `~/Projects`, `~/code`,
`~/src`, `~/dev`, `~/repos`, and `~/git`, falling back to `~/projects`. The mtime
cache is persisted to `~/.emacs.d/macs-projects.eld` so the first paint is
already sorted.

## Notes

- The build targets native Wayland through PGTK on Linux, Cocoa (`--with-ns`)
  on Darwin.
- Native compilation is off; startup uses a high GC threshold while loading and
  restores it afterwards.
- `auto-save-file-name-transforms` and `backup-directory-alist` keep autosaves
  and backups in `~/.emacs.d`, out of your project trees.

## Licensing

The code is licensed under the BSD 3-Clause License - See [LICENSE](./LICENSE) for details.
