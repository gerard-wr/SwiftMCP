# SwiftMCP Session Notes

## What We Did

1. **Created CLAUDE.md** - Comprehensive documentation file for future Claude Code instances
   - Location: `/Users/gerard/Library/Mobile Documents/com~apple~CloudDocs/Play/Wonderrush.ai/SwiftMCP/CLAUDE.md`
   - Contains architecture overview, build commands, and key implementation details

2. **Generated Documentation** - Built DocC documentation successfully
   - Command: `swift package generate-documentation`
   - Output: `.build/plugins/Swift-DocC/outputs/SwiftMCP.doccarchive`
   - View with: `open .build/plugins/Swift-DocC/outputs/SwiftMCP.doccarchive`
   - Or preview: `swift package --disable-sandbox preview-documentation --target SwiftMCP`

3. **Created Test Script** - Shell script to test the HTTP+SSE server
   - Location: `/Users/gerard/Library/Mobile Documents/com~apple~CloudDocs/Play/Wonderrush.ai/SwiftMCP/test-server.sh`
   - Made executable with `chmod +x`

## Key Discoveries

### Testing the Server with curl

**CRITICAL:** The endpoint is `/messages` (with 's'), not `/message`

**Working Commands:**

```bash
# Start the server
swift run SwiftMCPDemo httpsse --port 8080

# Terminal 2: Get session ID from SSE endpoint
curl -N http://localhost:8080/sse
# Output shows: id: <UUID>
# Copy this UUID, then Ctrl+C

# Terminal 3: Send requests (replace SESSION_ID with your UUID)
curl -X POST http://localhost:8080/messages \
  -H "Content-Type: application/json" \
  -H "X-Session-ID: SESSION_ID" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"curl","version":"1.0"}},"id":1}'

# List tools
curl -X POST http://localhost:8080/messages \
  -H "Content-Type: application/json" \
  -H "X-Session-ID: SESSION_ID" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}'

# Call a tool
curl -X POST http://localhost:8080/messages \
  -H "Content-Type: application/json" \
  -H "X-Session-ID: SESSION_ID" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"add","arguments":{"a":10,"b":20}},"id":3}'
```

### Available Endpoints (from HTTPHandler.swift)

- `GET /sse` - SSE connection (get session ID)
- `POST /messages` - Send JSON-RPC messages
- `GET /openapi.json` - OpenAPI spec (if --openapi flag used)
- `GET /.well-known/ai-plugin.json` - AI plugin manifest
- `GET /mcp` - Alternative SSE endpoint
- `POST /mcp` - Alternative message endpoint
- OAuth endpoints (if configured)

## Project Structure

### Main Components

- **Sources/SwiftMCP/** - Core library
  - `Protocols/` - MCPServer, MCPToolProviding, etc.
  - `Transport/` - StdioTransport, HTTPSSETransport
  - `Models/` - JSON-RPC types, tools, resources
  - `Extensions/` - Utility extensions
  - `Errors/` - Error types

- **Sources/SwiftMCPMacros/** - Macro implementations
  - `@MCPServer` - Marks class/actor as MCP server
  - `@MCPTool` - Exposes functions as tools
  - `@MCPResource` - Exposes data via URI templates
  - `@MCPPrompt` - Defines prompts

- **Demos/SwiftMCPDemo/** - Demo application
  - `DemoServer.swift` - Example server with tools

### Build Commands

```bash
# Build
swift build

# Test
swift test

# Run demo (stdio mode)
swift run SwiftMCPDemo stdio

# Run demo (HTTP+SSE mode)
swift run SwiftMCPDemo httpsse --port 8080
swift run SwiftMCPDemo httpsse --port 8080 --token my-secret
swift run SwiftMCPDemo httpsse --port 8080 --openapi
```

## Current State

- Server is running on port 8080 (PID 40492)
- Has active curl connections
- Documentation generated successfully
- Test script created but needs endpoint fix (`/messages` not `/message`)

## Swift Concepts Explained

### guard Keyword
- Early exit validation pattern
- Unwraps optionals that remain available in scope
- Must exit scope in else block (return, throw, break, continue)
- Makes "happy path" clear by handling errors upfront

Example:
```swift
guard let name = params["name"] as? String else {
    return .error("Missing name")
}
// name is now unwrapped and available here
```

## Next Steps After Reboot

1. Test the corrected curl commands with `/messages` endpoint
2. Verify the test script works (might need to fix timeout command for macOS)
3. Explore OpenAPI endpoint if needed: `swift run SwiftMCPDemo httpsse --port 8080 --openapi`

## Session 2: Fixed test-server.sh

### What We Did

1. **Fixed test-server.sh** - Complete rewrite to use `/mcp` fallback endpoint
   - **Problem**: Original script attempted SSE mode (two-connection protocol) which is complex in bash
   - **Solution**: Switched to `/mcp` endpoint which provides synchronous request-response
   - **Result**: Script now reliably tests all major SwiftMCP functionality

### Key Discovery: Two Transport Modes

The HTTP+SSE transport has **two distinct modes**:

1. **SSE Mode (Two-Connection Protocol)**
   - `GET /sse` - Establishes SSE connection, receives responses
   - `POST /messages` - Sends JSON-RPC requests
   - Responses come via SSE channel, NOT in HTTP response body
   - Complex to implement in shell scripts
   - Better suited for MCP client libraries

2. **Fallback Mode (Single Connection)** ⭐ **Used in test script**
   - `POST /mcp` - Send request, get response in HTTP body
   - Synchronous request-response pattern
   - Simple, reliable, perfect for testing
   - Requires `Accept: application/json` header

### Errors Fixed

1. **SSE Timeout**: Added `-m 2` timeout to prevent curl hanging
2. **Echo Syntax**: Fixed `echo $(VAR)` → `echo "$VAR"`
3. **Session ID Extraction**: Updated to handle new SSE format: `data: http://localhost:8080/messages/<UUID>`
4. **Empty Responses**: Discovered SSE mode sends responses via SSE channel, not HTTP body
5. **Missing Header**: Added required `Accept: application/json` header
6. **Protocol Complexity**: Final solution - switched from SSE mode to `/mcp` fallback endpoint

### Test Script Final Version

The script successfully tests:
- ✅ Initialize connection (protocol 2025-06-18)
- ✅ List tools (17 tools available)
- ✅ Call add tool (10 + 20 = 30)
- ✅ Call multiply tool (3 × 13 = 39)
- ✅ List resources (3 resources)

### Server Started

```bash
# Server running in background with logs
swift run SwiftMCPDemo httpsse --port 8080 > /tmp/swiftmcp-server.log 2>&1 &
# PID can be found with: lsof -i :8080
```

### Files Modified This Session

- `test-server.sh` - Complete rewrite to use `/mcp` endpoint (MAJOR CHANGES)

## Files Modified/Created Across All Sessions

- `/Users/gerard/Library/Mobile Documents/com~apple~CloudDocs/Play/Wonderrush.ai/SwiftMCP/CLAUDE.md` (Session 1 - NEW)
- `/Users/gerard/Library/Mobile Documents/com~apple~CloudDocs/Play/Wonderrush.ai/SwiftMCP/test-server.sh` (Session 1 - NEW, Session 2 - REWRITTEN)
- Documentation archives in `.build/plugins/Swift-DocC/outputs/`

## Token Usage

- Session 1: ~58k/200k (29%)
- Session 2: ~27k/200k (13%)
- Model: claude-sonnet-4-5-20250929
