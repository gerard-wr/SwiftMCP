# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwiftMCP is a Swift implementation of the Model Context Protocol (MCP) for JSON-RPC communication over various transports. It enables building MCP servers that expose tools, resources, and prompts to AI clients.

**Key Capabilities:**
- Multiple transport options (stdio, HTTP+SSE)
- JSON-RPC 2.0 compliant with OpenAPI generation
- Built-in authorization and OAuth validation
- Transparent OAuth proxy mode
- Cross-platform compatibility (macOS, iOS, tvOS, watchOS, Catalyst)

## Build and Test Commands

```bash
# Build the project
swift build

# Run all tests
swift test

# Build and run the demo application
swift run SwiftMCPDemo

# Build for release
swift build -c release
```

## Running the Demo Server

The `SwiftMCPDemo` executable provides two transport modes:

```bash
# stdio mode (default) - for command-line integration
swift run SwiftMCPDemo stdio

# HTTP+SSE mode - for web/network integration
swift run SwiftMCPDemo httpsse --port 8080

# HTTP+SSE with authentication
swift run SwiftMCPDemo httpsse --port 8080 --token your-secret-token

# HTTP+SSE with OpenAPI support
swift run SwiftMCPDemo httpsse --port 8080 --openapi

# HTTP+SSE with OAuth
swift run SwiftMCPDemo httpsse --port 8080 \
    --oauth-issuer https://example.com \
    --oauth-token-endpoint https://example.com/oauth/token \
    --oauth-introspection-endpoint https://example.com/oauth/introspect \
    --oauth-jwks-endpoint https://example.com/.well-known/jwks.json \
    --oauth-audience your-api-identifier
```

## Architecture

### Core Components

**Macros Layer** (`Sources/SwiftMCPMacros/`)
- Swift macros that generate MCP server infrastructure at compile time
- `@MCPServer` - Marks a class/actor as an MCP server and generates JSON-RPC handling code
- `@MCPTool` - Exposes functions as callable tools with automatic parameter extraction and JSON schema generation
- `@MCPResource` - Exposes read-only data through URI templates with path/query parameter support
- `@MCPPrompt` - Defines prompts that can be called by clients
- Macros extract documentation comments to generate descriptions for tools and parameters

**Protocol Layer** (`Sources/SwiftMCP/Protocols/`)
- `MCPServer` - Core protocol for all MCP servers, provides JSON-RPC message handling
- `MCPToolProviding` - Protocol for servers that provide executable tools
- `MCPResourceProviding` - Protocol for servers that expose data resources
- `MCPPromptProviding` - Protocol for servers that provide prompts
- `MCPLoggingProviding` - Protocol for servers that support structured logging
- `MCPCompletionProviding` - Protocol for custom completion suggestions

**Transport Layer** (`Sources/SwiftMCP/Transport/`)
- `Transport` - Base protocol defining how messages are sent/received
- `StdioTransport` - Standard input/output transport for CLI integration
- `HTTPSSETransport` - HTTP + Server-Sent Events transport for web integration
- `Session` - Manages client session state, capabilities, and message handling
- `SessionManager` - Manages multiple concurrent sessions in HTTP mode
- `RequestContext` - Task-local context for progress notifications during tool execution

**Models Layer** (`Sources/SwiftMCP/Models/`)
- JSON-RPC message types (`JSONRPCMessage`)
- MCP-specific types (tools, resources, prompts, sampling)
- JSON Schema representation for OpenAPI generation
- Server and client capabilities negotiation

**OAuth Layer** (`Sources/SwiftMCP/Transport/OAuth/`)
- JWT token validation (both introspection and JWKS-based)
- OAuth configuration and transparent proxy mode
- Token storage and session management

### Request Flow

1. **HTTP Request** → `HTTPHandler` parses HTTP request
2. **Authorization** → Token validation via OAuth or custom handler
3. **Session Management** → `SessionManager` routes to appropriate `Session`
4. **JSON-RPC** → `MCPServer.handleMessage()` processes request
5. **Tool Execution** → Macro-generated wrapper calls actual tool function
6. **Response** → Result sent via SSE channel to client

### Macro Code Generation

When you annotate a type with `@MCPServer`, the macro generates:
- JSON-RPC method dispatching infrastructure
- Tool metadata from function signatures and doc comments
- JSON schema definitions for parameters
- Wrapper functions for type-safe argument extraction

## Key Implementation Details

**Session Context**
- `Session.current` provides task-local access to the current client session
- Use `RequestContext.current` to send progress notifications during tool execution
- Access client capabilities via `Session.current?.clientCapabilities`

**Error Handling**
- Tools can throw errors - they're automatically converted to JSON-RPC error responses
- `MCPServerError` for server-side errors
- `MCPResourceError` for resource access issues
- `JWTError` for OAuth validation failures

**Type Conversion**
- Parameters extracted from JSON-RPC requests are automatically converted to Swift types
- Date encoding uses ISO8601 with timezone
- Custom `SchemaRepresentable` protocol for complex types

**OAuth Integration**
- Supports both token introspection and JWT validation via JWKS
- Transparent proxy mode allows proxying encrypted JWE tokens
- Automatic user info fetching and session storage

## Testing Notes

- Tests use Swift Testing framework (migrated from XCTest)
- Test files are in `Tests/SwiftMCPTests/`
- Macro tests validate code generation output
- Integration tests verify end-to-end JSON-RPC flows

## Documentation

The project uses DocC for documentation:
- Documentation source: `Sources/SwiftMCP/SwiftMCP.docc/`
- Generate docs: `swift package generate-documentation`

## Dependencies

- **swift-nio** - Non-blocking network I/O for HTTP transport
- **swift-argument-parser** - CLI argument parsing for demo
- **swift-log** - Structured logging
- **swift-syntax** - Macro implementation
- **swift-crypto** / **swift-certificates** - JWT validation
- **AnyCodable** - Type-erased JSON encoding/decoding
