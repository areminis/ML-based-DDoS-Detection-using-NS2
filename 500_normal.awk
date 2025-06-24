BEGIN {
    FS = " "
    OFS = ","
    print "NodeID,PacketsSent,PacketsDropped,SendRate,EnqueueRatio,DropRatio,PacketDeliveryRatio,NodeType"
}

{
    event = $1
    time = $2
    node = $3
    layer = $4
    pkt_type = $7

    # Clean nodeID: remove underscores
    sub(/^_/, "", node)
    sub(/_$/, "", node)

    # Only focus on CBR packets at AGT layer for sent/received
    if (pkt_type == "cbr" && layer == "AGT") {
        if (event == "s") {
            sent[node]++
        }
        else if (event == "r") {
            received[node]++
        }
    }

    # Count CBR packet drops at any layer
    if (event == "D" && pkt_type == "cbr") {
        drop[node]++
    }
}

END {
    sim_time = 15.0  # seconds

    for (n in sent) {
        psent = sent[n]
        precv = received[n]
        pdropped = drop[n]

        sendrate = (psent > 0) ? psent / sim_time : 0
        enqueue_ratio = (psent > 0) ? (psent - pdropped) / psent : 0
        drop_ratio = (psent > 0) ? pdropped / psent : 0
        pdr = (psent > 0) ? precv / psent : 0

        # Node Type labeling
        if (n >= 1 && n <= 449)
            nodetype = "Normal"
        else if (n >= 450 && n <= 499)
            nodetype = "Attacker"
        else if (n == 0)
            nodetype = "Target"
        else
            nodetype = "Normal"

        print n, psent, pdropped, sendrate, enqueue_ratio, drop_ratio, pdr, nodetype
    }
}

