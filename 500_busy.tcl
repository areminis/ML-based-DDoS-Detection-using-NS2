# MANET Simulation: 500 Nodes (Harder Attack Detection)

set ns [new Simulator]

# Trace Files
set tf [open "500_busy.tr" w]
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
                -ifqLen 20 \
                -antType Antenna/OmniAntenna \
                -propType Propagation/TwoRayGround \
                -phyType Phy/WirelessPhy \
                -channel $chan \
                -topoInstance $topo \
                -agentTrace ON \
                -routerTrace ON \
                -macTrace ON

# Create nodes
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

# Setup Attackers (Nodes 450–499)
for {set i 450} {$i < 500} {incr i} {
    set udp_attack($i) [new Agent/UDP]
    $ns attach-agent $node($i) $udp_attack($i)

    set cbr_attack($i) [new Application/Traffic/CBR]
    
    set random_pkt_size [expr 256 + int(rand()*1792)]  ;# Random packet size between 256 and 2048
    $cbr_attack($i) set packetSize_ $random_pkt_size

    set random_interval [expr 0.01 + (rand() * 0.07)] ;# 0.01–0.08 interval
    $cbr_attack($i) set interval_ $random_interval
    $cbr_attack($i) attach-agent $udp_attack($i)

    $ns connect $udp_attack($i) $sink

    # Random start/stop times
    set start_time [expr 1.0 + (rand()*2.0)] ;# 1–3 seconds
    set stop_time [expr $start_time + 5.0 + (rand()*5.0)] ;# active for 5–10 seconds
    $ns at $start_time "$cbr_attack($i) start"
    $ns at $stop_time "$cbr_attack($i) stop"
}

# Setup Normal nodes (1-449)
for {set i 1} {$i < 450} {incr i} {
    set udp($i) [new Agent/UDP]
    $ns attach-agent $node($i) $udp($i)

    set cbr($i) [new Application/Traffic/CBR]
    $cbr($i) set packetSize_ 512

    if {$i % 50 == 0} {
        # Every 50th normal node is slightly busy (simulate bursty normal nodes)
        set normal_interval [expr 0.03 + (rand()*0.03)] ;# 0.03–0.06
    } else {
        set normal_interval [expr 0.05 + (rand()*0.05)] ;# 0.05–0.10
    }
    $cbr($i) set interval_ $normal_interval
    $cbr($i) attach-agent $udp($i)

    $ns connect $udp($i) $sink

    set start_time [expr 2.0 + (rand()*3.0)] ;# Start between 2–5s
    $ns at $start_time "$cbr($i) start"
    $ns at 45.0 "$cbr($i) stop"
}

# Finish
proc finish {} {
    global ns nf tf
    $ns flush-trace
    close $nf
    close $tf
    exec nam manet_500_challenging_v2.nam &
    exit 0
}

$ns at 50.0 "finish"
$ns run

