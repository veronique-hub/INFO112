#!/bin/bash

echo "=============================="
echo " INFO1112 TESTS"
echo "=============================="
echo


# --
# Successful program tests


echo "===== SAMPLE TEST: expect 60 ====="
if bash assembler.sh tests/sample.vsc; then
    bash emulator.sh tests/sample.bin
fi
echo


echo "===== LOAD/STORE TEST: expect 42 ====="
if bash assembler.sh tests/load_store.vsc; then
    bash emulator.sh tests/load_store.bin
fi
echo


echo "===== ADD TEST: expect 15 ====="
if bash assembler.sh tests/add.vsc; then
    bash emulator.sh tests/add.bin
fi
echo


echo "===== SUBTRACT TEST: expect 30 ====="
if bash assembler.sh tests/subtract.vsc; then
    bash emulator.sh tests/subtract.bin
fi
echo


echo "===== SUBTRACT ERROR TEST ====="
echo "Expect an error, then the original register value."
if bash assembler.sh tests/subtract_error.vsc; then
    bash emulator.sh tests/subtract_error.bin
fi
echo


echo "===== QUIT-ONLY TEST ====="
echo "Expect assembly to succeed and emulator to print nothing."
if bash assembler.sh tests/quit.vsc; then
    bash emulator.sh tests/quit.bin
fi
echo


# --
# Invalid .vsc tests


echo "===== INVALID OPCODE TEST: expect error ====="
bash assembler.sh tests/invalid_opcode.vsc
echo


echo "===== INVALID REGISTER TEST: expect error ====="
bash assembler.sh tests/invalid_register.vsc
echo


echo "===== INVALID ADDRESS TEST: expect error ====="
bash assembler.sh tests/invalid_address.vsc
echo


echo "===== MALFORMED INSTRUCTION TEST: expect error ====="
bash assembler.sh tests/instruction_error.vsc
echo


echo "===== MISSING QUIT TEST: expect error ====="
bash assembler.sh tests/missing_quit_error.vsc
echo


echo "===== EMPTY FILE TEST: expect error ====="
bash assembler.sh tests/empty_file_error.vsc
echo


#--

echo "===== NO ARGUMENT TEST: expect error ====="
bash assembler.sh
echo


echo "===== TWO ARGUMENTS TEST: expect error ====="
bash assembler.sh tests/sample.vsc tests/add.vsc
echo


echo "===== NON-EXISTENT FILE TEST: expect error ====="
bash assembler.sh tests/doesnotexist.vsc
echo


echo "===== WRONG EXTENSION TEST: expect error ====="
bash assembler.sh assembler.sh
echo


echo "=============================="
echo " TESTING FINISHED"
echo "=============================="