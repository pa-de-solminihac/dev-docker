# dev-docker

Une image pour se faire une machine de dev

# Il y a quoi dans la boîte ?

Apache
MySQL (mariadb)
PHP
phpMyAdmin

Divers outils en ligne de commande avec une [configuration de base](https://github.com/pa-de-solminihac/configuration/) à emporter partout avec [sbash](https://github.com/pa-de-solminihac/configuration/#emporter-cette-configuration-partout)

- [sitesync](https://github.com/pa-de-solminihac/sitesync)
- [wp-cli](http://wp-cli.org/)
- [drush](http://www.drush.org/en/master/)
- wp-wned

## Dossiers montés

- www : les fichiers sources de vos sites
- database : contient les bases de données de Mysql (dossier monté sous `/var/lib/mysql`)
- log : fichiers logs des différents services (Apache access_log et error_log, PHP error_log, MySQL slow queries)
- vhosts : pour configurer des `<VirtualHost>` Apache supplémentaires
- conf-sitesync : fichiers de configuration à utiliser sous la forme `sitesync --conf=/sitesync/etc/...`


# Installation

```bash
git clone https://github.com/pa-de-solminihac/dev-docker
cd dev-docker
wget "http://quai2/devdocker.tar"
docker load -i devdocker.tar
```

# Configuration

```bash
cp sample/config etc/config
```

Puis réglez les variables selon votre installation.

`DOCKERSITE_ROOT` : doit pointer sur votre arborescence `dockersite`. Une arborescence vide est fournie dans ce dépôt comme point de départ.

**Remarque** : sous Windows, il faut impérativement que le dossier `dockersite` soit dans `C:\Users\...`


# Utilisation

```bash
# lancer l'environnement
./run.sh
```

Sous Linux, l'environnement expose MySQL sur le port 3306 et Apache sur le port 80. Il faut donc qu'ils soient disponibles. Sous Windows et OS X c'est masqué par le fait que l'environnement tourne dans une machine virtuelle Boot2docker.


# Requirements : Docker / Boot2docker

## Linux

Voir https://docs.docker.com/docker/installation/debian/

## Mac OS X

Voir https://docs.docker.com/docker/installation/mac/

## Windows

Voir https://docs.docker.com/docker/installation/windows/

Il faut faire une **Full install** de `boot2docker` (testé avec la version `1.7.1`)

Puis il faut retoucher la configuration de VirtualBox :

    Delete all boot2docker VM into Virtualbox (boot2docker delete)

    Go into File > Preferences > Network > Host-only Networks

    Delete all adapters in the list

    Add a new one (that's there the problem occur) it will output an error msg but will add it anyway. Just get out of the menu by clicking OK and go back in the menu right after, you'll see the new Ethernet Adapter in the list.

    Set the IPV4 address and network mask mentioned in the video
      IPV4 Address: 192.168.59.3
      IPV4 Mask: 255.255.255.0

    Enable the DHCP server and enter all 4 addresses mentioned in the video.
      Server Address: 192.168.59.99
      Server Mask: 255.255.255.0
      Lower address bound: 192.168.59.103
      Upper address bound: 192.168.59.254

    Click OK

    Double click on the Boot2Docker Start icon to reinitialize everything.


### Remarques supplémentaires

Sous windows, on ne peut monter que des sous-dossiers de `C:\Users\...`, sous la forme `/c/Users/...`


# Cheatsheet

```bash
# générer l'image
docker build -f devdocker/Dockerfile -t devdocker devdocker

# sauver l'image dans un fichier .tar
docker save -o devdocker.tar devdocker

# importer l'image (sur une autre machine par exemple) à partir du fichier .tar
docker load -i devdocker.tar

```
 
On lancera le conteneur ainsi :
```bash
DOCKERSITE_ROOT="/c/Users/...../path/to/dockersite" ./run.sh
```

