#!/bin/bash
#Script by me@rhsameera.com
set -e
# Define variables
sudoers_group="ENTER YOUR SUDO GROUP HERE"
Computer_OU="ENTER distinguished name (DN) OF YOUR OU" #Format in  distinguished name (DN) ou=myOU,dc=MyDomain
domain="Enter Your Domain Here"
Ssh_Allow="Enter the group to allow ssh acccess here" #This does not grant sudo access

# Detect OS release and version
source /etc/os-release
os_release=$NAME
os_version=$VERSION_ID

# Run realm discover command to get required packages
packages=$(realm discover $domain | grep 'package' | awk '{print $2}')

# Install required packages
if [[ -n $packages ]]; then
    sudo yum install -y $packages
	systemctl enable --now oddjobd.service
fi

# Prompt user for domain admin credentials
read -p "Enter your Active Directory domain admin username: " username

# Join to Active Directory using realm command and domain admin credentials
realm_join_output=$(sudo realm join --verbose --computer-ou=$Computer_OU $domain -U $username 2>&1)

# Check realm join status
if [[ $? -eq 0 ]]; then
    echo -e "\e[1;32mSuccess: This computer has joined the domain $JOIN_STATE.\e[0m"
else
    echo -e "\e[1;31mDomain joining was unsuccessful with error: $realm_join_output\e[0m"
    exit 1
fi

# Add a group using realm permit command
if sudo realm permit --groups $Ssh_Allow -R $domain; then
    echo "$Ssh_Allow group added to permit login successfully."
else
    echo "Failed to add Linux Admins group."
fi

# Set use_fully_qualified_names to False in sssd.conf file
if sudo sed -i 's/use_fully_qualified_names = .*/use_fully_qualified_names = False/' /etc/sssd/sssd.conf; then
    echo "use_fully_qualified_names set to False in sssd.conf."
else
    echo "Failed to set use_fully_qualified_names to False in sssd.conf."
fi

# Modify home directory settings in sssd.conf file
if sudo sed -i 's/\(override_homedir\|fallback_homedir\) = .*/\1 = \/home\/%u/' /etc/sssd/sssd.conf; then
    echo "Home directory settings modified successfully in sssd.conf."
else
    echo "Failed to modify home directory settings in sssd.conf."
fi

# Add override_homedir = /home/%u if it does not exist
if ! grep -q "^override_homedir = /home/%u" /etc/sssd/sssd.conf; then
    if sudo bash -c "echo -e \"override_homedir = /home/%u\" >> /etc/sssd/sssd.conf"; then
        echo "override_homedir added to [$domain] section in sssd.conf."
    else
        echo "Failed to add override_homedir to [$domain] section in sssd.conf."
    fi
else
    echo "override_homedir is already in place in [$domain] section."
fi
# Add override_shell = /bin/bash if it does not exist
if ! grep -q "^override_shell = /bin/bash" /etc/sssd/sssd.conf ; then
    if sudo bash -c "echo -e \"override_shell = /bin/bash\" >> /etc/sssd/sssd.conf"; then
        echo "override_shell added to [$domain] section in sssd.conf."
    else
        echo "Failed to add override_shell to [$domain] section in sssd.conf."
    fi
else
    echo "override_shell is already in place in [$domain] section."
fi
# Add ldap_user_extra_attrs = altSecurityIdentities if it does not exist
if ! grep -q "^ldap_user_extra_attrs = altSecurityIdentities" /etc/sssd/sssd.conf ; then
    if sudo bash -c "echo -e \"ldap_user_extra_attrs = altSecurityIdentities\" >> /etc/sssd/sssd.conf"; then
        echo "ldap_user_extra_attrs added to [$domain] section in sssd.conf."
    else
        echo "Failed to add ldap_user_extra_attrs to [$domain] section in sssd.conf."
    fi
else
    echo "ldap_user_extra_attrs is already in place in [$domain] section."
fi
# Add ldap_user_ssh_public_key = altSecurityIdentities if it does not exist
if ! grep -q "^ldap_user_ssh_public_key = altSecurityIdentities" /etc/sssd/sssd.conf ; then
    if sudo bash -c "echo -e \"ldap_user_ssh_public_key = altSecurityIdentities\" >> /etc/sssd/sssd.conf"; then
        echo "ldap_user_ssh_public_key added to [$domain] section in sssd.conf."
    else
        echo "Failed to add ldap_user_ssh_public_key to [$domain] section in sssd.conf."
    fi
else
    echo "ldap_user_ssh_public_key is already in place in [$domain] section."
fi
# Add AuthorizedKeysCommand /usr/bin/sss_ssh_authorizedkeys if it does not exist
if ! grep -q "^AuthorizedKeysCommand /usr/bin/sss_ssh_authorizedkeys" /etc/ssh/sshd_config ; then
    if sudo bash -c "echo -e \"AuthorizedKeysCommand /usr/bin/sss_ssh_authorizedkeys\" >> /etc/ssh/sshd_config"; then
        echo "AuthorizedKeysCommand added to [$domain] section in sshd_config."
    else
        echo "Failed to add AuthorizedKeysCommand to [$domain] section in sshd_config."
    fi
else
    echo "AuthorizedKeysCommand is already in place in [$domain] section."
fi
# Add AuthorizedKeysCommandUser root if it does not exist
if ! grep -q "^AuthorizedKeysCommandUser root" /etc/ssh/sshd_config ; then
    if sudo bash -c "echo -e \"AuthorizedKeysCommandUser root\" >> /etc/ssh/sshd_config"; then
        echo "AuthorizedKeysCommandUser added to [$domain] section in sshd_config."
    else
        echo "Failed to add AuthorizedKeysCommandUser to [$domain] section in sshd_config."
    fi
else
    echo "AuthorizedKeysCommandUser is already in place in [$domain] section."
fi
# Add sudores group to sudoers file if it doesn't exist
if ! grep -q "^%$sudoers_group" /etc/sudoers.d/sudoers; then
    if sudo bash -c 'echo "%'"$sudoers_group"' ALL=(ALL) ALL" >> /etc/sudoers.d/sudoers'; then
        echo "$sudoers_group added to sudoers file."
    else
        echo "Failed to add $sudoers_group to sudoers file."
    fi
else
	echo "$sudoers_group already in sudoers file."
fi
JOIN_STATE_OUTPUT=$(realm list)
JOIN_STATE=$(echo $JOIN_STATE_OUTPUT | grep "domain-name" | awk '{print $NF}')
# Check if the domain join state is empty and if not print realm list output and restart sssd,sshd services and reload systemd manager
if ! [ -z "$JOIN_STATE" ]; then
  echo -e "\e[1;32m$JOIN_STATE_OUTPUT \e[0m"
  systemctl restart sssd
  systemctl daemon-reload
  systemctl restart sshd
fi
