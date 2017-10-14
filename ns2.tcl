#!/usr/local/bin/tclsh

set ns [new Simulator]
set nf [open out.nam w]
$ns trace-all $nf
$ns namtrace-all $nf
$ns color 1 Blue
$ns color 2 Red
set prev1 0
set prev2 0
proc finish {} {
	global ns nf filename f1 f2
	$ns flush-trace
	close $nf
	close $filename
	close $f1
	close $f2
	exec xgraph sink1.tr sink2.tr &
	exec nam out.nam &
	
	exit 0
}

proc record {} {
	global tcpsink1 tcpsink2 ns filename initial_bytes1 initial_bytes2 f1 f2 prev1 prev2
	set time 1
	set bytes1 [$tcpsink1 set bytes_]
	set bytes2 [$tcpsink2 set bytes_]
	
	set now [$ns now]
	if {$now == 100} {
 		set initial_bytes1 [expr $bytes1]
		set initial_bytes2 [expr $bytes2]
	} elseif {$now == 400} {
		set final_bytes1 [expr $bytes1]
		set final_bytes2 [expr $bytes2]
		set diff1 [expr ($final_bytes1-$initial_bytes1)] 
		set diff2 [expr ($final_bytes2-$initial_bytes2)]
		set bw1 [expr $diff1/300*8]
		set bw2 [expr $diff2/300*8]
		set ratio [expr $bw1/$bw2]
		puts $filename "Time for calculation: [expr $time] sec"
		puts $filename "Now: [expr $now]"
		puts $filename "Number of bytes received at sink1: [expr $diff1]"
		puts $filename "Number of bytes received at sink2: [expr $diff2]"
		puts $filename "Throughput at sink1: [expr $bw1] bps"
		puts $filename "Throughput at sink2: [expr $bw2] bps"	
		puts $filename "Ratio: [expr $ratio]"
		puts "Throughput at sink1: [expr $bw1] bps"
		puts "Throughput at sink2: [expr $bw2] bps"	
		puts "Ratio: [expr $ratio]"
	}
	
	if {$now > 100} {

		puts $f1 "$now [expr ($bytes1-$initial_bytes1)/($now-100)*8]"
		puts $f2 "$now [expr ($bytes2-$initial_bytes2)/($now-100)*8]"		
	}	
	$ns at [expr $now+$time] "record"
}


set src1 [$ns node]
set src2 [$ns node]
set r1 [$ns node]
set r2 [$ns node]
set rcv1 [$ns node]
set rcv2 [$ns node]

$src1 color blue
$src2 color red
$r1 shape box
$r1 color black
$r2 shape box
$r2 color black
$rcv1 color blue
$rcv2 color red

set TCP_flavor [lindex $argv 0]
set case_no [lindex $argv 1]

set str1 "output"
set str2 "_"
set str3 ".tr"
set name $str1$str2$TCP_flavor$str2$case_no
set filename [open $name w]
set f1 [open sink1.tr w]
set f2 [open sink2.tr w]

if {$case_no == 1} {
	set delay "12.5ms"
} elseif {$case_no == 2} {
	set delay "20ms"
} elseif {$case_no == 3} {
	set delay "27.5ms"
}

$ns duplex-link $src1 $r1 10Mb 5ms DropTail orient right-down
$ns duplex-link $src2 $r1 10Mb $delay DropTail orient right-up
$ns duplex-link $r1 $r2 1Mb 5ms DropTail orient right
$ns duplex-link $r2 $rcv1 10Mb 5ms DropTail orient left-down
$ns duplex-link $r2 $rcv2 10Mb $delay DropTail orient left-up

$ns duplex-link-op $src1 $r1 orient right-down
$ns duplex-link-op $src2 $r1 orient right-up
$ns duplex-link-op $r1 $r2 orient right
$ns duplex-link-op $r2 $rcv1 orient right-up
$ns duplex-link-op $r2 $rcv2 orient right-down

$ns duplex-link-op $src1 $r1 color blue
$ns duplex-link-op $src2 $r1 color red
$ns duplex-link-op $r1 $r2 color black
$ns duplex-link-op $r2 $rcv1 color blue
$ns duplex-link-op $r2 $rcv2 color red


$ns duplex-link-op $r1 $r2 queuePos 0.5

if {$TCP_flavor == "VEGAS"} {
	set tcp1 [new Agent/TCP/Vegas]
	set tcp2 [new Agent/TCP/Vegas]
} elseif {$TCP_flavor == "SACK"} {
	set tcp1 [new Agent/TCP/Sack1]
	set tcp2 [new Agent/TCP/Sack1]
}

$ns attach-agent $src1 $tcp1
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1


$ns attach-agent $src2 $tcp2
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2


set tcpsink1 [new Agent/TCPSink]
$ns attach-agent $rcv1 $tcpsink1

set tcpsink2 [new Agent/TCPSink]
$ns attach-agent $rcv2 $tcpsink2

$ns connect $tcp1 $tcpsink1
$ns connect $tcp2 $tcpsink2

$tcp1 set fid_ 1
$tcp2 set fid_ 2


$ns at 0 "$src1 label \"source1\""
$ns at 0 "$src2 label \"source2\""
$ns at 0 "$r1 label \"router1\""
$ns at 0 "$r2 label \"router2\""
$ns at 0 "$rcv1 label \"sink1\""
$ns at 0 "$rcv2 label \"sink2\""
$ns at 0 "puts $TCP_flavor"
$ns at 0 "puts $case_no"
$ns at 0 "puts $delay"	
$ns at 0 "$ftp1 start"
$ns at 100 "record"
$ns at 400 "$ftp1 stop"
$ns at 0 "$ftp2 start"
$ns at 400 "$ftp2 stop"
$ns at 400 "finish"
$ns run
