apiVersion: batch/v1
kind: Job
metadata:
  name: odom-train
spec:
  template:
    spec:
      affinity:
       nodeAffinity:
         requiredDuringSchedulingIgnoredDuringExecution:
           nodeSelectorTerms:
           - matchExpressions:
             - key: gpu-type
               operator: In
               values:
               - 1080Ti
               - 2080Ti
      containers:
      - name: odom-train
        image: hurunyan/cuda10
        command:
        - sh
        - -c
        - "apt update && apt install -y python3-pip tmux vim && pip3 install --upgrade pip && cp /ceph/kitti.tar /mnt/data/ && tar -C /mnt/data/ -xvf /mnt/data/kitti.tar && cd /opt/repo/motionflow/ && git fetch && git checkout debug-odom && git pull && pip3 install -r requirements.txt && chmod u+x ./scripts/install_modules.sh && ./scripts/install_modules.sh && chmod u+x ./scripts/train_odom.sh && ./scripts/train_odom.sh"
        volumeMounts:
        - name: data
          mountPath: /mnt/data
        - name: git-repo
          mountPath: /opt/repo
        - name: sceneflow-datasets
          mountPath: /ceph
        - name: dshm
          mountPath: /dev/shm
        resources:
          limits:
            memory: 50Gi
            cpu: "5"
            nvidia.com/gpu: "4"
            ephemeral-storage: 100Gi
          requests:
            memory: 40Gi 
            cpu: "4"
            nvidia.com/gpu: "4"
            ephemeral-storage: 100Gi
      initContainers:
      - name: init-clone-repo
        image: alpine/git
        args:
          - clone
          - https://github.com/shreyas23/motionflow.git
          - /opt/repo/motionflow
        volumeMounts:
          - name: git-repo
            mountPath: /opt/repo
      volumes:
      - name: data
        emptyDir: {}
      - name: git-repo
        emptyDir: {}
      - name: sceneflow-datasets
        persistentVolumeClaim:
          claimName: sceneflow-datasets
      - name: dshm
        emptyDir:
          medium: Memory
      restartPolicy: "Never"
  backoffLimit: 2
