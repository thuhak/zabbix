#!/bin/bash

perf list | grep fp_arith_inst_retired.512b_packed_double > /dev/null
if [[ $? == 0 ]]; then
    a=($(perf stat -e fp_arith_inst_retired.128b_packed_double,fp_arith_inst_retired.128b_packed_single,fp_arith_inst_retired.256b_packed_double,fp_arith_inst_retired.256b_packed_single,fp_arith_inst_retired.512b_packed_double,fp_arith_inst_retired.512b_packed_single,fp_arith_inst_retired.scalar_double,fp_arith_inst_retired.scalar_single -a -- sleep 1 2>&1 | grep fp_arith_inst_retired | awk '{print $1}' | sed 's/,//g'))

    echo $((${a[0]}*2 + ${a[1]}*4 + ${a[2]}*4 + ${a[3]}*8 + ${a[4]}*8 + ${a[5]}*16 +${a[6]} + ${a[7]}))
    exit
fi

perf list | grep avx_insts.all > /dev/null
if [[ $? == 0 ]]; then
    perf stat -e avx_insts.all -a -- sleep 1 2>&1 | grep avx_insts.all | awk '{print $1}' | sed 's/,//g'
else
    a=($(perf stat -e fp_arith_inst_retired.128b_packed_double,fp_arith_inst_retired.128b_packed_single,fp_arith_inst_retired.256b_packed_double,fp_arith_inst_retired.256b_packed_single,fp_arith_inst_retired.scalar -a -- sleep 1 2>&1 | grep fp_arith_inst_retired | awk '{print $1}' | sed 's/,//g'))

    echo $((${a[0]}*2 + ${a[1]}*4 + ${a[2]}*4 + ${a[3]}*8 + ${a[4]}))
fi