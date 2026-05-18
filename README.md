# Double-homed Firewall Projekt

Nätverkssegmentering med en dedikerad brandvägg som kontrollerar all trafik mellan tre isolerade zoner.

## Arkitektur

![Nätverkstopologi](diagram.png)

## Krav

- VirtualBox
- Vagrant
- Ansible (installeras automatiskt via setup_keys.sh)

## Starta projektet

### 1. Starta alla VM:er
```bash
vagrant up
```

### 2. SSH in i brandväggen
```bash
vagrant ssh firewall
```

### 3. Kör setup och Ansible
```bash
bash /vagrant/setup_keys.sh
cd /vagrant/ansible
ansible-playbook -i inventory.ini playbook.yml
```

## Verifiera att allt fungerar

SSH in i klient-VM:en:
```bash
vagrant ssh client
```

Testa att klient når webbservern:
```bash
curl http://10.0.4.2
```

Testa att klient INTE når databasen:
```bash
curl --connect-timeout 5 http://10.0.3.2
```

## Säkerhetsåtgärder

| Åtgärd | Beskrivning |
|--------|-------------|
| Nätverkssegmentering | 3 isolerade zoner via VirtualBox intnet |
| Brandväggsregler | iptables med minsta privilegium |
| SSH-härdning | Root-inloggning inaktiverad, endast nyckelbaserad autentisering, MaxAuthTries 3 |

## Varför VirtualBox och inte containers (K4)

VirtualBox (hypervisor typ 2) valdes framför containers eftersom projektet kräver fullständig nätverksisolering mellan zoner. Containers delar kärna och är svårare att isolera på nätverksnivå. VirtualBox ger varje VM ett eget nätverksgränssnitt vilket möjliggör realistisk brandväggskonfiguration med iptables.

## Fördelar med virtualisering (F2)

- Isolerade miljöer — ett fel i en VM påverkar inte de andra
- Reproducerbar miljö — `vagrant up` ger identisk miljö varje gång
- Säker testmiljö — brandväggsregler kan testas utan risk för produktionsmiljön
- Kostnadseffektivt — flera isolerade servrar på en fysisk maskin

## Kvarvarande säkerhetsbrister (KO1)

| Brist | Risk | Åtgärd |
|-------|------|---------|
| Ingen loggning av brandväggsträffar | Attacker syns inte | Aktivera iptables LOG-regler |
| DNS ej härdad (8.8.8.8 hårdkodad) | DNS-spoofing möjlig | Intern DNS-server |
| Ingen kryptering mellan webbserver och databas | Avlyssning möjlig | TLS på PostgreSQL |




