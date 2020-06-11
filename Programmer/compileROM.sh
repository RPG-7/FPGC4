#!/bin/bash

printf "\nConverting code.list to code.bin\n"
#create code.bin from code.list (comments can stay after lines)
    perl -ne 'print pack("B32", $_)' < code.list > code.bin


#printf "to verify, use: \nxxd -b -c4 code.bin\n"


#printf "to create intel hex file for quartus, use: \nsrec_cat code.bin -binary -output -intel > code.hex\n"


printf "Padding code.bin with ones until multiple of 4096\n"

#get file size
    SIZE=$(wc -c < code.bin)

printf "Size of code.bin is $SIZE bytes\n"

#get needed bytes to make multiple of 4096
    NEEDED=$((4096-($SIZE%4096)))

printf "Need $NEEDED more bytes for next multiple of 4096\n"

printf "Appending $NEEDED bytes to code.bin\n"

    dd if=<(yes $'\xFF' | tr -d "\n") bs=1 count=$NEEDED >> code.bin

printf "Done compiling binary files\n"

printf "\nKilling previous uartFlasher process\n"
    
    ps aux | grep uartFlasher | grep python3 | awk '{print $2}' | xargs kill -9 > /dev/null 2>&1

if [ $? -eq 0 ]
then
  echo "Previous process was killed"
else
  echo "No previous process found"
fi
