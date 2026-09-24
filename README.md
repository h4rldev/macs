# macs

A minimal, opinionated Emacs 31 build and config, packaged as a Nix flake.

The Emacs binary and the Lisp config are built together into one derivation, so
the whole editor is reproducible. Features a programming workflow does not use
(mail, systemd, dbus, sqlite, gpm, selinux, Xinput2) are compiled out, and the
UI is trimmed to a start screen, a file explorer, tree-sitter, terminals, and
LSP.

The flake exposes a package, an overlay, a NixOS module, and a home-manager
module.

- GitHub: `github:h4rldev/macs`
- Codeberg: `git+https://codeberg.org/h4rl/macs`

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Table of Contents

- [Usage](#usage)
- [Options](#options)
- [Packages](#packages)
- [Layout](#layout)
- [Config loading](#config-loading)
- [Tree-sitter](#tree-sitter)
- [Snippets](#snippets)
- [Clipboard](#clipboard)
- [LSP and linting](#lsp-and-linting)
- [Formatters](#formatters)
- [Discord](#discord)
- [Keybindings](#keybindings)
  - [Aliases for a Swedish keyboard](#aliases-for-a-swedish-keyboard)
- [Start screen](#start-screen)
- [Notes](#notes)
- [Licensing](#licensing)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


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

## Options

`programs.macs` options, shared by both modules:

| Option | Type | Default | Meaning |
| --- | --- | --- | --- |
| `enable` | bool | `false` | Install macs. |
| `package` | package | `macs.packages.<system>.default` | Which macs build to install. |
| `config` | path or string | `null` | Replace the default config. |
| `appendConfig` | path or string | `null` | Loaded after the base config. |
| `earlyInit` | path or string | `null` | `~/.emacs.d/early-init.el` (home-manager only). |
| `packages` | list of package | `null` | Replace the default package list. |
| `appendPackages` | list of package | `[]` | Extra packages added to whichever list is used. |
| `discord` | bool | `false` | Discord Rich Presence via elcord. |

Both `config` and `appendConfig` take a path or a string of elisp.

- A **string** is baked into the derivation; editing it needs a rebuild.
- A **path** is symlinked, so editing the file's contents is live. Editing the
  path itself is still a Nix change. A path *inside the flake source* is copied
  to the store, so point outside the flake for live edits.

## Packages

macs ships a default set: magit, vertico/corfu/orderless/marginalia, consult,
embark, cape, yasnippet, apheleia, envrc, treemacs, vterm, the catppuccin theme,
`nix-ts-mode`, and the `ripgrep`, `fd`, `zoxide`, and `wl-clipboard` CLI tools.

`packages` replaces the whole list; the base config is always included, so
`packages = [];` still gives a working editor. `appendPackages` adds on top of
whichever list is used, and `discord` adds elcord.

## Layout

- `config/early-init.el` - runs before the first frame; primes the theme
- `config/init.el` - entry point; requires every module in `config/lisp/`
- `config/lisp/macs-ui.el` - theme, chrome, scrolling, editing defaults, keys
- `config/lisp/macs-start.el` - the `*macs*` start screen
- `config/lisp/macs-completion.el` - vertico, corfu, consult, embark, zoxide
- `config/lisp/macs-explorer.el` - treemacs
- `config/lisp/macs-terminals.el` - vterm (floating, vertical, horizontal)
- `config/lisp/macs-lsp.el` - eglot, flymake, elisp linting
- `config/lisp/macs-treesitter.el` - tree-sitter modes and grammar installs
- `config/lisp/macs-discord.el` - elcord presence (opt-in, no-op otherwise)
- `config/lisp/macs-clipboard.el` - `wl-copy` kill bridge for PGTK

## Config loading

- `config/early-init.el` is installed to `~/.emacs.d/early-init.el` by the
  home-manager module, so the theme is set before the first frame and there is
  no white flash.
- `config/init.el` is installed as `macs-base.el`, and a generated `default.el`
  loads it automatically (then any `appendConfig`). `config/lisp/` is copied to
  `site-lisp/macs/`.

## Tree-sitter

- `treesit-enabled-modes` is `t`, so a file opens in its `*-ts-mode` whenever a
  grammar is available.
- `treesit-auto-install-grammar` is `'ask`, so opening a language with no
  grammar asks to install it, then clones and compiles it into
  `~/.emacs.d/tree-sitter/`. Needs `git` and a C compiler on `PATH`; set it to
  `'always` for silent installs.
- Nix has no built-in tree-sitter mode, so `nix-ts-mode` is bundled and its
  grammar installs through the same prompt.

Grammars live outside the Nix store, so they survive rebuilds.
`M-x treesit-install-language-grammar` installs one manually.

## Snippets

`yasnippet` is on via `yas-global-mode`, backed by the `yasnippet-snippets`
collection (~one set per major mode). `~/.emacs.d/snippets` is searched first,
so your own override the bundled ones. Expand with `TAB` after a key, or use the
`C-c &` prefix (`C-c & i` inserts, `C-c & n` creates).

## Clipboard

With a PGTK (Wayland) build, Emacs' native clipboard write is unreliable: `M-w`
can report success while the system clipboard stays empty. macs routes kills
through `wl-copy` (`wl-clipboard` is in the default package list), which works
from both GUI and TTY frames. Pasting still uses Emacs' native reader, and where
`wl-copy` is not on `PATH` it falls back to the stock behaviour.

## LSP and linting

`eglot` autoconnects from `prog-mode` only when a server is known for the mode.
`flymake` runs in `emacs-lisp-mode` for byte-compile and checkdoc diagnostics.
Byte-compiling untrusted buffers is blocked; `M-x macs-trust-dir` trusts the
current project (or directory), persistently, and restarts flymake.

## Formatters

`apheleia-global-mode` formats on save using apheleia's built-in mode table
(python to black, nix to nixfmt, rust to rustfmt, and so on). The formatter
binary must be on `PATH`, from the system profile or a project dev shell loaded
through `envrc-global-mode`. Node formatters (prettier, biome, oxfmt) go through
the bundled `apheleia-npx` helper and need node or a project
`node_modules/.bin`. `C-c F` formats on demand.

## Discord

`programs.macs.discord = true;` adds [elcord](https://github.com/Mstrodl/elcord)
and turns on Rich Presence, using the major mode as the activity icon. Off by
default; `config/lisp/macs-discord.el` is a no-op without it.

## Keybindings

Keys macs adds or overrides. Stock Emacs bindings are left alone.

Files and search:

| Key | Command |
| --- | --- |
| `C-s` | consult-line |
| `C-x b` | consult-buffer |
| `C-c s` | consult-ripgrep |
| `C-c C-f` | consult-find |
| `C-c z` | zoxide-find-file |
| `C-c C-z` | zoxide-travel |

Projects and windows:

| Key | Command |
| --- | --- |
| `C-c e` | treemacs toggle |
| `C-c E` | treemacs focus |
| `C-c <left>` / `C-c <right>` | winner-undo / winner-redo |

Terminals (`C-c t` prefix, repeatable with `repeat-mode`):

| Key | Command |
| --- | --- |
| `C-c t f` | floating terminal toggle |
| `C-c t v` | vertical terminal toggle |
| `C-c t h` | horizontal terminal toggle |

Completion and context:

| Key | Command |
| --- | --- |
| `C-y` | accept the corfu candidate |
| `C-.` | embark-act |
| `C-;` | embark-dwim (alias `C-c w`) |

`RET` inserts a newline; `M-n` / `M-p` cycle candidates.

Editing:

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
each a clickable button with its path. Opening a project sets the working
directory and roots treemacs on it, expanded.

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
