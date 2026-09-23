{
  description = "macs - An opinionated emacs build + config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    emacs-overlay,
  }: let
    lib = nixpkgs.lib;
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAll = lib.genAttrs systems;

    mkMacs = pkgs: {
      config ? null,
      appendConfig ? null,
    }: let
      macs-pkgs = pkgs.extend emacs-overlay.overlays.default;
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

      emacs-minimal =
        (macs-pkgs.emacs.override {
          withMailutils = false;
          withSelinux = false;
          withDbus = false;
          withGpm = false;
          withSQLite3 = false;
          withSystemd = false;
          withXinput2 = false;
          withCsrc = false;
          withPgtk = !isDarwin;
          withNativeCompilation = false;
        })
            .overrideAttrs (old: {
          configureFlags =
            if isDarwin
            then [
              "--without-all"
              "--with-ns"
              "--with-png"
              "--with-jpeg"
              "--with-gif"
              "--with-tiff"
              "--with-rsvg"
              "--with-webp"
              "--with-tree-sitter"
              "--with-json"
              "--with-gnutls"
              "--with-zlib"
              "--with-modules"
            ]
            else [
              "--without-all"
              "--with-pgtk"
              "--with-png"
              "--with-jpeg"
              "--with-gif"
              "--with-tiff"
              "--with-rsvg"
              "--with-webp"
              "--with-tree-sitter"
              "--with-json"
              "--with-gnutls"
              "--with-xml2"
              "--with-zlib"
              "--with-modules"
              "--with-toolkit-scroll-bars"
            ];

          env = removeAttrs (old.env or {}) ["NATIVE_FULL_AOT"];
          buildInputs =
            old.buildInputs
            ++ (with pkgs; [zlib])
            ++ lib.optionals isDarwin (with pkgs; [libpng libjpeg giflib libtiff]);
        });

      sourcePath = name: value:
        if lib.isPath value
        then toString value
        else "${pkgs.writeText name value}";

      base =
        if config == null
        then "${./config/init.el}"
        else sourcePath "macs-base.el" config;

      extra =
        if appendConfig == null
        then null
        else sourcePath "macs-extra.el" appendConfig;

      emacs-config = pkgs.runCommand "emacs-config" {} ''
        target=$out/share/emacs/site-lisp
        mkdir -p $target
        ln -s ${base} $target/macs-base.el
        ${lib.optionalString (extra != null) "ln -s ${extra} $target/macs-extra.el"}
        cat > $target/default.el <<'MACS'
        ;;; -*- lexical-binding: t; -*-
        ;; macs: base config, then optional appended config.
        (load "macs-base")
        (load "macs-extra" t)
        MACS
        if [ -d ${./config/lisp} ]; then
          cp -r ${./config/lisp} $target/macs
        fi
      '';

      macs-epkgs = macs-pkgs.emacsPackagesFor emacs-minimal;
      macs = macs-epkgs.withPackages (_: [
        emacs-config

        # Melpa packages
        macs-epkgs.magit
        macs-epkgs.vterm
        macs-epkgs.corfu
        macs-epkgs.vertico
        macs-epkgs.orderless
        macs-epkgs.marginalia
        macs-epkgs.envrc
        macs-epkgs.catppuccin-theme
        macs-epkgs.cape
        macs-epkgs.yasnippet
        macs-epkgs.apheleia
        macs-epkgs.consult
        macs-epkgs.embark
        macs-epkgs.zoxide
        macs-epkgs.treemacs
        macs-epkgs.treemacs-nerd-icons
        macs-epkgs.nerd-icons
        macs-epkgs.nerd-icons-completion
        macs-epkgs.nerd-icons-dired

        pkgs.zoxide
        pkgs.ripgrep
        pkgs.fd
      ]);
    in
      macs;

    mkModule = install: {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.programs.macs;
      earlyInitSource =
        if cfg.earlyInit == null
        then ./config/early-init.el
        else if lib.isPath cfg.earlyInit
        then cfg.earlyInit
        else pkgs.writeText "macs-early-init.el" cfg.earlyInit;
    in {
      options.programs.macs = {
        enable = lib.mkEnableOption "macs, a minimal custom Emacs";

        package = lib.mkOption {
          type = lib.types.package;
          default = self.packages.${pkgs.system}.default;
          defaultText = lib.literalExpression "macs.packages.\${pkgs.system}.default";
          description = "The macs package to install.";
        };

        config = lib.mkOption {
          type = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
          default = null;
          example = lib.literalExpression "''(menu-bar-mode -1)''";
          description = ''
            Replace macs' default config. A path is symlinked, so edits are
            live (the path must be outside the flake source); a string of
            elisp is baked into the derivation.
          '';
        };

        appendConfig = lib.mkOption {
          type = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
          default = null;
          description = "Loaded after the base config. Same path/string semantics.";
        };

        earlyInit = lib.mkOption {
          type = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
          default = null;
          description = ''
            Content of ~/.emacs.d/early-init.el (home-manager only). Null uses
            macs' default, which loads the theme before the first frame to
            avoid a white flash. Paths are symlinked (live); strings are baked.
          '';
        };
      };

      config = lib.mkIf cfg.enable (
        install {
          package = cfg.package.override {
            inherit (cfg) config appendConfig;
          };
          inherit earlyInitSource;
        }
      );
    };
  in {
    packages = forAll (system: {
      default = lib.makeOverridable (mkMacs (import nixpkgs {inherit system;})) {};
    });

    overlays.default = final: prev: {
      macs = lib.makeOverridable (mkMacs final) {};
    };

    nixosModules.default = mkModule ({package, ...}: {
      environment.systemPackages = [package];
    });

    homeManagerModules.default = mkModule ({
      package,
      earlyInitSource,
    }: {
      home.packages = [package];
      home.file.".emacs.d/early-init.el".source = earlyInitSource;
    });

    apps = forAll (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/emacs";
      };
    });
  };
}
