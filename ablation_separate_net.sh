apiVersion: batch/v1
kind: Job
metadata:
  name: ablation-separate
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
               - V100
      containers:
      - name: ablation-separate
        image: hurunyan/cuda10
        command:
        - sh
        - -c
        - "apt update && apt install -y python3-pip && pip3 install --upgrade pip && cp /ceph/kitti2012.tar /mnt/data/ && tar -C /mnt/data/ -xvf /mnt/data/kitti2012.tar && cd /opt/repo/motionflow/ && pip3 install -r requirements.txt && chmod u+x ./scripts/install_modules.sh && ./scripts/install_modules.sh && chmod u+x ./scripts/ablation_separate_net.sh && ./scripts/ablation_separate_net.sh"
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
            memory: 30Gi
            cpu: "3"
            nvidia.com/gpu: "1"
            ephemeral-storage: 100Gi
          requests:
            memory: 20Gi 
            cpu: "2"
            nvidia.com/gpu: "1"
            ephemeral-storage: 100Gi
      initContainers:
      - name: init-clone-repo
        image: alpine/git
        args:
          - clone
          - --single-branch
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
      restartPolicy: "OnFailure"
  backoffLimit: 2