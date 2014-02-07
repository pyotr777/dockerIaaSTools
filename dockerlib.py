# functions to work with docker API

import sys, re,subprocess,json

docker_api_sock=["docker"]
docker_api_port=["docker","-H","localhost:4243"]

docker_api=docker_api_sock

def confirm(message):
    sys.stdout.write(message+"\n[y/n]:")
    while True:
        answer=raw_input().lower()
        if (answer.find("y") >= 0):
            return True
        elif (answer.find("n") >= 0):
            return False
        else:
            sys.stdout.write("Only 'y' or 'n':")
            
# Remove virtual networking interfaces
# created by ip.sh for for assigning external IP addresses to Docker containers
def removeInterfaces(cont_names):
    for cont in cont_names:
        # do=confirm("Remove "+cont+"?")
        do = True
        if (do):
            br = getBridgeName(cont)
            print "Removing " + br
            subprocess.call(["dhclient","-d","-r",br])
            subprocess.call(["ip","link","set",br,"down"])
            ps_list=subprocess.Popen(["ps","ax"],stdout=subprocess.PIPE)
            dchp_proc=subprocess.Popen(["grep",br],stdin=ps_list.stdout,stdout=subprocess.PIPE)
            procls, err = dchp_proc.communicate()
            procs = procls.split("\n")
            for proc in procs:
                if (proc.find("grep")==-1):
                    print "Killing process "+proc
                    m = re.match("\d+",proc)
                    if (m is not None):
                        procn = m.group(0)
                        subprocess.call(["kill",procn])
            
            subprocess.call(["ip","link","delete",br])

def getContNames():
    c = subprocess.Popen(docker_api+["ps"],stdout=subprocess.PIPE)
    cont_list, err = c.communicate()
    cont_names = []
    
    for line in cont_list.split("\n"):
        if "Up" in line:
            m=re.findall("[\w\/:\-\.]+",line)
            cont_names.append(m[len(m)-1])
    return cont_names

def getContID(cont_name):
    c = subprocess.Popen(docker_api+["inspect",cont_name],stdout=subprocess.PIPE)
    r, err = c.communicate()
    if (len(r) < 5):
        return None
    jsn = json.loads(r)
    return jsn[0]["Config"]["Hostname"]

# Get container name
# cont_ID
def getContName(cont_ID):
    c = subprocess.Popen(docker_api+["inspect",cont_ID],stdout=subprocess.PIPE)
    r, err = c.communicate()
    if (len(r) < 5):
        return None
    jsn = json.loads(r)
    return jsn[0]["Name"]


def getInternalIP(cont_name):
    c = subprocess.Popen(docker_api+["inspect",cont_name],stdout=subprocess.PIPE)
    r, err = c.communicate()
    if (len(r) < 5):
        return None
    jsn = json.loads(r)
    return jsn[0]["NetworkSettings"]["IPAddress"]

def getExternalIP(cont_name):
    br_name = getBridgeName(cont_name)
    c = subprocess.Popen(["./getip.sh",br_name],stdout=subprocess.PIPE)
    CIDR, err = c.communicate()
    if (len(CIDR) < 5):
        return None
    extip = CIDR.split("/")[0]
    return extip

def getBridgeName(cont_name):
    br_name = "br_"+cont_name
    if (len(br_name)>15):
        br_name = br_name[0:15]
    return br_name


# Run N containers
# command - command to start containers
#
# Returns containers long IDs

def runContainers(N,command):
    cont_longIDs = []
    i_start=1
    for i in range(i_start,N+1):
        name="cont"+str(i)
        print "Starting "+name
        docker_command = " run -d -name "+name + " " + command
        command_list = docker_command.split()
        c = subprocess.Popen(docker_api+command_list,stdout=subprocess.PIPE)
        num, err = c.communicate()
        # Detect error
        if (len(num)<1):
            i_start = i+1
            continue
        if (err is not None):
            i_start = i+1
            print "ERROR " + err
            continue
       
       #print num + " by name " +name
        cont_longIDs.append(num.replace('\n',''))
    return cont_longIDs
