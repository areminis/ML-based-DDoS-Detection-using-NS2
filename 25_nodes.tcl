# DDoS Simulation - 25 Nodes Flooding Target Node 10 (Fixed CBR Traffic)

# Initialize the simulator
set ns [new Simulator]

# Trace files
set tf [open "full_ddos_25nodes.tr" w]
$ns trace-all $tf

set nf [open "full_ddos_25nodes.nam" w]
$ns namtrace-all $nf

# Define topology
set val(x) 1000
set val(y) 1000

set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

# Wireless Channel
set chan [new Channel/WirelessChannel]

# Node Configuration
$ns node-config -adhocRouting AODV \
                -llType LL \
                -macType Mac/802_11 \
                -ifqType Queue/DropTail/PriQueue \
                -ifqLen 50 \
                -antType Antenna/OmniAntenna \
                -propType Propagation/TwoRayGround \
                -phyType Phy/WirelessPhy \
                -channel $chan \
                -topoInstance $topo \
                -agentTrace ON \
                -routerTrace ON \
                -macTrace ON

# Set number of nodes and Create God object
set num_nodes 25
create-god $num_nodes

# Create mobile nodes
for {set i 0} {$i < $num_nodes} {incr i} {
    set node($i) [$ns node]
    $node($i) set X_ [expr rand()*$val(x)]
    $node($i) set Y_ [expr rand()*$val(y)]
    $node($i) set Z_ 0.0
}

# Define the target node (Node 10)
set target $node(10)

# Attach a Null agent (sink) at the target node
set sink [new Agent/Null]
$ns attach-agent $target $sink

# Setup CBR traffic from all other nodes toward Target Node 10
for {set i 0} {$i < $num_nodes} {incr i} {
    if {$i == 10} { continue } ;# Skip the target itself

    set udp($i) [new Agent/UDP]
    $ns attach-agent $node($i) $udp($i)

    set cbr($i) [new Application/Traffic/CBR]
    $cbr($i) set packetSize_ 512       ;# Fixed Packet Size (Normal and Attackers)
    $cbr($i) set interval_ 0.01        ;# Fixed Interval (Fast)
    $cbr($i) attach-agent $udp($i)

    $ns connect $udp($i) $sink
    $ns at 1.0 "$cbr($i) start"
    $ns at 10.0 "$cbr($i) stop"
}

# Define finish procedure
proc finish {} {
    global ns tf nf
    $ns flush-trace
    close $tf
    close $nf
    exec nam full_ddos_25nodes.nam &
    exit 0
}

# End simulation after 15 seconds
$ns at 15.0 "finish"
$ns run

