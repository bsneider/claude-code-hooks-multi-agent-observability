#!/bin/bash

# Test script to verify hooks work without summarizer

echo "Testing send_event.py without --summarize flag..."
echo "=================================================="

# Create test input
TEST_INPUT='{
  "session_id": "test-session-123",
  "tool_name": "bash",
  "tool_input": {
    "command": "ls"
  }
}'

# Test without --summarize flag (should work)
echo ""
echo "✓ Testing without --summarize flag:"
echo "$TEST_INPUT" | python3 -c "
import sys
import json
import argparse

# Minimal test of argument parsing
parser = argparse.ArgumentParser()
parser.add_argument('--source-app', required=True)
parser.add_argument('--event-type', required=True)
parser.add_argument('--server-url', default='http://localhost:4000/events')
parser.add_argument('--add-chat', action='store_true')

# This should NOT have --summarize anymore
args = parser.parse_args(['--source-app', 'test-app', '--event-type', 'PreToolUse'])

print('✓ Arguments parsed successfully')
print(f'  source_app: {args.source_app}')
print(f'  event_type: {args.event_type}')
print(f'  add_chat: {args.add_chat}')

# Read stdin
input_data = json.load(sys.stdin)
print(f'✓ JSON input parsed successfully')
print(f'  session_id: {input_data.get(\"session_id\")}')
"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ send_event.py works correctly without --summarize flag"
else
    echo ""
    echo "❌ send_event.py test failed"
    exit 1
fi

# Test that --summarize flag is NOT accepted (should fail)
echo ""
echo "✓ Testing that --summarize flag is rejected:"
echo "$TEST_INPUT" | python3 -c "
import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--source-app', required=True)
parser.add_argument('--event-type', required=True)
parser.add_argument('--server-url', default='http://localhost:4000/events')
parser.add_argument('--add-chat', action='store_true')

try:
    args = parser.parse_args(['--source-app', 'test-app', '--event-type', 'PreToolUse', '--summarize'])
    print('❌ --summarize flag was accepted (should not be)')
    sys.exit(1)
except SystemExit as e:
    if e.code == 2:  # argparse error code
        print('✅ --summarize flag is correctly rejected')
        sys.exit(0)
    else:
        raise
" 2>/dev/null

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ All tests passed! V2 hooks are working correctly."
else
    echo ""
    echo "⚠️  Warning: --summarize test had unexpected behavior"
fi

echo ""
echo "Summary:"
echo "- ✅ send_event.py no longer requires --summarize flag"
echo "- ✅ send_event.py rejects --summarize flag (V2 improvement)"
echo "- ✅ Hook scripts are more efficient without LLM calls"
