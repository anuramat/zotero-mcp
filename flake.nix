{
  description = "Zotero MCP: Model Context Protocol server for Zotero research libraries";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python311;

        # Build missing Python packages from PyPI
        pyzotero = python.pkgs.buildPythonPackage rec {
          pname = "pyzotero";
          version = "1.6.11";
          format = "setuptools";

          src = python.pkgs.fetchPypi {
            inherit pname version;
            sha256 = "0x2pfgh466kl9w1iy3ax74ijg3xxx4c98nqjv1bk3bc8iy9zlwwp";
          };

          propagatedBuildInputs = with python.pkgs; [
            requests
            bibtexparser
            feedparser
            pytz
            httpx
          ];

          # Skip tests for now
          doCheck = false;

          meta = {
            description = "Python client for the Zotero API";
            homepage = "https://github.com/urschrei/pyzotero";
          };
        };

        fastmcp = python.pkgs.buildPythonPackage rec {
          pname = "fastmcp";
          version = "2.8.0";
          format = "wheel";

          src = python.pkgs.fetchPypi {
            inherit pname version;
            format = "wheel";
            python = "py3";
            abi = "none";
            platform = "any";
            sha256 = "034wjhyq6hzx41v9q3ggwnq4271lhcjxsj8z72rmmmdciplnh93p";
          };

          dependencies = with python.pkgs; [
            # Core MCP and validation
            mcp
            # CLI and UI
            rich
            typer
            # HTTP and async
            httpx
            # Authentication
            authlib
            # OpenAPI
            openapi-pydantic
            # Config
            python-dotenv
            # Compatibility
            exceptiongroup
          ];

          # Skip tests for now
          doCheck = false;

          meta = {
            description = "FastMCP - A fast, simple way to build MCP servers";
            homepage = "https://github.com/jlowin/fastmcp";
          };
        };

        # Main zotero-mcp package
        zotero-mcp = python.pkgs.buildPythonApplication rec {
          pname = "zotero-mcp";
          version = "0.1.0";

          meta.mainProgram = "zotero-mcp";

          src = ./.;
          format = "pyproject";

          # Build system dependencies
          build-system = with python.pkgs; [
            hatchling
          ];

          # Runtime dependencies - minimal for faster builds (excluding heavy ML deps)
          dependencies =
            with python.pkgs;
            [
              # Essential MCP and Zotero functionality
              mcp
              python-dotenv
              pydantic
              requests
              # markitdown excluded from minimal build due to heavy ML dependencies
            ]
            ++ [
              # Custom packages built from PyPI
              pyzotero
              fastmcp
            ];

          # Optional dependencies might include system packages for PDF processing
          buildInputs = with pkgs; [
            # Add any system dependencies needed for PDF processing, etc.
          ];

          # Development and test dependencies
          nativeCheckInputs = with python.pkgs; [
            pytest
            black
            isort
          ];

          # Skip tests and dependency checks for minimal build
          doCheck = false;
          dontCheckRuntimeDeps = true;

          # Install the CLI script
          postInstall = ''
            # The CLI is already handled by pyproject.toml [project.scripts]
          '';

          meta = {
            description = "Model Context Protocol server for Zotero research libraries";
            homepage = "https://github.com/54yyyu/zotero-mcp";
            license = pkgs.lib.licenses.mit;
            maintainers = [ ];
          };
        };

        # Full-featured package with all dependencies including ML/AI
        zotero-mcp-full = zotero-mcp.overrideAttrs (old: {
          propagatedBuildInputs =
            old.propagatedBuildInputs
            ++ (with python.pkgs; [
              # Semantic search capabilities (heavy ML dependencies)
              chromadb
              sentence-transformers
              # Document processing
              markitdown
              # AI integrations
              openai
              google-genai
            ]);
        });

      in
      {
        # Package variants
        packages = {
          default = zotero-mcp; # Minimal, fast build
          full = zotero-mcp-full; # All features including ML/AI
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = [
            python
            # Python development tools
            python.pkgs.pip
            python.pkgs.setuptools
            python.pkgs.wheel
            # Linting and formatting
            python.pkgs.black
            python.pkgs.isort
            python.pkgs.pytest
          ]
          ++ zotero-mcp.dependencies
          ++ zotero-mcp.build-system;

          # Environment variables for development
          shellHook = ''
            echo "🧠 Zotero MCP Development Environment"
            echo "📚 Available commands:"
            echo "  - zotero-mcp --help    (CLI interface)"
            echo "  - black src/           (format code)"
            echo "  - isort src/           (sort imports)"
            echo "  - pytest               (run tests if available)"
            echo ""
            echo "💡 Set environment variables for Zotero connection:"
            echo "  export ZOTERO_LOCAL=true           # for local Zotero"
            echo "  export ZOTERO_API_KEY=your_key     # for web API"
            echo "  export ZOTERO_LIBRARY_ID=your_id   # for web API"
            echo ""

            # Make the package available in development
            export PYTHONPATH="${zotero-mcp}/${python.sitePackages}:$PYTHONPATH"
          '';
        };

        # CLI application
        apps.default = {
          type = "app";
          program = "${zotero-mcp}/bin/zotero-mcp";
        };

        # Additional apps for specific commands (using wrapper scripts)
        apps.setup = {
          type = "app";
          program = "${pkgs.writeShellScript "zotero-mcp-setup" ''
            exec ${zotero-mcp}/bin/zotero-mcp setup "$@"
          ''}";
        };

        apps.serve = {
          type = "app";
          program = "${pkgs.writeShellScript "zotero-mcp-serve" ''
            exec ${zotero-mcp}/bin/zotero-mcp serve "$@"
          ''}";
        };

        # Checks - basic build verification
        checks = {
          build = zotero-mcp;

          # Format check
          format-check =
            pkgs.runCommand "format-check"
              {
                buildInputs = [
                  python.pkgs.black
                  python.pkgs.isort
                ];
              }
              ''
                cd ${self}
                black --check src/ || (echo "Code is not formatted with black" && exit 1)
                isort --check-only src/ || (echo "Imports are not sorted" && exit 1)
                touch $out
              '';
        };

        # Formatter for `nix fmt`
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
