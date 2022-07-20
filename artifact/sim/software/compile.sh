#!/bin/bash

#=================================================================================
# compile.sh

#  Copyright (c) 2018 ASCS Laboratory (ASCS Lab/ECE/BU)
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.

#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
#==================================================================================

COMPILER_DIR=./riscv-compiler/bin/

if [ -z "$1" ]
then
    apps=(aes)
else
    apps=($1)
fi

if [ -z "$2" ]
then
    stack=1536
else
    stack=$2
fi

echo "...@ Making sure all binaries are executable."

echo "...@ Start compilation process."

error=0

for app in ${apps[@]}
do
    echo "...@ Application: $app.c."
    echo "...@ Cleanning binary folder from possible stale copies."
    #rm applications/binaries/$app.* applications/binaries/$app 2&>/dev/null
    #cp applications/src/$app.c $app.c
    riscv32-unknown-elf-gcc -Dmarch=rv32i -O1 -S $app.c
    cp compiler-scripts/kernel_frontend kernel_frontend
    cp compiler-scripts/kernel_backend kernel_backend
    ./compiler-scripts/link.pl kernel_frontend $app.s kernel_backend $app.asm $stack
    grep -v ".attribute" $app.asm > tmpfile  && mv tmpfile $app.asm #pk: move attribute
    echo "...@ Stack point set to $stack."
    riscv32-unknown-elf-as $app.asm -o $app.o
    riscv32-unknown-elf-ld -N -Ttext 0x0000 --no-relax --unresolved-symbols=ignore-all $app.o -o $app 
    echo "...@ Compilation done. Moving to binary generation."
    riscv32-unknown-elf-objdump -d -Mno-aliases $app > $app.dump
    riscv32-unknown-elf-objcopy -O verilog $app $app.vmh
    ./compiler-scripts/binaries.pl $app.vmh
    echo "...@ Instruction and memory binaries partitioning."
    ./compiler-scripts/objdump2vmh.pl $app.dump $app.mem
    cp data_$app.vmh data_$app.mem 2&> /dev/null
    echo "...@ Done compiling application $app."
    mv $app.s $app.asm $app.o $app.dump $app *.vmh *.mem binaries/
    #cp $app.c applications/src/_$app.c
    #rm $app.c
    rm kernel_*end
	
    if [ ! -f binaries/$app.dump ]; then 
	echo "Can't find $app.dump"
	error=1;
    fi	
    if [ ! -f binaries/$app.vmh ]; then 
	echo "Can't find $app.vmh"
	error=1;
    fi	

done

if [ $error -eq 0 ]; then
    /bin/echo -e "\n\n\033[0;32mCOMPILATION SUCCESSFUL!\033[0m\n\n"
else 
    /bin/echo -e "\n\n\033[0;31mCOMPILATION FAILED!\033[0m\n\n"
fi
