#!/bin/bash

#one argument only
if [ "$#" -ne 1 ]; then
    echo "Error: usage: bash emulator.sh <file.bin>" >&2
    exit 1
fi


input="$1"

if [ ! -f "$input" ]; then
    echo "Error: '$input' is not a file" >&2
    exit 1
fi


if [[ "$input" != *.bin ]]; then
    echo "Error: input file must end in .bin" >&2
    exit 1
fi


if [ ! -s "$input" ]; then
    echo "Error: input file is empty" >&2
    exit 1
fi


bytes=( $(od -An -tu1 -v "$input") )


n_values=${bytes[0]}


if (( ${#bytes[@]} < 1 + n_values + 2 )); then
    echo "Error: invalid .bin file" >&2
    exit 1
fi


instruction_bytes=$(( ${#bytes[@]} - 1 - n_values ))


if (( instruction_bytes % 2 != 0 )); then
    echo "Error: instructions must be 2 bytes each" >&2
    exit 1
fi


if (( n_values + instruction_bytes > 256 )); then
    echo "Error: program does not fit in 256-byte memory" >&2
    exit 1
fi


#memory locations, begins at 0 
# Every memory location begins at 0.
memory=()

for ((i = 0; i < 256; i++)); do
    memory[$i]=0
done


#vsc's 4 registers
registers=(0 0 0 0)


for ((i = 0; i < n_values; i++)); do
    memory[$i]=${bytes[$((1 + i))]}
done


for ((i = 0; i < instruction_bytes; i++)); do

    memory[$((n_values + i))]=${bytes[$((1 + n_values + i))]}

done


pc=$n_values #instrucs begins after static values


program_end=$((n_values + instruction_bytes))


found_quit=0


while (( pc < program_end )); do

    if (( pc + 1 >= program_end )); then
        echo "Error: incomplete instruction at memory address $pc" >&2
        exit 1
    fi


    first_byte=${memory[$pc]}
    second_byte=${memory[$((pc + 1))]}


    
    opcode=$(( first_byte >> 2 )) #first 6 bits for opcode
    register=$(( first_byte & 3 )) #last 2bits for register

    
    address=$second_byte #memory address


    case "$opcode" in

        1) #load
            registers[$register]=${memory[$address]}
            ;;


        2) #store
            memory[$address]=${registers[$register]}
            ;;


        3) #add
            registers[$register]=$(( \
                ${registers[$register]} + ${memory[$address]} \
            ))
            ;;


        4) #sub
            if (( ${registers[$register]} >= ${memory[$address]} )); then

                registers[$register]=$(( \
                    ${registers[$register]} - ${memory[$address]} \
                ))

            else

                echo "Error: SUB would produce a negative result" >&2

            fi
            ;;


        8) #quit
            if (( register != 0 || address != 0 )); then
                echo "Error: invalid QUIT instruction" >&2
                exit 1
            fi

            found_quit=1
            break
            ;;


        9) #print
            if (( address != 0 )); then
                echo "Error: invalid PRINT instruction" >&2
                exit 1
            fi

            echo "${registers[$register]}"
            ;;


        *)
            echo "Error: unknown opcode $opcode at memory address $pc" >&2
            exit 1
            ;;

    esac



    pc=$((pc + 2)) #move forward by 2 memeory addresses since every normal instruc is 2bytes

done


if (( found_quit == 0 )); then
    echo "Error: program ended without QUIT" >&2
    exit 1
fi