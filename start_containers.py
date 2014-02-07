# Start containers
# and assign external IP with pipeworks

import sys,subprocess,dockerlib

N = 2
create_cont = True
assign_IP = True
cont_names = []
if (len(sys.argv) > 1):
    N = int(sys.argv[1])

if (create_cont):
    print "Creating " + str(N) + " containers."
    command = "-p 22 peter/ssh /usr/sbin/sshd -D"
    cont_longIDs=dockerlib.runContainers(N,command)

print cont_longIDs
print "ps"
subprocess.call(["dock","ps"])
    
cont_IDs = []  
if (cont_longIDs is None):
    cont_IDs = dockerlib.getContNames()
else:
    for cont_longID in cont_longIDs:
        cont_IDs.append(dockerlib.getContID(str(cont_longID)))

print "\n-------","\nIDs:",cont_IDs

if (assign_IP):    
    print "Assigning IP addresses"
    
    for cont_ID in cont_IDs:
        print "./pipework.sh","br1",cont_ID,"dhcp"
        c = subprocess.Popen(["./pipework-dhcp.sh","br1",cont_ID,"dhcp"],stdout=subprocess.PIPE)
        out, err = c.communicate()
        print out

    