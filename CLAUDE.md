# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zotero MCP is a Model Context Protocol (MCP) server that connects Zotero research libraries with AI assistants like Claude, Cherry Studio, and Cursor. It provides semantic search capabilities, annotation extraction, and comprehensive library access through both local and web APIs.

## Development Commands

### Testing and Linting
```bash
# Install dev dependencies if needed (they're in pyproject.toml optional-dependencies)
pip install -e ".[dev]"

# Code formatting
python -m black src/ --line-length 88
python -m isort src/ --profile black

# Testing - look for test files in the codebase or use pytest if available
pytest  # if test files exist
```

### Building and Installation
```bash
# Build the package
python -m build

# Install in development mode
pip install -e .

# Install from source
pip install git+https://github.com/54yyyu/zotero-mcp.git
```

### CLI Commands
The main entry point is `zotero-mcp` with subcommands:
- `zotero-mcp serve` - Run the MCP server (default)
- `zotero-mcp setup` - Configure for Claude Desktop
- `zotero-mcp update-db` - Update semantic search database
- `zotero-mcp db-status` - Show database status
- `zotero-mcp update` - Update to latest version
- `zotero-mcp version` - Show version info

## Code Architecture

### Core Modules
- **server.py** - FastMCP server with all MCP tools (~2000 lines)
- **client.py** - Zotero API wrapper and utilities
- **cli.py** - Command-line interface and argument parsing
- **semantic_search.py** - AI-powered semantic search using ChromaDB and embeddings
- **setup_helper.py** - Configuration setup for Claude Desktop
- **updater.py** - Smart update system that preserves configurations

### Key Features
- **Dual API Support**: Local Zotero API (via local=True) and Zotero Web API
- **Semantic Search**: ChromaDB with multiple embedding models (local, OpenAI, Gemini)
- **PDF Annotation Extraction**: Direct PDF processing with Better BibTeX integration
- **Smart Updates**: Detects installation method (uv, pip, conda, pipx) and preserves configs

### MCP Tools Structure
All tools in server.py follow the pattern:
```python
@mcp.tool(name="zotero_tool_name", description="...")
def tool_function(params, *, ctx: Context) -> str:
    # Returns markdown-formatted results
```

Major tool categories:
- Search tools (text, semantic, advanced, by tag)
- Content retrieval (metadata, full text, children)
- Library browsing (collections, tags, recent items)
- Annotation and notes management
- Semantic search database management

### Configuration System
- Environment variables for Zotero connection (ZOTERO_LOCAL, ZOTERO_API_KEY, etc.)
- Semantic search config in `~/.config/zotero-mcp/config.json`
- Claude Desktop integration via `claude_desktop_config.json`
- Auto-loading of environment variables from Claude config

### Dependencies
Key dependencies from pyproject.toml:
- **pyzotero**: Zotero API client
- **fastmcp**: MCP server framework
- **chromadb**: Vector database for semantic search
- **sentence-transformers**: Local embeddings
- **markitdown**: Document conversion to markdown
- **openai/google-genai**: External embedding providers

## Development Notes

- The codebase prioritizes backwards compatibility and configuration preservation
- Error handling is comprehensive with proper logging via FastMCP Context
- All user-facing output is markdown-formatted for readability
- The semantic search system supports auto-updates with configurable frequency
- Better BibTeX integration is optional but recommended for enhanced functionality

## Environment Variables

### Zotero Connection
- `ZOTERO_LOCAL=true` - Use local Zotero API (default for setup)
- `ZOTERO_API_KEY` - Web API key
- `ZOTERO_LIBRARY_ID` - Library identifier
- `ZOTERO_LIBRARY_TYPE` - "user" or "group"

### Semantic Search
- `ZOTERO_EMBEDDING_MODEL` - "default", "openai", or "gemini"
- `OPENAI_API_KEY` - For OpenAI embeddings
- `GEMINI_API_KEY` - For Gemini embeddings