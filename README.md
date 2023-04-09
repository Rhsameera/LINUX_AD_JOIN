Join a Linux Server to Active Directory Domain
==============================================

This script automates the process of joining a Linux server to an Active Directory domain. It also configures the home directory settings and shell access for AD users on the Linux server.

Prerequisites
-------------

This script requires the following:

*   A Linux server running RHEL 7 or later, CentOS 7 or later, or Fedora 26 or later.
*   An Active Directory domain to join the server.
*   Domain administrator credentials with permission to join computers (Similar to Winows Machine)

How to use
----------

1.  Copy the `join-to-domain.sh` script to your Linux server.
    
2.  Make the script executable using the command `chmod +x join-to-domain.sh`.
    
3.  Open the script in a text editor and set the following variables according to your domain requirements:
    
    *   `sudoers_group`: The name of the AD group that will have sudo access on the Linux server.
    *   `Computer_OU`: The OU where the computer account will be created in AD.
    *   `domain`: The FQDN of the Active Directory domain.
    *   `Ssh_Allow`: The name of the AD group that will be allowed SSH access to the Linux server.
4.  Run the script using the command `sudo ./join-to-domain.sh`.

Use SSH Public Key authentication
---------------------------------

1.  Generate an SSH key pair on the local machine if you don't have one already. You can do this using the `ssh-keygen` command (Or you can use Puttygen).
    
2.  Copy the public key generated in step 1. You can do this by using the `cat` command to print the contents of the public key file and then copying the output (or copy from Puttygen Directly).
    
3.  Log in to the Active Directory server and open the Active Directory Users and Computers console.
    
4.  Locate the user account to which you want to add the SSH public key and right-click on it. Select "Properties" from the context menu.
    
5.  In the Properties dialog box, click on the "Attribute Editor" tab (If you can't see it make sure to enable Advanced Features by going to View &rarr; Advanced Features).
    
6.  In the Attribute Editor tab, scroll down and find the attribute "altSecurityIdentities". Double-click on it to open the Editor dialog box.
    
7.  In the Editor dialog box, click on the "Add" button.
    
8.  In the Add String dialog box, enter the following:
    
    Name: altSecurityIdentities Value: sshPublicKey <public-key>
    
    Replace `<public-key>` with the contents of the public key copied in step 2.
    
9.  Click on "OK" to close all dialog boxes.
    
10.  The SSH public key is now added to the user's altSecurityIdentities attribute in Active Directory. You can now use this key to log in to remote servers using SSH without the need for a password.

What it does
------------

1.  Detects the OS release and version.
2.  Runs the `realm discover` command to get the required packages and installs them using `yum`.
3.  Prompts the user for domain administrator credentials and joins the Linux server to the AD domain using the `realm join` command.
4.  Adds the `Ssh_Allow` group to the `sshd_config` file to allow SSH access for AD users.
5.  Configures the `sssd.conf` file to set the home directory and shell settings for AD users.
6.  Configures the `sssd.conf` file to allow the use of `altSecurityIdentities` as SSH public keys for AD users.
7.  Configures the `sshd_config` file to use the `sss_ssh_authorizedkeys` command to retrieve the SSH public keys of AD users.

To Do
------
1.  Make and test one for Debian, Ubuntu based OSs.
2.  Test it on ARM64 system
2.  Combine all to a python script so it can be executed anywhere. 
