# dev-docker

Une image pour se faire une machine de dev


# Notes concernant l'installation sous Windows

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


## Remarques supplémentaires

Sous windows, on ne peut monter que des sous-dossiers de `C:\Users\...`, sous la forme `/c/Users/...`

On lancera le conteneur ainsi :
```bash
DOCKERSITE_ROOT="/c/Users/...../path/to/dockersite" ./run.sh
```


## Cheatsheet

```bash
# générer l'image
docker build -f devdocker/Dockerfile -t devdocker devdocker

# sauver l'image dans un fichier .tar
docker save -o devdocker.tar devdocker

# importer l'image (sur une autre machine par exemple) à partir du fichier .tar
docker load -i devdocker.tar

```
 
