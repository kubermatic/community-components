# Active Directory Authentication for DEX

## Setup DEX Connector

Active Directory authentication works with the DEX LDAP connector as described in the [documentaion][1].
Add a connector of type ldap to in the dex connector object:

```
dex:
...
  connectors:
    - type: ldap
      name: ActiveDirectory
      id: ad
      config:
        host: "192.168.11.39:636"

        insecureNoSSL: false
        insecureSkipVerify: true

        bindDN: cn=Administrator,cn=users,dc=ad,dc=kubermatic,dc=dev
        bindPW: Test123

        usernamePrompt: Email Address

        userSearch:
          baseDN: cn=Users,dc=ad,dc=kubermatic,dc=dev
          filter: "(objectClass=person)"
          username: userPrincipalName
          idAttr: DN
          emailAttr: userPrincipalName
          nameAttr: cn

        groupSearch:
          baseDN: cn=Users,dc=ad,dc=kubermatic,dc=dev
          filter: "(objectClass=group)"
          userAttr: DN
          groupAttr: member
          nameAttr: cn
...
```

The requested userPrincipalName attribute contains the AD domain name. In this exampe user@ad.kubermatic.dev.
Authentication with the username only works with with querying the sAMAccountName attribute:

```
username: sAMAccountName
```
Change the usernamePrompt for this case.

## Setup Active Directory with Samba for Testing

Since version 4.0, Samba can take the Active Directory domain controller role. On an Ubuntu system, install Samba and Winbind:

```
sudo apt install samba winbind
```

Configure Samba for the domain controller role:
```
sudo rm /etc/samba/smb.conf
sudo samba-tool domain provision
```

Start Samba with the sufficient Systemd unit:
```
sudo systemctl disable smbd nmbd winbind
sudo systemctl stop smbd nmbd winbind
sudo systemctl unmask samba-ad-dc
sudo systemctl start samba-ad-dc
```

Add user:
```
sudo samba-tool user add myuser
```

[1]: https://github.com/dexidp/dex/blob/master/Documentation/connectors/ldap.md
