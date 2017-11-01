# dev-docker : un environnement de développement web

Une image Docker pour se faire une machine de développement Linux, qu'on soit sous Windows, MacOS ou Linux

## Il y a quoi dans la boîte ?

Une plateforme LAMP : Linux (basé sur Debian Jessie) / Apache / MySQL (ou plutôt MariaDB) / PHP

Des outils pré-configurés : 
- le classique [phpMyAdmin](https://www.phpmyadmin.net/)
- [blackfire.io](https://blackfire.io/)
- [git](https://git-scm.com/)
- [composer](https://getcomposer.org/)
- [imagemagick](http://www.imagemagick.org/script/index.php) et de quoi recompresser efficacement les divers formats d'images ([jpeg-recompress](https://github.com/danielgtaylor/jpeg-archive), etc...)
- un [libreoffice](https://fr.libreoffice.org/) headless
- l'outil [certbot](https://certbot.eff.org/) du projet [Letsencrypt](https://letsencrypt.org/)
- [sitesync](https://github.com/pa-de-solminihac/sitesync)
- [wp-cli](http://wp-cli.org/)
- [drush](http://www.drush.org/en/master/)
- un [vim](http://www.vim.org) avec un config minimale mais portable au travers de connexions SSH
- divers outils en ligne de commande avec une [configuration de base](https://github.com/pa-de-solminihac/configuration/) à emporter partout avec [sbash](https://github.com/pa-de-solminihac/configuration/#emporter-cette-configuration-partout)
- etc... (mais ouvrez un ticket si vous voulez qu'on en rajoute)

## Dossiers montés

- `www` : les fichiers sources de vos sites
- `database` : contient les bases de données de Mysql (dossier monté sous `/var/lib/mysql`)
- `log` : fichiers logs des différents services (Apache access_log et error_log, PHP error_log, MySQL slow queries)
- `apache2` : pour rajouter de la config Apache, par exemple des `<VirtualHost>` supplémentaires
- `conf-sitesync` : fichiers de configuration à utiliser sous la forme `sitesync --conf=/sitesync/etc/...`
- `bashrc.d` : fichiers `.sh` à lancer à chaque fois que vous vous connectez (pour retrouver vos alias...)

# Installation

> **Pré-requis**
> Il faut [installer Docker](#pré-requis)
> Ne pas oublier de [permettre l'exécution de docker sans sudo](#permettre-lexécution-de-docker-sans-sudo)

L'installation se fait alors par un simple _git clone_ :
```bash
git clone https://github.com/pa-de-solminihac/dev-docker
cd dev-docker
```

# Configuration

```bash
cp sample/config etc/config
```

Puis réglez les variables selon votre installation.

`DOCKERSITE_ROOT` : doit pointer sur votre arborescence `dockersite`. Une arborescence vide est fournie dans ce dépôt comme point de départ, on peut par exemple la copier dans le dossier `/Users/$USER/dev`

```bash
cp -pr dockersite ~/dev
```

**Remarque** : sous Windows, il faut impérativement que le dossier `dockersite` soit dans `C:\Users\...`, et on doit spécifier son chemin sous la forme `/c/Users/...`


# Utilisation

## Lancer les services
```bash
./start.sh
```

## Couper les services
```bash
./stop.sh
```

## Remarque

Sous Linux, l'environnement expose MySQL sur le port 3306 et Apache sur le port 80. Il faut donc qu'ils soient disponibles. Sous Windows et OS X c'est masqué par le fait que l'environnement tourne dans une machine virtuelle Boot2docker.


# Pré-requis

Il vous faut une installation fonctionnelle de Docker

## Linux

C'est le cas le plus simple. Voir https://docs.docker.com/docker/installation/debian/

### Permettre l'exécution de docker sans sudo
```
sudo groupadd docker
sudo gpasswd -a ${USER} docker
# vous devrez vous déconnecter de votre session pour que cette modif soit prise en compte
```

## Mac OS X

On peut faire l'installation avec Homebrew
```
brew cask install docker-toolbox
```

### Amélioration des performances sous OSX

Pour OS X, les performances du partage de dossiers de VirtualBox étant médiocres, on va utiliser à la place un partage NFS.

Editer le fichier /etc/exports (avec sudo, penser à remplacer `UTILISATEUR` par votre nom d'utilisateur)

```bash
$ sudo vim /etc/export
/Users/UTILISATEUR/.ssh -alldirs -mapall=UTILISATEUR -network 192.168.99.0 -mask 255.255.255.0
/Users/UTILISATEUR/dev -alldirs -mapall=UTILISATEUR -network 192.168.99.0 -mask 255.255.255.0
```

Puis relancer le service `nfsd`

```bash
sudo nfsd checkexports && sudo nfsd -v -v -v restart && echo "NFS restarted" || echo "NFS error"
```

### Lancement au démarrage de la session

Voir [Démarrage automatique sous Mac OS X](https://github.com/pa-de-solminihac/dev-docker/wiki/D%C3%A9marrage-automatique-sous-Mac-OS-X) dans la [FAQ](https://github.com/pa-de-solminihac/dev-docker/wiki/)

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
