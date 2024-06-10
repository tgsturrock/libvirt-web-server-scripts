# ele796-e23-lab1
Laboratoire 1 du cours ELE796 en Été 2024

## Description


## Configuration pour le serveur
En raison de difficultés avec virsh console, j'ai donc pivoté vers une connection ssh avec le serveur

Il faut donc configurer une connection ssh avec le serveur

ssh-copy-id tgs@192.168.122.203
mot de passe: 1234

Afin d'avoir une connection ssh facile et rapide avec le serveur je fais l'utilisation de SSH pass sur la machine hote

sudo apt-get install sshpass

Cependant, le fichier access.log est partager entre l'hote et le serveur.

## Configuration clients
Les client sont cloner a partir d'une image deja configurer avec un lancement automatique d'une connection vers le server.

Les fonctionnalitées du programme virsh et virt-clone sont utiliser pour traiter les VM clients.

Il n'y a pas de configuration du fichier xml en raison du fait que virt-clone s'occupe de dupliquer l'image en changeant les parametres d'identifications tel que l'addresse MAC, le nom de la VM et sont identifiant uuid.

De plus, DHCP est utiliser pour assigner des addresses IP de manière dynamique.

## Programme lab1.sh

Le programme s'execute en prenant pour acquis que le serveur est configurer et cree d'avance et ceci de meme pour le client de reference qui est cloner pour cree les 3 clients.

Le programme clone 3 VM, ensuite les allumes. les clients se connect ensuite automatiquement au serveur. Le programme attend ensuite que les clients soient completement operationnel puis les éteinds et les suprime. 

Par la suite, par ssh l'hote communique au server de copier le fichier d'access dans le dossier partager, dans le cas de l'hote c'est le dossier qui contient le programme.

Ensuite l'hote analyse les connections et génère un petit sommaire des acces.

Le tout est répété 3 fois.

Afin de lancer le programme il s'agit de se positionner dans le repertoire du programme et le lancer par commande ./lab1.sh.

## Notes

Parfois les addresses ip des client ne sont pas tous unique parce que'elles retiennent celle de la VM original. Cependant, la majorité du temps elles se configure pour etre unique. Le serveur ne semble pas etre derangé. À investiguer.

De plus, a quelques moments la 3ieme VM à etre cloner ne se suprime pas completement. c-a-d l'image ne se fait pas suprimer. C'est pour ceci que j'ai mi un court délai lors de la supression des VMs. 

 




#

#
