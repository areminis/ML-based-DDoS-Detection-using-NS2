#!/usr/bin/awk -f
# AWK script to extract features from NS2 trace file with AGT, RTR, MAC, IFQ layers

BEGIN {
    FS = " "
    OFS = ","
    print "NodeID,PacketsSent,PacketsDropped,SendRate,EnqueueRatio,DropRatio,NodeType"
}

{
    event = $1
    time = $2
    node = $3
    layer = $4
    pkt_type = $7

    # Clean nodeID if needed (remove underscores)
    sub(/^_/, "", node)
    sub(/_$/, "", node)

    # Focus only on CBR packets
    if (pkt_type == "cbr") {
        # Sent packets
        if (event == "s" && layer == "AGT") {
            sent[node]++
            if (start_time[node] == "") start_time[node] = time
            end_time[node] = time
        }

        # Received packets
        if (event == "r" && layer == "AGT") {
            received[node]++
        }

        # Dropped packets
        if (event == "D") {
            drop[node]++
        }
    }
}

END {
    sim_time = 35.0  # Set simulation time (adjust if needed)

    for (n in sent) {
        psent = sent[n]
        pdropped = drop[n]
        precv = received[n]

        duration = end_time[n] - start_time[n]
        if (duration <= 0) duration = sim_time  # fallback if no proper start-end

        sendrate = (psent > 0) ? psent / duration : 0
        enqueue_ratio = (psent > 0) ? (psent - pdropped) / psent : 0
        drop_ratio = (psent > 0) ? pdropped / psent : 0

        # Label Node Type (change this if you know attacker node range)
        if (n >= 1 && n <= 449)
            nodetype = "Normal"
        else if (n >= 450 && n <= 499)
            nodetype = "Attacker"
        else if (n == 0)
            nodetype = "Target"
        else
            nodetype = "Normal"

        print n, psent, pdropped, sendrate, enqueue_ratio, drop_ratio, nodetype
    }
}

