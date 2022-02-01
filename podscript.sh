#!/bin/bash

start=1637452800
end=1638230340

echo "PVC: $pvc"

cd $(df -ha | grep $pvc | head -n1 |  awk '{print $6}')/prometheus-db
wget -O azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux && tar -xf azcopy_v10.tar.gz --strip-components=1
chmod +x azcopy
export AZCOPY_SPA_CLIENT_SECRET="KY87Q~_KpRqkWS3bmSn4RsReLc6XmL1bJ_p16"
./azcopy login --service-principal --application-id d1af1a0b-3793-4e2e-b079-178e3380dd9a --tenant-id 5a86b3fb-4213-49cd-b4d6-be91482ad3c0
mkdir -p $(df -ha | grep $pvc | head -n1 |  awk '{print $6}')/prometheus-db/bkp
mkdir -p $(df -ha | grep $pvc | head -n1 |  awk '{print $6}')/prometheus-db/bkp/$cluster

for dir in $( ls -d */ | egrep -iv "wal|chunks|bkp|snapshots"); do
   ts_min=$(head -n 5 $dir/meta.json| grep minTime | awk '{print $2}' | sed 's|,||g')
   ts_min=${ts_min::-3}
   ts_max=$(head -n 5 $dir/meta.json| grep maxTime | awk '{print $2}' | sed 's|,||g')
   ts_max=${ts_max::-3}
       if [[ $ts_min -ge $start ]] && [[ $ts_max -le $end ]]; then
        echo -e "\n\n Copying $dir"
        cp -r $dir $(df -ha | grep $pvc | head -n1 |  awk '{print $6}')/prometheus-db/bkp/$cluster
       echo -e "\nDIR: $dir -> minTime: $(date -d @$ts_min) & maxTime: $(date -d @$ts_max)\n"
    fi
done

du -h bkp/$cluster > bkp/$cluster/size.txt
./azcopy copy "bkp/$cluster" "https://bfprometheusbkp.blob.core.windows.net/prometheusbkp" --recursive