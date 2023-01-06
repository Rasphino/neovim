{
  description = "Rasphino's simple Neovim flake for easy configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-flake = {
      url = "github:neovim/neovim?dir=contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Theme
    "plugin:onedark-vim" = {
      url = "github:joshdick/onedark.vim";
      flake = false;
    };
    # Git
    "plugin:gitsigns" = {
      url = "github:lewis6991/gitsigns.nvim";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    # This line makes this package availeable for all systems
    # ("x86_64-linux", "aarch64-linux", "i686-linux", "x86_64-darwin",...)
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Once we add this overlay to our nixpkgs, we are able to
        # use `pkgs.neovimPlugins`, which is a map of our plugins.
        # Each input in the format:
        # ```
        # "plugin:yourPluginName" = {
        #   url   = "github:exampleAuthor/examplePlugin";
        #   flake = false;
        # };
        # ```
        # included in the `inputs` section is packaged to a (neo-)vim
        # plugin and can then be used via
        # ```
        # pkgs.neovimPlugins.yourPluginName
        # ```
        pluginOverlay = final: prev:
          let
            inherit (prev.vimUtils) buildVimPluginFrom2Nix;
            treesitterGrammars = prev.tree-sitter.withPlugins (_: prev.tree-sitter.allGrammars);
            plugins = builtins.filter
              (s: (builtins.match "plugin:.*" s) != null)
              (builtins.attrNames inputs);
            plugName = input:
              builtins.substring
                (builtins.stringLength "plugin:")
                (builtins.stringLength input)
                input;
            buildPlug = name: buildVimPluginFrom2Nix {
              pname = plugName name;
              version = "master";
              src = builtins.getAttr name inputs;

              # Tree-sitter fails for a variety of lang grammars unless using :TSUpdate
              # For now install imperatively
              #postPatch =
              #  if (name == "nvim-treesitter") then ''
              #    rm -r parser
              #    ln -s ${treesitterGrammars} parser
              #  '' else "";
            };
          in
          {
            neovimPlugins = builtins.listToAttrs (map
              (plugin: {
                name = plugName plugin;
                value = buildPlug plugin;
              })
              plugins);
          };

        # Apply the overlay and load nixpkgs as `pkgs`
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            pluginOverlay
            (final: prev: {
              neovim-unwrapped = inputs.neovim-flake.packages.${prev.system}.neovim;
            })
          ];
        };

        # neovimBuilder is a function that takes your prefered
        # configuration as input and just returns a version of
        # neovim where the default config was overwritten with your
        # config.
        # 
        # Parameters:
        # customRC | your init.vim as string
        # viAlias  | allow calling neovim using `vi`
        # vimAlias | allow calling neovim using `vim`
        # start    | The set of plugins to load on every startup
        #          | The list is in the form ["yourPluginName" "anotherPluginYouLike"];
        #          |
        #          | Important: The default is to load all plugins, if
        #          |            `start = [ "blabla" "blablabla" ]` is
        #          |            not passed as an argument to neovimBuilder!
        #          |
        #          | Make sure to add:
        #          | ```
        #          | "plugin:yourPluginName" = {
        #          |   url   = "github:exampleAuthor/examplePlugin";
        #          |   flake = false;
        #          | };
        #          | 
        #          | "plugin:anotherPluginYouLike" = {
        #          |   url   = "github:exampleAuthor/examplePlugin";
        #          |   flake = false;
        #          | };
        #          | ```
        #          | to your imports!
        # opt      | List of optional plugins to load only when 
        #          | explicitly loaded from inside neovim
        neovimBuilder = { customRC ? ""
                        , viAlias  ? true
                        , vimAlias ? true
                        , start    ? builtins.attrValues pkgs.neovimPlugins
                        , opt      ? []
                        , extraPackages ? []
                        , debug    ? false }:
                        let
                          myNeovimUnwrapped = pkgs.neovim-unwrapped.overrideAttrs (prev: {
                            propagatedBuildInputs = with pkgs; [ pkgs.stdenv.cc.cc.lib ];
                          });
                          extraMakeWrapperArgs = pkgs.lib.optionalString (extraPackages != [ ])
                            ''--suffix PATH : "${pkgs.lib.makeBinPath extraPackages}"'';
                        in
                        pkgs.wrapNeovim myNeovimUnwrapped {
                          inherit viAlias;
                          inherit vimAlias;
                          extraMakeWrapperArgs = extraMakeWrapperArgs;
                          configure = {
                            customRC = customRC;
                            packages.myVimPackage = with pkgs.neovimPlugins; {
                              start = start;
                              opt = opt;
                            };
                          };
                        };
      in
      rec {
        defaultApp = apps.nvim;
        defaultPackage = packages.neovimRasp;

        apps.nvim = {
            type = "app";
            program = "${defaultPackage}/bin/nvim";
          };

        packages.neovimRasp = neovimBuilder {
          # the next line loads a trivial example of a init.vim:
          customRC = "luafile ${./init.lua}";
          extraPackages = with pkgs; [
            python310 python310Packages.flake8 black
          ];
          # if you wish to only load the onedark-vim colorscheme:
          start = with pkgs.neovimPlugins; with pkgs.vimPlugins; [ 
            onedark-vim
            plenary-nvim
            nvim-autopairs
            comment-nvim
            nvim-ts-context-commentstring
            nvim-web-devicons
            nvim-tree-lua
            bufferline-nvim
            vim-bbye
            lualine-nvim
            toggleterm-nvim
            project-nvim
            impatient-nvim
            indent-blankline-nvim
            alpha-nvim
            # -- color schemes --
            tokyonight-nvim
            # darkplus-nvim
            # -- cmp --
            nvim-cmp
            cmp-buffer
            cmp-path
            cmp_luasnip
            cmp-nvim-lsp
            cmp-nvim-lua
            # -- snippets --
            luasnip
            friendly-snippets
            # -- LSP --
            nvim-lspconfig
            null-ls-nvim
            vim-illuminate
            # -- telescope --
            telescope-nvim
            # -- treesitter --
            nvim-treesitter
            nvim-treesitter-textobjects
            playground
            # -- git --
            gitsigns-nvim
            # -- dap --
            nvim-dap
            nvim-dap-ui
            # -- enhance paren matching --
            {
              plugin = vim-matchup;
              config = "let g:matchup_matchparen_offscreen = {'method': 'popup'}";
            }
            # -- rainbow paren --
            nvim-ts-rainbow
            nvim-surround
            lightspeed-nvim
            # -- language plusins --
            # {
            #   plugin = rust-tools-nvim;
            #   config = "let g:vscode_lldb_path = '${pkgs.vscode-extensions.vadimcn.vscode-lldb.outPath}'";
            # }
            rust-tools-nvim
            flutter-tools-nvim
          ];
        };
      }
    );
}

