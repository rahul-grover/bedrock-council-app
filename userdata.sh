#!/bin/bash -xe
sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo yum install -y openssl-devel bzip2-devel libffi-devel

cd /usr/src/
sudo wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz
sudo tar xzf Python-3.12.0.tgz

cd Python-3.12.0/
sudo ./configure --enable-optimizations
sudo make altinstall

python3.12 -c "import ssl; print(ssl.OPENSSL_VERSION)"

python3.12 -m ensurepip --upgrade
python3.12 -m pip install --upgrade pip setuptools

cd /home/ec2-user/
sudo yum install git -y

sudo git clone https://github.com/rahul-grover/bedrock-council-app.git
cd bedrock-council-app

python3.12 -m venv venv
source venv/bin/activate

cd front-end/
pip install -r requirements.txt
PRIVATE_IP=$(hostname -i)
echo $PRIVATE_IP
export AWS_DEFAULT_REGION=ap-southeast-2
chainlit run app.py --host $PRIVATE_IP --port 80 -w -d