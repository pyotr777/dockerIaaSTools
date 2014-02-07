# Start containers
# and create external IP addresses with iptables and DHCP.
# Parameters:
# 1st - number of containers to create
# other - names of running containers


import sys,subprocess,dockerlib


N = 10
create_cont = True
make_br = True
add_routing = True
iperf = True

if (len(sys.argv) > 1):
    N = int(sys.argv[1])

cont_nums=[]
cont_names=[]

if (create_cont):
    print "Creating " + str(N) + " containers."

    for i in range(1,N+1):
        name="cont"+str(i)
        print "Starting "+name
        if not (iperf):
            c = subprocess.Popen(dockerlib.docker_api+["run","-name",name,"-d","-p","22","peter/ssh","/usr/sbin/sshd","-D"],stdout=subprocess.PIPE)
        else:
            c = subprocess.Popen(dockerlib.docker_api+["run","-name",name,"-d","-p","22","-p","5001","peter/iperf","/usr/sbin/sshd","-D"],stdout=subprocess.PIPE)

        num, err = c.communicate()
        cont_nums.append(num)
        print num + " by name " +name
        cont_names.append(name)
    
   
if (cont_names is None or len(cont_names) < 1):
    print "Getting container names"
    if (len(sys.argv) > 2):
        print "Args: "+str(sys.argv[2:])
        cont_names=sys.argv[2:]
    else:
        print "docker ps"
        cont_names = dockerlib.getContNames()
print cont_names

if (make_br):    
    print "Assigning IP addresses"
    
    for cont_name in cont_names:
        if (cont_name is None):
            continue
        print "Bridge for " + str(cont_name)
        br_name=dockerlib.getBridgeName(cont_name)
        subprocess.call(["./ip.sh",br_name])
        
for cont_name in cont_names:
    br_name = dockerlib.getBridgeName(cont_name)
    c = subprocess.Popen(["./getip.sh",br_name],stdout=subprocess.PIPE)
    CIDR, err = c.communicate()
    extip = CIDR.split("/")[0]
    intip = dockerlib.getInternalIP(cont_name)
    print cont_name+ " - "+ extip + " - " + intip
    
    if (add_routing):
        if (extip is None):
            print "No ext IP for "+ cont_name
        elif (intip is None):
            print "No int IP for " + cont_name
        else :    
            subprocess.call(["./iptables.sh",cont_name,extip,intip])
