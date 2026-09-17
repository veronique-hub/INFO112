#!/bin/bash


if [ "$#" -ne 1 ]; then
    echo "Error: usage: bash assembler.sh <file.vsc>" >&2
    exit 1
fi

#save filename
input="$1"

#validate filname and input
if [ ! -f "$input" ]; then
    echo "Error: '$input' is not a file" >&2
    exit 1
fi

if [[ "$input" != *.vsc ]]; then
    echo "Error: input file must end in .vsc" >&2
    exit 1
fi


if [ ! -s "$input" ]; then
    echo "Error: input file is empty" >&2
    exit 1
fi


# Read every line of the .vsc file into an array called lines.
mapfile -t lines < "$input"

#remove windows carridge return character thing
for i in "${!lines[@]}"; do
    lines[$i]="${lines[$i]%$'\r'}"
done


#read no. of static values
n_values="${lines[0]}"

#static values between 0 to 255 (array of 256 elements from instructions)
if ! [[ "$n_values" =~ ^[0-9]+$ ]] || (( 10#$n_values > 255 )); then
    echo "Error: first line must be an integer from 0 to 255" >&2
    exit 1
fi

n_values=$((10#$n_values))


#check no. of sv promised
if (( ${#lines[@]} < 1 + n_values )); then
    echo "Error: expected $n_values static values" >&2
    exit 1
fi


#arrat to hold all the bytes for .bin file
bytes=("$n_values")


#validate static values.
for ((i = 1; i <= n_values; i++)); do

    value="${lines[$i]}"

    # Every static value must fit inside one byte: 0-255.
    if ! [[ "$value" =~ ^[0-9]+$ ]] || (( 10#$value > 255 )); then
        echo "Error: invalid static value on line $((i + 1))" >&2
        exit 1
    fi

    bytes+=("$((10#$value))")
done


# Instructions begin after n_values and all the static values.
first_instruction=$((1 + n_values))

instruction_count=0
found_quit=0


#reach each line as an instruction
for ((i = first_instruction; i < ${#lines[@]}; i++)); do

    line="${lines[$i]}"
    line_number=$((i + 1))


    #valid format of instruction --> instruction, register, address

    if ! [[ "$line" =~ ^([A-Z]+),([0-9]+),([0-9]+)$ ]]; then
        echo "Error: invalid instruction format on line $line_number" >&2
        exit 1
    fi


    instruction="${BASH_REMATCH[1]}"
    register_text="${BASH_REMATCH[2]}"
    address_text="${BASH_REMATCH[3]}"

    register=$((10#$register_text))
    address=$((10#$address_text))


    # Convert instruction names into opcode
    case "$instruction" in

        LOAD)
            opcode=1
            ;;

        STORE)
            opcode=2
            ;;

        ADD)
            opcode=3
            ;;

        SUB)
            opcode=4
            ;;

        QUIT)
            opcode=8
            ;;

        PRINT)
            opcode=9
            ;;

        *)
            echo "Error: unknown instruction '$instruction' on line $line_number" >&2
            exit 1
            ;;
    esac


    #for load, store, add, sub --> register must be 0-3(page 2)--> address must be 0-255(pafe )
    case "$instruction" in

        LOAD|STORE|ADD|SUB)

            if (( register < 0 || register > 3 )); then
                echo "Error: register must be 0-3 on line $line_number" >&2
                exit 1
            fi

            if (( address < 0 || address > 255 )); then
                echo "Error: address must be 0-255 on line $line_number" >&2
                exit 1
            fi
            ;;

        #register,0
        PRINT)

            if (( register < 0 || register > 3 || address != 0 )); then
                echo "Error: PRINT must be PRINT,<0-3>,0 on line $line_number" >&2
                exit 1
            fi
            ;;


        #0,0
        QUIT)

            if (( register != 0 || address != 0 )); then
                echo "Error: QUIT must be QUIT,0,0 on line $line_number" >&2
                exit 1
            fi
            ;;
    esac


    instruction_count=$((instruction_count + 1))


    # Convert instruction into 2 bytes --> b1 = opcode(6bit)+reg(2bit), b2 = address
    first_byte=$((opcode * 4 + register)) 
    #memory address.
    second_byte=$address

    bytes+=("$first_byte" "$second_byte")



    if [ "$instruction" = "QUIT" ]; then

        found_quit=1

       
        if (( i != ${#lines[@]} - 1 )); then
            echo "Error: no instructions are allowed after QUIT" >&2
            exit 1
        fi

        break
    fi

done



if (( found_quit == 0 )); then
    echo "Error: program must end with QUIT,0,0" >&2
    exit 1
fi



if (( n_values + 2 * instruction_count > 256 )); then
    echo "Error: program is too large for 256-byte memory" >&2
    exit 1
fi


#changensomething.vsc to something.bin.
output="${input%.vsc}.bin"

#temp file
temp_output="${output}.tmp"

: > "$temp_output"


#convert to bin
for byte in "${bytes[@]}"; do
    printf "\\$(printf '%03o' "$byte")" >> "$temp_output"
done


mv "$temp_output" "$output"

echo "Created $output"