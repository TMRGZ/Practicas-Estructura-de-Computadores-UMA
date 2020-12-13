#!/bin/bash
arm-none-eabi-as -o tmp.o $1.s
arm-none-eabi-ld -e 0 -Ttext=0x8000 tmp.o
arm-none-eabi-objcopy a.out -O binary $1.img
rm tmp.o
rm a.out