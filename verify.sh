#!/bin/bash
PASS=0
FAIL=0
ERRORS=()

check() {
  local desc=$1
  local result=$2
  local expected=$3
  if [ "$result" = "$expected" ]; then
    echo "  PASS  $desc"
    ((PASS++))
  else
    echo "  FAIL  $desc"
    echo "        Förväntade: '$expected' — fick: '$result'"
    ((FAIL++))
    ERRORS+=("$desc")
  fi
}

KEY_CLIENT=~/.ssh/vagrant_keys/client
KEY_WEB=~/.ssh/vagrant_keys/webserver
KEY_DB=~/.ssh/vagrant_keys/database
SSH_OPTS="-o StrictHostKeyChecking=no"

echo ""
echo "========================================"
echo " Double-homed Firewall — Verifieringsskript"
echo "========================================"
echo ""

echo "[1/9] Klient → webbserver (port 80, ska fungera)"
HTTP=$(ssh $SSH_OPTS -i $KEY_CLIENT vagrant@10.0.1.2 \
  "curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 http://10.0.4.2" \
  2>/dev/null | tr -d '\r')
check "HTTP 200 från Apache" "$HTTP" "200"

echo "[2/9] Klient → databas direkt (ska blockeras)"
BLOCKED=$(sudo dmesg | grep "FW-DROP" | grep "DST=10.0.3.2" | wc -l)
if [ "$BLOCKED" -gt "0" ]; then BLOCKED="1"; else BLOCKED="0"; fi
check "FW-DROP loggar blockerad trafik mot databasen" "$BLOCKED" "1"

echo "[3/9] Webbserver → databas (port 5432, ska fungera)"
DB=$(ssh $SSH_OPTS -i $KEY_WEB vagrant@10.0.4.2 \
  "nc -zv 10.0.3.2 5432 2>&1 | grep -c succeeded" \
  2>/dev/null | tr -d '\r')
check "PostgreSQL nåbar från webbservern" "$DB" "1"

echo "[4/9] SSH-härdning — root-inloggning inaktiverad"
ROOT=$(ssh $SSH_OPTS -i $KEY_CLIENT vagrant@10.0.1.2 \
  "grep -c 'PermitRootLogin no' /etc/ssh/sshd_config" \
  2>/dev/null | tr -d '\r')
check "PermitRootLogin no i sshd_config" "$ROOT" "1"

echo "[5/9] Brandvägg — FORWARD-policy är DROP"
POLICY=$(sudo iptables -L FORWARD | head -1 | grep -c 'DROP')
check "iptables FORWARD policy DROP" "$POLICY" "1"

echo "[6/9] Brandvägg — FW-DROP loggningsregel aktiv"
LOG=$(sudo iptables -L FORWARD | grep -c 'LOG')
check "FW-DROP loggningsregel aktiv" "$LOG" "1"

echo "[7/9] Health check — Apache körs på webbservern"
APACHE=$(ssh $SSH_OPTS -i $KEY_WEB vagrant@10.0.4.2 \
  "systemctl is-active apache2" \
  2>/dev/null | tr -d '\r')
check "Apache är aktiv" "$APACHE" "active"

echo "[8/9] Health check — PostgreSQL körs på databasen"
POSTGRES=$(ssh $SSH_OPTS -i $KEY_DB vagrant@10.0.3.2 \
  "systemctl is-active postgresql" \
  2>/dev/null | tr -d '\r')
check "PostgreSQL är aktiv" "$POSTGRES" "active"

echo "[9/9] Health check — iptables är aktiv på brandväggen"
IPTABLES=$(sudo iptables -L FORWARD | grep -c 'ACCEPT')
check "iptables ACCEPT-regler aktiva" "$IPTABLES" "4"

echo ""
echo "========================================"
if [ $FAIL -eq 0 ]; then
  echo " Resultat: $PASS/$((PASS+FAIL)) PASS — alla tester godkända"
else
  echo " Resultat: $PASS PASS, $FAIL FAIL"
  for e in "${ERRORS[@]}"; do
    echo "   - $e"
  done
fi
echo "========================================"
echo ""
[ $FAIL -eq 0 ] && exit 0 || exit 1