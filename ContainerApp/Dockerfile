# ==============================================================================
# Script Name:  Dockerfile
# Description:  Docker file to create a continer helps windows Users 
#               to run on Linux Environment with minmal solution
# Author:       MohammedDiaa (mohammeddiaato@gmail.com)
# Company:      Gestell - Professional Embedded Solutions
# ==============================================================================

FROM ubuntu:latest

RUN apt-get update && apt-get install -y nginx build-essential \
     python3 python3-pip python3-venv gcc-avr binutils-avr avr-libc avrdude \
     gdb-avr  

WORKDIR /app

RUN mkdir /app/workspace && chmod 777 /app/workspace
RUN mkdir -p /app/workspace/Avr_Projects
RUN mkdir -p /app/workspace/C_Prog_projects

#making a virtual envrionment for the flask app that recieves the Files and routes them to work on python because of errors 
RUN python3 -m venv venv

# installing the Flask for the Virtual environment

RUN ./venv/bin/pip install flask


COPY app.py .
COPY Runner.sh .
RUN chmod +x  Runner.sh

COPY nginx.conf /etc/nginx/nginx.conf


EXPOSE 80

CMD ["./Runner.sh"]