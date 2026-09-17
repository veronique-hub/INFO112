FROM ubuntu:24.04

WORKDIR /app

COPY . .

RUN chmod +x assembler.sh emulator.sh run_tests.sh

CMD ["bash"]