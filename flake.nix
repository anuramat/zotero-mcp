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

          # Runtime dependencies - full package with all features
          dependencies =
            with python.pkgs;
            [
              # Essential MCP and Zotero functionality
              mcp
              python-dotenv
              pydantic
              requests
              # Semantic search capabilities (ML dependencies)
              chromadb
              sentence-transformers
              # Document processing
              markitdown
              # AI integrations
              openai
              google-genai
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

          # Skip tests and dependency checks for custom-built packages
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


      in
      {
        packages.default = zotero-mcp;
        apps.default = {
          type = "app";
          program = "${zotero-mcp}/bin/zotero-mcp";
        };
      }
    );
}
