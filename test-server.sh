#!/bin/bash

# Test script for SwiftMCP HTTP+SSE server
# Usage: ./test-server.sh
#
# This script uses the simple /mcp endpoint (fallback mode)
# which returns responses directly in HTTP response bodies

set -e

HOST="http://192.168.1.47:8080"

echo "=== SwiftMCP Server Test ==="
echo ""
echo "Note: Using /mcp endpoint (simple mode - responses via HTTP)"
echo ""

# Helper function to send request and show response
send_request() {
    local description=$1
    local request_body=$2

    echo "$description"

    RESPONSE=$(curl -s -X POST "$HOST/mcp" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$request_body")

    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    echo ""
}

# Step 1: Initialize
send_request "Step 1: Initializing connection..." '{
    "jsonrpc": "2.0",
    "method": "initialize",
    "params": {
        "capabilities": {}
    },
    "id": 0
}'

# # Step 2: List resources
# send_request "Step 2: Listing available resources..." '{
#     "jsonrpc": "2.0",
#     "method": "resources/list",
# 	"id": 0
# }'
#
# # Step 3: List prompts
# send_request "Step 3: Listing available prompts..." '{
#     "jsonrpc": "2.0",
#     "method": "prompts/list",
# 	"id": 0
# }'

# # Step 2: Call getCurrentDateTime tool
# send_request "Step 2: Calling 'getCurrentDateTime' tool..." '{
#     "jsonrpc": "2.0",
#     "method": "tools/call",
#     "params": {
#         "name": "getCurrentDateTime",
#         "arguments": {}
#     },
#     "id": 2
# }'

# Step 3: Obfuscate a string using ROT13
echo "Step 3: Obfuscating 'wonderrush.ai'..."
OBFUSCATED=$(curl -s -X POST "$HOST/mcp" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "obfuscate",
            "arguments": {
                "text": "wonderrush.ai"
            }
        },
        "id": 3
    }')

echo "$OBFUSCATED" | python3 -m json.tool 2>/dev/null || echo "$OBFUSCATED"
echo ""

# Extract the obfuscated text from the response
OBFUSCATED_TEXT=$(echo "$OBFUSCATED" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('content', [{}])[0].get('text', ''))" 2>/dev/null)

# Step 4: Decode the obfuscated string
send_request "Step 4: Decoding '$OBFUSCATED_TEXT'..." "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"tools/call\",
    \"params\": {
        \"name\": \"decode\",
        \"arguments\": {
            \"text\": \"$OBFUSCATED_TEXT\"
        }
    },
    \"id\": 4
}"

# # Step 5: List tools
# send_request "Step 3: Listing available tools..." '{
#     "jsonrpc": "2.0",
#     "method": "tools/list",
# 	"id": 0
# }'
#
# # Step 4: Call add tool
# send_request "Step 4: Calling 'add' tool (10 + 20)..." '{
#     "jsonrpc": "2.0",
#     "method": "tools/call",
#     "params": {
#         "name": "add",
#         "arguments": {
#             "a": 10,
#             "b": 20
#         }
#     },
#     "id": 3
# }'
#
# # Step 5: Call multiply tool
# send_request "Step 5: Calling 'multiply' tool (3 * 13)..." '{
#     "jsonrpc": "2.0",
#     "method": "tools/call",
#     "params": {
#         "name": "multiply",
#         "arguments": {
#             "a": 3,
#             "b": 13
#         }
#     },
#     "id": 4
# }'
#
# # Step 6: List resources
# send_request "Step 6: Listing resources..." '{
#     "jsonrpc": "2.0",
#     "method": "resources/list",
#     "id": 5
# }'
#
# # Step 7: Call colorPrompt prompt
# send_request "Step 7: Calling 'colorPrompt' prompt (red)..." '{
#     "jsonrpc": "2.0",
#     "method": "prompts/get",
#     "params": {
#         "name": "colorPrompt",
#         "arguments": {
#             "color": "red"
#         }
#     },
#     "id": 7
# }'
# 
# echo "=== Test Complete ==="
# echo ""
# echo "For SSE mode (two-connection protocol), you would:"
# echo "1. Open SSE connection: curl -N $HOST/sse"
# echo "2. Get session ID from the 'data:' line"
# echo "3. Send requests to: $HOST/messages"
# echo "4. Receive responses via the SSE channel"
# echo ""
# echo "Note: SSE mode requires maintaining a persistent connection"
# echo "and is better suited for MCP client libraries than shell scripts."
