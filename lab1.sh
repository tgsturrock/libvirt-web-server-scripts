#!/bin/bash

echo "Laboratoire 1- ELE796 Été 2022"

#Cette command vérifie s'il a des VMs existantes dans l"hôte
virsh list --all


#Cette commande dénombre des accès au serveur de chaque IP
grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" access.log | sort | uniq -c | sort>
