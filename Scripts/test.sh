#!/bin/bash

# Test script for macOS App
# This script runs all tests and generates coverage reports

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
TEST_RESULTS_DIR="${PROJECT_DIR}/test-results"

echo -e "${BLUE}🧪 Running tests for MacOS App${NC}"

# Clean previous test results
echo -e "${YELLOW}🧹 Cleaning previous test results...${NC}"
rm -rf "${TEST_RESULTS_DIR}"
mkdir -p "${TEST_RESULTS_DIR}"

# Change to project directory
cd "${PROJECT_DIR}"

# Run swift tests with coverage
echo -e "${YELLOW}🚀 Running Swift tests...${NC}"
swift test --enable-code-coverage --build-path "${BUILD_DIR}" 2>&1 | tee "${TEST_RESULTS_DIR}/test-output.log"

# Check if tests passed
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    echo -e "${RED}Check ${TEST_RESULTS_DIR}/test-output.log for details${NC}"
    exit 1
fi

# Generate code coverage report if lcov is available
echo -e "${YELLOW}📊 Generating code coverage report...${NC}"
if command -v xcrun &> /dev/null; then
    # Find the profdata file
    PROFDATA_FILE=$(find "${BUILD_DIR}" -name "*.profdata" -type f | head -1)
    
    if [ -n "${PROFDATA_FILE}" ]; then
        # Find the test executable
        TEST_EXECUTABLE=$(find "${BUILD_DIR}" -name "*PackageTests.xctest" -type d | head -1)
        
        if [ -n "${TEST_EXECUTABLE}" ]; then
            BINARY_PATH="${TEST_EXECUTABLE}/Contents/MacOS/MacOSAppPackageTests"
            
            if [ -f "${BINARY_PATH}" ]; then
                echo -e "${BLUE}📈 Generating coverage report...${NC}"
                
                # Generate coverage report
                xcrun llvm-cov show "${BINARY_PATH}" \
                    -instr-profile="${PROFDATA_FILE}" \
                    -format=html \
                    -output-dir="${TEST_RESULTS_DIR}/coverage" \
                    -ignore-filename-regex=".build|Tests" \
                    2>/dev/null || echo -e "${YELLOW}⚠️ Could not generate HTML coverage report${NC}"
                
                # Generate coverage summary
                xcrun llvm-cov report "${BINARY_PATH}" \
                    -instr-profile="${PROFDATA_FILE}" \
                    -ignore-filename-regex=".build|Tests" \
                    > "${TEST_RESULTS_DIR}/coverage-summary.txt" \
                    2>/dev/null || echo -e "${YELLOW}⚠️ Could not generate coverage summary${NC}"
                
                if [ -f "${TEST_RESULTS_DIR}/coverage-summary.txt" ]; then
                    echo -e "${GREEN}📊 Coverage Summary:${NC}"
                    cat "${TEST_RESULTS_DIR}/coverage-summary.txt"
                    
                    # Extract overall coverage percentage
                    COVERAGE=$(tail -n 1 "${TEST_RESULTS_DIR}/coverage-summary.txt" | grep -o '[0-9]*\.[0-9]*%' | tail -1)
                    if [ -n "${COVERAGE}" ]; then
                        echo -e "${GREEN}🎯 Total Coverage: ${COVERAGE}${NC}"
                    fi
                fi
                
                if [ -d "${TEST_RESULTS_DIR}/coverage" ]; then
                    echo -e "${GREEN}📊 HTML coverage report generated: ${TEST_RESULTS_DIR}/coverage/index.html${NC}"
                fi
            fi
        fi
    else
        echo -e "${YELLOW}⚠️ No profdata file found. Run tests with --enable-code-coverage${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ xcrun not available, skipping coverage report${NC}"
fi

# Run additional static analysis if SwiftLint is available
echo -e "${YELLOW}🔍 Running static analysis...${NC}"
if command -v swiftlint &> /dev/null; then
    echo -e "${BLUE}🧹 Running SwiftLint...${NC}"
    swiftlint --reporter json > "${TEST_RESULTS_DIR}/swiftlint-results.json" 2>/dev/null || true
    swiftlint > "${TEST_RESULTS_DIR}/swiftlint-results.txt" 2>/dev/null || true
    
    if [ -f "${TEST_RESULTS_DIR}/swiftlint-results.txt" ]; then
        echo -e "${GREEN}✅ SwiftLint analysis complete${NC}"
        if [ -s "${TEST_RESULTS_DIR}/swiftlint-results.txt" ]; then
            echo -e "${YELLOW}⚠️ SwiftLint found issues:${NC}"
            cat "${TEST_RESULTS_DIR}/swiftlint-results.txt"
        else
            echo -e "${GREEN}✨ No SwiftLint issues found!${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️ SwiftLint not installed, skipping lint analysis${NC}"
    echo -e "${YELLOW}   Install with: brew install swiftlint${NC}"
fi

# Performance benchmarks (if available)
echo -e "${YELLOW}⚡ Running performance benchmarks...${NC}"
swift test --filter PerformanceTests --build-path "${BUILD_DIR}" 2>&1 | tee "${TEST_RESULTS_DIR}/performance-results.log"

# Generate test summary
echo -e "${YELLOW}📝 Generating test summary...${NC}"
cat > "${TEST_RESULTS_DIR}/test-summary.md" << EOF
# Test Summary

## Test Results
- **Status**: $(grep -q "❌" "${TEST_RESULTS_DIR}/test-output.log" && echo "FAILED" || echo "PASSED")
- **Date**: $(date)
- **Platform**: macOS $(sw_vers -productVersion)
- **Swift Version**: $(swift --version | head -1)

## Coverage
$([ -f "${TEST_RESULTS_DIR}/coverage-summary.txt" ] && cat "${TEST_RESULTS_DIR}/coverage-summary.txt" || echo "Coverage data not available")

## Static Analysis
$([ -f "${TEST_RESULTS_DIR}/swiftlint-results.txt" ] && ([ -s "${TEST_RESULTS_DIR}/swiftlint-results.txt" ] && echo "SwiftLint issues found - see swiftlint-results.txt" || echo "No SwiftLint issues found") || echo "SwiftLint analysis not performed")

## Performance
$([ -f "${TEST_RESULTS_DIR}/performance-results.log" ] && echo "Performance benchmarks completed - see performance-results.log" || echo "Performance benchmarks not available")

## Files Generated
- test-output.log: Complete test output
- coverage/: HTML coverage report (if available)
- coverage-summary.txt: Coverage summary
- swiftlint-results.txt: SwiftLint analysis results
- performance-results.log: Performance benchmark results
EOF

echo -e "${GREEN}✅ Test run completed!${NC}"
echo -e "${GREEN}📊 Results saved to: ${TEST_RESULTS_DIR}${NC}"

# Open coverage report if available
if [ -f "${TEST_RESULTS_DIR}/coverage/index.html" ]; then
    echo -e "${GREEN}🌐 Opening coverage report...${NC}"
    open "${TEST_RESULTS_DIR}/coverage/index.html" 2>/dev/null || true
fi

echo -e "${BLUE}📋 Test Summary:${NC}"
cat "${TEST_RESULTS_DIR}/test-summary.md"