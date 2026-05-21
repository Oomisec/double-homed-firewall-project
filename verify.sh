#!/bin/bash
# verify.sh — Automatiserat verifieringsskript (VG-nivå)
# Kör efter: vagrant up && bash /vagrant/setup_keys.sh && ansible-playbook

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

echo ""
echo "========================================"
echo " Double-homed Firewall — Verifieringsskript"
echo "========================================"
echo ""

echo "[1/5] Klient → webbserver (port 80, ska fungera)"
HTTP=$(vagrant ssh client -c \
  "curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 http://10.0.4.2" \
  2>/dev/null | tr -d '\r')
check "HTTP 200 från Apache" "$HTTP" "200"

echo "[2/5] Klient → databas direkt (port 5432, ska blockeras)"
BLOCKED=$(vagrant ssh client -c \
  "curl --connect-timeout 5 -s 10.0.3.2:5432 2>&1 | grep -c -i 'timeout\|refused\|timed out'" \
  2>/dev/null | tr -d '\r')
check "Anslutning blockeras av brandväggen" "$BLOCKED" "1"

echo "[3/5] Webbserver → databas (port 5432, ska fungera)"
DB=$(vagrant ssh webserver -c \
  "nc -zv 10.0.3.2 5432 2>&1 | grep -c succeeded" \
  2>/dev/null | tr -d '\r')
check "PostgreSQL nåbar från webbservern" "$DB" "1"

echo "[4/5] SSH-härdning — root-inloggning inaktiverad"
ROOT=$(vagrant ssh firewall -c \
  "grep -c 'PermitRootLogin no' /etc/ssh/sshd_config" \
  2>/dev/null | tr -d '\r')
check "PermitRootLogin no i sshd_config" "$ROOT" "1"

echo "[5/5] Brandvägg — FORWARD-policy är DROP"
POLICY=$(vagrant ssh firewall -c \
  "sudo iptables -L FORWARD | head -1 | grep -c 'DROP'" \
  2>/dev/null | tr -d '\r')
check "iptables FORWARD policy DROP" "$POLICY" "1"

echo "[6/9] Brandvägg — FW-DROP loggningsregel aktiv"
LOG=$(vagrant ssh firewall -c \
  "sudo iptables -L FORWARD | grep -c 'LOG'" \
  2>/dev/null | tr -d '\r')
check "FW-DROP loggningsregel aktiv" "$LOG" "1"

echo "[7/9] Health check — Apache körs på webbservern"
APACHE=$(vagrant ssh webserver -c \
  "systemctl is-active apache2" \
  2>/dev/null | tr -d '\r')
check "Apache är aktiv" "$APACHE" "active"

echo "[8/9] Health check — PostgreSQL körs på databasen"
POSTGRES=$(vagrant ssh database -c \
  "systemctl is-active postgresql" \
  2>/dev/null | tr -d '\r')
check "PostgreSQL är aktiv" "$POSTGRES" "active"

echo "[9/9] Health check — iptables är aktiv på brandväggen"
IPTABLES=$(vagrant ssh firewall -c \
  "sudo iptables -L FORWARD | grep -c 'ACCEPT'" \
  2>/dev/null | tr -d '\r')
check "iptables ACCEPT-regler aktiva" "$IPTABLES" "3"

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