### Please note that you use this script at your own risk and that I will not be liable for any damages that may occur ###


# Hornet Lightwight Manager #

**Download the latest release version of the script and run it. Do the following steps:**

1. First you should clone the repo
```shell
cd /var/lib && sudo git clone https://github.com/TangleBay/hornet-light-manager.git && sudo chmod +x /var/lib/hornet-light-manager/hlm.sh
```
2. Set aliases for run hlm from every source
```shell
echo "alias hlm='sudo /var/lib/hornet-light-manager/hlm.sh'" >> ~/.bashrc && . ~/.bashrc
```
3. Run the Manager (HLM): `hlm`
4. With the first start it is necessary to edit the hornet config (will opened automatically) !!!


# Install reverse proxy #

**Before you can run the installation of the reverse proxy it is necessary that you have defined your domain in script before.**
**Also you need to open following ports in your router configuration: `80/TCP` (Letsencrypt-Auth)**

1. Set your domain over HLM in the nginx.cfg (Edit configuration -> nginx.cfg)
2. Choose the option "Installer Manager" and "3"
3. Enter your e-mail address for notifications from LetsEncrypt
4. Agree the terms with `A`
5. Choose `N` next
6. Select `1` for installing the certificate

**If you want to reach your node from an external IP (outside of your local network) you need to open the TCP port which is selected in the installer script (apiport).**
**Also if you want to reach you dashboard from an external IP (outside of your local network) you need to open the TCP port which is selected in the installer script (dashport).**


# IOTA Community Node Pool #

**I would be very happy if you would join the IOTA Community Node Pool so that together we can provide a strong and reliable node to the ecosystem and thus the Trinity users.**

**To add your node to the ICNP please follow these steps:**
1. Set your node name and pow option in the pool config over the HLM itself (icnp.cfg)
2. Choose the option "1" and add your node
3. You get now a password! Please copy the password and save it in the config.sh (and also write it down!).
4. You're done, welcome to the pool party!

**To remove your node from the ICNP please follow these steps:**
1. Set your password in the pool config over the HLM itself (icnp.cfg)
2. Choose the option "2"
3. If your node details shows up, your node was successfully removed.
4. Thank you very much for your participation in the ICNP!

**To udpdate your node on the ICNP please follow these steps:**
1. Set your donation address and make sure you have your password set in the pool config (icnp.cfg)
2. Choose the option "3"
3. If your node details shows up, your node was successfully updated.
4. Thank you very much for your participation in the ICNP!


# Support #

`CP9LDJQPBNRBRWWNPI9XSUSLCTWZEBG9NMANXDWDJHMFSHSBVRIWGKVOCFWVETVBWBAKOZURNZE9NSCGDWEZXAXSFW`
