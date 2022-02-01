#!/bin/bash

kubectx #cluster-name

for cluster in $(kubectl config get-contexts --no-headers | awk '{print $1}' | egrep -i "prd-admin"| grep -v "\*" | egrep -iv \"cluster-prefix\")
do

    echo $cluster
    export cluster=$cluster
    kubectx $cluster
    kubectl delete pod nsenter -n monitoring
    export node=$(kubectl get pods -l app=prometheus -n monitoring -o wide --no-headers | awk '{print $7}')
    export pvc=$(kubectl get pvc -l app=prometheus -n monitoring --no-headers | awk '{print $3}')

    echo "Node: $node"
    echo "pvc: $pvc"

    cat nsenter.yaml| envsubst | kubectl apply -f -

    sleep 8

    kubectl cp podscript.sh nsenter:/ -n monitoring

    kubectl exec nsenter -n monitoring -- chmod +x podscript.sh
    kubectl exec nsenter -n monitoring -- bash podscript.sh

    if [[ $? -ne 0 ]];
    then 
        echo "$cluster falhou" >> erros.txt
        continue
    else
        kubectl delete pod nsenter -n monitoring 
        echo "Dados copiados do cluster $cluster"   
    fi        

done 

