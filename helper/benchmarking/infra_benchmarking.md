# Kubernetes infrastructure requirements & benchmarking

<br>

![Lord William](https://user-images.githubusercontent.com/29113813/148016679-2613948f-cc39-46d3-926c-f1bf193bf1a2.png)


## 1.0 Introduction

As we deal with multiple infrastructure building blocks (compute, storage, network, virtualization, cloud) for hosting the kubernetes clusters and one should ensure that the underlying infrastructure is not creating a bottleneck for the smooth operation of the cluster. The below guide will help in benchmarking various infrastructure building blocks and will come handy for troubleshooting various performance related issues.

 <font size="2">_This will be a living document and will be updated frequently based on various providers identified, tool improvements and new test cases identified. (last updated on 3rd Jan 2022)._</font>

## 2.0 Minimum requirements

 Based on various available benchmark data and performance outputs the below are the basic requirements to be available to run a kubernetes cluster. Based on the components/applications which are hosted on the cluster the requirements will vary as well. However the below recommendations are not hard rules; they serve as a good starting point for a robust production deployment. As always, deployments should be tested with simulated workloads before running in production.

 The most critical component in a kubernetes cluster is the etcd. etcd usually runs well with limited resources for development or testing purposes. However, when running etcd clusters in production, we should ensure that the right set of resources are available if not it will slow down the entire cluster and applications hosted in it. Due to criticality of etcd the document will focus more on the the infrastructure requirements for running the etcd cluster. Infrastructure requirements for the applications need to be factored separately and will not be under the scope of this document.

 The following are the requirements we should be considering for running etcd clusters.

#### 2.1 CPU

 Typical clusters need two to four cores to run smoothly. Heavily loaded etcd deployments, serving thousands of clients or tens of thousands of requests per second, tend to be CPU bound since etcd can serve requests from memory. Such heavy deployments usually need eight to sixteen dedicated cores.

#### 2.2 Memory

 etcd has a relatively small memory footprint but its performance still depends on having enough memory. An etcd server will aggressively cache key-value data and spends most of the rest of its memory tracking watchers. Typically 8GB is enough. For heavy deployments with thousands of watchers and millions of keys, allocate 16GB to 64GB memory accordingly.

#### 2.3 Disks

Fast disks are the most critical factor for etcd deployment performance and stability. A slow disk will increase etcd request latency and potentially hurt cluster stability. Since etcd’s consensus protocol depends on persistently storing metadata to a log, a majority of etcd cluster members must write every request down to disk. Additionally, etcd will also incrementally checkpoint its state to disk so it can truncate this log. If these writes take too long, heartbeats may time out and trigger an election, undermining the stability of the cluster.

It's highly recommended to back etcd’s storage with an SSD. A SSD usually provides lower write latencies and with less variance than a spinning disk, thus improving the stability and reliability of etcd. With at least three cluster members, mirroring and/or parity variants of RAID are unnecessary as etcd’s consistent replication already gets high availability and data integrity.

#### 2.4 Network

Multi-member etcd deployments benefit from a fast and reliable network. Low latency ensures etcd members can communicate fast. High bandwidth can reduce the time to recover a failed etcd member. Its recommended to run production grade clusters on 10 GbE ethernet for better performance and faster recovery.

It is recommended to deploy etcd members within a single data center when possible to avoid latency overheads and lessen the possibility of partitioning events. If a failure domain in another data center is required, choose a data center closer to the existing one.

#### 2.5 Sizing recommendations [vSphere]

| Size       | vCPU   | RAM   | IOPs | Bandwidth   |
|------------|:------:|:-----:|------|:-----------:|
| Small      |   2    |  8    | 800  |     50      |
| Medium     |   4    |  16   | 1000 |     70      |
| Large      |   8    |  32   | 1200 |     90      |
| Xtra large |  16    |  64   | 2000 |    120      |


The table mentioned above is an indicative sizing for a vSphere environment based on various benchmarks done in the past for hosting etcd, standard cluster components and basic monitoring. The cluster need to be sized accordingly based on the workloads which is planned to be hosted.

Based on the above benchmarks done for vsphere we have to arrive at the right numbers for various cloud providers as there is no common strategy/tool set which is adopted by them currently.

#### 2.6 [TODO]



## 3.0 Infrastructure benchmarking

Benchmarking the infrastructure in which the kubernetes cluster is hosted prior to the cluster deployment is very crucial to identify the bottlenecks. This section discuss about various tools used for infrastructure benchmarking **_prior_** to cluster deployments.

Below is the set of tools which are currently used for infrastructure benchmarking and how each tool needs to be used is also explained in the subsequent sections.



| Element | Tool used | Maturity | version |
|---------|-----------|----------|---------|
| CPU     | sysbench  | High         |  1.0.18        |
| Memory  | sysbench  | High         |  1.0.18       |
| Disk    | fio       | High         |  3.16       |
| Network | iperf3    | High         |  3.7       |
| HTTP    | drill     | Low         |         |


#### 3.1 Basic benchmarking setup

<br>

![Benchmarking Infrastructure](https://user-images.githubusercontent.com/29113813/148016781-ba4f0a7a-9ea6-458f-8f2f-89ce21098f31.png)


<br>
We provisioned the Kubernetes clusters that we used to run our benchmarks on with our Kubermatic Kubernetes Platform (KKP) and used Ubuntu 20.04 as its underlying operating system. Both are fully open source and available to everybody to reproduce benchmarks, and to extend the work by running their own.

#### 3.1 CPU benchmarking - sysbench

Virtual Machine performance is mainly qualified by computing power delivered by CPU model. This value derives from a lot of other characteristics bound to virtualization and CPU specifications such as frequency, built-in instructions and more. Facing a real-life workload, the simple MIPS (Millions of Instructions Per Seconds) or FLOPS (Floating-point Operations Per Second) declared by CPU vendors aren’t enough to declare if a machine performs better than another.

To collect a synthetic performance value, we use the Sysbench tool. Sysbench is a popular, open source, scriptable and multi-threaded benchmarking suite. It provides extensive statistics about operation rates and latency with minimal overhead even with thousands of concurrent threads. Sysbench is a great tool for testing anything from databases to general system performance. It is one of the best options around for reliable server benchmarking. This software runs workloads across Integer, Floating Point and Cryptography domains. 

Clouds are known to deliver a high-level of service by avoiding practice of CPU overcommitting. But by nature, VMs mandatorily share  resources with other tenants or at least with the hypervisor. CPU sharing can be measured by collecting a Linux kernel counter called **CPU Steal**. Expressed in percentage, this number represents the amount of time that a task was not able to be done by CPU because of someone else usage. Cloud providers generally don’t overcommit their hypervisor. A CPU stolen higher than 10% is extremely rare. But this needs to be watched out for on-premise environments.

Computing performance can be measured by how many operations the system is capable of performing within a given time (events/sec) or by how long a certain task takes to complete. The results largely depend on the number of virtual CPU cores allocated to the server but that is not the whole truth. While the race on clock speeds has slowed down, there are still noticeable differences between CPU models and generational upgrades. Therefore, the same number of cores might not perform the same between providers.

For single thread execution, issue the below command

```
sysbench --threads=1 --time=30 CPU run
```
For multi thread execution use the below command

```
sysbench cpu --cpu-max-prime=20000 --threads=_NUM_THREADS_ --time=60 run
```

The outputs must be compared and analyzed for on max threads where the performance in events/sec is getting into a saturation point. The outputs need to be compared with similar enviornments as well to arrive at comparitive benchmarks.

[TODO]


#### 3.2 Memory benchmarking - sysbench

The primary purpose of system memory is to reduce the time it takes for processes to access information. While fetching records from RAM is much faster than having to read it from a storage device, it is still considered slow in terms of CPU speeds. System memory is one of the simpler things to benchmark. Sysbench, has easy to run throughput tests for both reads and writes like the command underneath. Memory performance is usually measured in either transfer rate (MB/s) or operations rate (ops/sec). The results can differ between providers due to differences in server memory speeds. Newer CPU architectures support faster memory and offer better performance in general. Because of system-wide advances, memory speeds often go hand in hand with CPU performance.

This test commands the system to write 100GB worth of data into memory with a 30 second time limit to prevent prolonged tests on slower hosts.

```
sysbench memory --memory-oper=write --memory-block-size=1K --memory-scope=global --memory-total-size=100G --threads=_NUM_THREADS_ --time=30 run
```

#### 3.3 Storage benchmarking - FIO

FIO a.k.a flexible IO tester is a storage/disk performance testing tool. FIO executes a synthetic workload to evaluate the performance characteristics of the storage assigned to the respective volumes. As the test is destructive, its highly recommended to run FIO only prior to setting up kubernetes cluster, or when adding new storage devices.

Key performance parameters which can be measured using FIO is as below.

  - **Throughput:** measured most commonly in storage systems in MB/sec, is the most commonly used way to talk about storage performance.  There are several choke points in a storage system for throughput—first and foremost, there's the speed, bandwidth of your controller, cabling etc.

  - **Latency:** the flip side of the same performance coin. Where throughput refers to how many bytes of data per second you can move on or off the disk, latency—most commonly measured in milliseconds—refers to the amount of time it takes to read or write a single block.

  - **IOPS:** short for input/output operations per second, IOPS is the metric of measurement most commonly hear real storage engineers discussing. It means exactly what it sounds like—how many different operations can a disk service? In much the same way, "throughput" usually refers to the maximal throughput of a disk, with very large and possibly sequential reads or writes, IOPS usually refers to the maximal number of operations a disk can service.

Below are the commands which need to be carried out to benchmark IO performance of the storage.

**Read IOPS:**
```
fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=read_iops --filename=/fiotest --bs=4K --iodepth=16 --fdatasync=0 --size=50G --readwrite=randread --time_based --ramp_time=10s --runtime=30s
```
 
**Write IOPS:** 
```
fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=write_iops --filename=/fiotest --bs=4K --iodepth=16 --fdatasync=0 --size=50G --readwrite=randwrite --time_based --ramp_time=10s --runtime=30s
```

**Read Bandwidth:** 
```
fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=read_bw --filename=/fiotest --bs=128K --iodepth=16 --fdatasync=0 --size=50G --readwrite=randread --time_based --ramp_time=10s --runtime=30s
```

**Write Bandwidth:** 
```
fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=write_bw --filename=/fiotest --bs=128K --iodepth=16 --fdatasync=0 --size=50G --readwrite=randwrite --time_based --ramp_time=10s --runtime=30s
```

**Read Latency:** 
```
fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=1 --name=read_latency --filename=/fiotest --bs=4K --iodepth=4 --size=50G --readwrite=randread --time_based --ramp_time=10s --runtime=30s
```

**Write Latency:** 
```
fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=1 --name=write_latency --filename=/fiotest --bs=4K --iodepth=4 --size=50G  --readwrite=randwrite --time_based --ramp_time=10s --runtime=30s
```
<br>

If you have to benchmark your storage and see whether it is suitable to back etcd, you can use fio for the same. Using fio we will simulate a load pattern which is nearly same as etcd. Disk I/O can happen in a lot of different ways; sync vs. async, many different classes of system calls, etc. The flip side of the coin is that fio is extremely complex to use. It has a lot of parameters, and different combinations of their values yield completely different I/O workloads. To get meaningful numbers with respect to etcd, you have to make sure that the write load generated by fio is as similar as possible to that generated by etcd when writing to WAL (Write-Ahead Logging) files. Databases commonly use WAL and etcd uses it too. Details about WAL are beyond the scope of this document.

This means that, at the very least, the load generated by fio must be a series of sequential writes to a file, where each write is made up by a write system call followed by a fdatasync system call. To get the sequential writes, you have to provide fio with the flag --rw=write. To make sure that fio writes using the write system call—as opposed to other system calls (e.g. pwrite) use --ioengine=sync. Finally, to make sure that each write fio invokes is followed by a fdatasync, use --fdatasync=1.

You need a [fio](https://github.com/axboe/fio) version at least as new as 3.5 because older versions don’t report fdatasync duration percentiles. For more details on interpreting test results please refer [etcd documentation](https://etcd.io/docs/v3.5/faq/#what-does-the-etcd-warning-failed-to-send-out-heartbeat-on-time-mean).

```
fio --rw=write --ioengine=sync --fdatasync=1 --directory=/dummy_data --size=22m --bs=2300 --name=perftest

```

To run this as a pod use the below command
```
kubectl run etcdperf -it -n monitoring --image quay.io/openshift-scale/etcd-perf
```


All you have to do then is look at the output and check if the 99th percentile of fdatasync durations is less than 10ms. If that is the case, then then the storage is fast enough.  Here is an example output:

![image](https://user-images.githubusercontent.com/29113813/148015568-79ef697f-7bfe-4218-a2c9-5ae60cb47034.png)


#### 3.4 Network benchmarking - iperf3

Cloud providers gernerally have a high perofrmance internal network throttled in consumner usage to guarantee a certain level if service for all tenants. The maximun performance is completely virtual and is defined by vendor in the VM's network specification.  

iperf3 is a cross-platform command-line based program for performing real-time network throughput measurements. It is one of the powerful tools for testing the maximum achievable bandwidth in IP networks __(supports IPv4 and IPv6)__. With iperf, you can tune several parameters associated with timing, buffers, and protocols such as TCP, UDP, SCTP. It comes in handy for network performance tuning operations.

Unlike other tools iPerf3 need to be installed in two identical instances/pods in the same region-availability zone/data centre. Basic test setup should be something like [this](#31-basic-benchmarking-setup) for running the tests. Below are the test which needs to be run for TCP and UDP for gathering the benchmark data.

Use the below command for the server instance. These commands will fill the bandwidth with the goal is to capture the maximum throughput between 2 hosts.
```
iperf3 --server --version4 --interval 30
```

Use the below command for the client instance (for TCP test)
```
iperf3 --client <server IP> --interval 30 --parallel <_NUM_THREADS_> --time 30 --format M –json
```

Use the below command for the client instance (for UDP test)
```
iperf3 --client <server IP> -u --interval 30 --parallel <_NUM_THREADS_> --time 30 --format M –json
```



#### 3.5 HTTP benchmarking - drill

[TODO]

<br>

#### 3.6 Benchmarking Suite [WIP]

Currently a docker image is getting created which will have all the required tools and scripts in it. This is currently work in progress. Details pertaining to same is available in the below link.

<br>

`https://github.com/bejoynr/kubernetes-benchmark`


#### 3.7 Summary of test and results

Below is a sample template which can be used to capture results...

| Test Element | Test type |   Output   | Unit type |
|--------------|-----------|----------|---------|
| CPU          | sysbench max-prime test with 2 threads   |          |     EPS    |
| Memory  | Writing 10gb worth of data into memory with a 30 second time using sysbench |          |    MBps     |
| Network (Pod to Pod TCP)    | Pod to Pod TCP Bit rate- run server and clients using iperf3       |          |   GBps      |
| Network (Pod to Pod UDP)    | UDP bit rate- run server and clients using iperf3       |          |   GBps      |
| Network (VM to VM TCP)    | TCP bit rate- run server and clients using iperf3       |          |   GBps      |
| Network (VM to VM UDP)    | UDP bit rate- run server and clients using iperf3     |          |   MBps      |
| Disk    | Random Read/Write IOPS using FIO     |          |   IOPS      |
| Disk    | Random Read/Write bandwidth using FIO     |          |   Mbps      |
| Disk    | Average Read/Write latency using FIO     |          |   msec      |
| Disk    | 99th percentile fsync latency using FIO     |          |   msec      |


#### 3.8 Conclusion 

Benchmarking infrastrucutre elements which host a kubernetes cluster in cloud or on-premise can be very tricky. There are many different settings and configurations that must be taken seriously to ensure that it always offers the best performance. Also, don’t just benchmark after the service is completed. Run benchmarks regularly when there are major code updates, dependencies updates, and also cluster updates. You might not get the same results, and if it’s the case, you can really quickly react before it becomes a problem in production. 


