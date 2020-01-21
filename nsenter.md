# nsenter

Purpose: `nsenter` is a powerful tool allowing you to enter into any namespaces. `nsenter` is available inside `netshoot` but requires `netshoot` to be run as a privileged container. Additionally, you may want to mount the `/var/run/docker/netns` directory to be able to enter any network namespace including bridge and overlay networks.

With `docker run --name container-B --net container:container-A`, docker uses `container-A`'s network namespace ( including interfaces and routes) when creating `container-B`. This approach is helpful for troubleshooting network issues at the container level. To troubleshoot network issues at the bridge or overlay network level, you need to enter the `namespace` of the network _itself_. `nsenter` allows you to do that. 

For example, if we wanted to check the L2 forwarding table for a overlay network. We need to enter the overlay network namespace and use same tools in `netshoot` to check these entries.  The following examples go over some use cases for using `nsenter` to understand what's happening within a docker network ( overlay in this case).

```
# Creating an overlay network
🐳  → docker network create -d overlay nsenter-test
9tp0f348donsdj75pktssd97b

# Launching a simple busybox service with 3 replicas
🐳  → docker service create --name nsenter-l2-table-test --replicas 3 --network nsenter-test busybox ping localhost
3692i3q3u8nephdco2c10ro4c

# Inspecting the service
🐳  → docker network inspect nsenter-test
[
    {
        "Name": "nsenter-test",
        "Id": "9tp0f348donsdj75pktssd97b",
        "Scope": "swarm",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "10.0.1.0/24",
                    "Gateway": "10.0.1.1"
                }
            ]
        },
        "Internal": false,
        "Containers": {
            "0ebe0fab555d2e2ef2fcda634bef2071ad3f5842b06bd134b40f259ab9be4f13": {
                "Name": "nsenter-l2-table-test.2.83uezc16jcaz2rp6cjwyf4605",
                "EndpointID": "3064946bb0224a4b3647cefcba18dcbea71b90a2ba1c09212a7bc599ec1ed3eb",
                "MacAddress": "02:42:0a:00:01:04",
                "IPv4Address": "10.0.1.4/24",
                "IPv6Address": ""
            },
            "55065360ac1c71638fdef50a073a661dec53b693409c5e09f8f854abc7dbb373": {
                "Name": "nsenter-l2-table-test.1.4ryh3wmmv21nsrfwmilanypqq",
                "EndpointID": "f81ae5f979d6c54f60636ca9bb2107d95ebf9a08f64786c549e87a66190f1b1f",
                "MacAddress": "02:42:0a:00:01:03",
                "IPv4Address": "10.0.1.3/24",
                "IPv6Address": ""
            },
            "57eca277749bb01a488f0e6c4e91dc6720b7c8f08531536377b29a972971f54b": {
                "Name": "nsenter-l2-table-test.3.9cuoq5m2ue1wi4lsw64k88tvz",
                "EndpointID": "ff1a251ffd6c674cd5fd117386d1a197ab68b4ed708187035d91ff5bd5fe0251",
                "MacAddress": "02:42:0a:00:01:05",
                "IPv4Address": "10.0.1.5/24",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.driver.overlay.vxlanid_list": "260"
        },
        "Labels": {}
    }
]

# Launching netshoot in privileged mode
 🐳  → docker run -it --rm -v /var/run/docker/netns:/var/run/docker/netns --privileged=true nicolaka/netshoot
 
# Listing all docker-created network namespaces
 
 / # cd /var/run/docker/netns/
/var/run/docker/netns # ls
0b1b36d33313  1-9tp0f348do  14d1428c3962  645eb414b538  816b96054426  916dbaa7ea76  db9fd2d68a9b  e79049ce9994  f857b5c01ced
1-9r17dodsxt  1159c401b8d8  1a508036acc8  7ca29d89293c  83b743f2f087  aeed676a57a5  default       f22ffa5115a0


# The overlay network that we created had an id of 9tp0f348donsdj75pktssd97b. All overlay networks are named <number>-<id>. We can see it in the list as `1-9tp0f348do`. To enter it:

/ # nsenter --net=/var/run/docker/netns/1-9tp0f348do sh

# Now all the commands we issue are within that namespace. 

/ # ifconfig
br0       Link encap:Ethernet  HWaddr 02:15:B8:E7:DE:B3
          inet addr:10.0.1.1  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::20ce:a5ff:fe63:437d%32621/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1450  Metric:1
          RX packets:36 errors:0 dropped:0 overruns:0 frame:0
          TX packets:18 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:2224 (2.1 KiB)  TX bytes:1348 (1.3 KiB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1%32621/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:4 errors:0 dropped:0 overruns:0 frame:0
          TX packets:4 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:336 (336.0 B)  TX bytes:336 (336.0 B)

veth2     Link encap:Ethernet  HWaddr 02:15:B8:E7:DE:B3
          inet6 addr: fe80::15:b8ff:fee7:deb3%32621/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1450  Metric:1
          RX packets:9 errors:0 dropped:0 overruns:0 frame:0
          TX packets:32 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:690 (690.0 B)  TX bytes:2460 (2.4 KiB)

veth3     Link encap:Ethernet  HWaddr 7E:55:C3:5C:C2:78
          inet6 addr: fe80::7c55:c3ff:fe5c:c278%32621/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1450  Metric:1
          RX packets:13 errors:0 dropped:0 overruns:0 frame:0
          TX packets:26 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:970 (970.0 B)  TX bytes:1940 (1.8 KiB)

veth4     Link encap:Ethernet  HWaddr 72:95:AB:A1:6A:87
          inet6 addr: fe80::7095:abff:fea1:6a87%32621/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1450  Metric:1
          RX packets:14 errors:0 dropped:0 overruns:0 frame:0
          TX packets:27 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1068 (1.0 KiB)  TX bytes:2038 (1.9 KiB)

vxlan1    Link encap:Ethernet  HWaddr EA:EC:1D:B1:7D:D7
          inet6 addr: fe80::e8ec:1dff:feb1:7dd7%32621/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1450  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:33 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

# Let's check out the L2 forwarding table. These MAC addresses belong to the tasks/containers in this service. 

/ # bridge  fdb show br br0
33:33:00:00:00:01 dev br0 self permanent
01:00:5e:00:00:01 dev br0 self permanent
33:33:ff:63:43:7d dev br0 self permanent
ea:ec:1d:b1:7d:d7 dev vxlan1 master br0 permanent
02:15:b8:e7:de:b3 dev veth2 master br0 permanent
33:33:00:00:00:01 dev veth2 self permanent
01:00:5e:00:00:01 dev veth2 self permanent
33:33:ff:e7:de:b3 dev veth2 self permanent
7e:55:c3:5c:c2:78 dev veth3 master br0 permanent
33:33:00:00:00:01 dev veth3 self permanent
01:00:5e:00:00:01 dev veth3 self permanent
33:33:ff:5c:c2:78 dev veth3 self permanent
72:95:ab:a1:6a:87 dev veth4 master br0 permanent
33:33:00:00:00:01 dev veth4 self permanent
01:00:5e:00:00:01 dev veth4 self permanent
33:33:ff:a1:6a:87 dev veth4 self permanent


# ARP and routing tables. Note that an overlay network only routes traffic for that network. It only has a single route that matches the subnet of that network.

/ # ip neigh show
/ # ip route
10.0.1.0/24 dev br0  proto kernel  scope link  src 10.0.1.1

# Looks like the arp table is flushed. Let's ping some of the containers on this network.

/ # ping 10.0.1.4
PING 10.0.1.4 (10.0.1.4) 56(84) bytes of data.
64 bytes from 10.0.1.4: icmp_seq=1 ttl=64 time=0.207 ms
64 bytes from 10.0.1.4: icmp_seq=2 ttl=64 time=0.087 ms
^C
--- 10.0.1.4 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.087/0.147/0.207/0.060 ms

/ # ip neigh show
10.0.1.4 dev br0 lladdr 02:42:0a:00:01:04 REACHABLE

# and using bridge-utils to show interfaces of the overlay network local bridge.

/ # brctl show
bridge name	bridge id		STP enabled	interfaces
br0		8000.0215b8e7deb3	no		vxlan1
							veth2
							veth3
							veth4
							
```
