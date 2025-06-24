# MANET Simulation: 500 Nodes (50 Attackers, 450 Normal)
set ns [new Simulator]

# Trace Files
set tf [open "500_normal.tr" w]
$ns trace-all $tf

# Define topology
set val(x) 2000
set val(y) 2000

set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

create-god 500

# Setup wireless channel
set chan [new Channel/WirelessChannel]

# Node Configuration
$ns node-config -adhocRouting AODV \
                -llType LL \
                -macType Mac/802_11 \
                -ifqType Queue/DropTail/PriQueue \
                -ifqLen 10 \
                -antType Antenna/OmniAntenna \
                -propType Propagation/TwoRayGround \
                -phyType Phy/WirelessPhy \
                -channel $chan \
                -topoInstance $topo \
                -agentTrace ON \
                -routerTrace ON \
                -macTrace ON

# Create 500 nodes
for {set i 0} {$i < 500} {incr i} {
    set node($i) [$ns node]
    $node($i) set X_ [expr rand()*$val(x)]
    $node($i) set Y_ [expr rand()*$val(y)]
    $node($i) set Z_ 0.0
}

# Target node
set target $node(0)

set sink [new Agent/Null]
$ns attach-agent $target $sink

# Attacker Traffic (Nodes 450 to 499) - Start early
for {set i 450} {$i < 500} {incr i} {
    set udp_attack($i) [new Agent/UDP]
    $ns attach-agent $node($i) $udp_attack($i)
    set cbr_attack($i) [new Application/Traffic/CBR]
    $cbr_attack($i) set packetSize_ 2048
    set random_interval [expr 0.001 + (rand() * 0.004)] ;# Very aggressive (0.001–0.005)
    $cbr_attack($i) set interval_ $random_interval
    $cbr_attack($i) attach-agent $udp_attack($i)
    $ns connect $udp_attack($i) $sink
    $ns at 1.0 "$cbr_attack($i) start"
    $ns at 10.0 "$cbr_attack($i) stop"
}
# Normal Traffic (Nodes 1 to 449) - Start later
for {set i 1} {$i < 450} {incr i} {
    set udp($i) [new Agent/UDP]
    $ns attach-agent $node($i) $udp($i)
    set cbr($i) [new Application/Traffic/CBR]
    $cbr($i) set packetSize_ 512
    set random_interval [expr 0.03 + (rand() * 0.04)] ;# 0.03–0.07
    $cbr($i) set interval_ $random_interval
    $cbr($i) attach-agent $udp($i)
    $ns connect $udp($i) $sink
    $ns at 2.0 "$cbr($i) start"
    $ns at 10.0 "$cbr($i) stop"
}

# Finish Procedure
proc finish {} {
    global ns nf tf
    $ns flush-trace
    close $nf
    close $tf
    exec nam manet_500_flood.nam &
    exit 0
}

$ns at 15.0 "finish"
$ns run
