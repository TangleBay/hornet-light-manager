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

**Your Dashboard address will be `https://yourdomain.com` and your API (Trinity) will be `https://yourdomain.com/api`**


# Support #

IOTA Address: `KKEMSVOKRVEOARTKSYFM9ZNFEDDQUFGTFATYGRF9RXKBJGTUMGMDVPSLSZF9TRQXSASYAFTFEUNCQCHZYTDOQAUGDW`
