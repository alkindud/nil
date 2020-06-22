#!/bin/sh

NODE_USER="sinovate"

if [ "$USER" != "root" ]; then
    echo "User must be root, use sudo ./$(basename $0)"
    exit
fi

echo "stopping sinovate.service"
systemctl stop sinovate.service
sleep 2
echo "disabling sinovate.service"
systemctl disable sinovate.service

cd /etc/systemd/system
if test -f sinovate.service; then
    echo "renaming sinovate.service to sinovate1.service"
    mv sinovate.service sinovate1.service
    sed -i 's/Description=sinovate service/Description=sinovate1 service/' sinovate1.service
    sed -i 's/\.sin/\.sin1/g' sinovate1.service
fi

cd /home/$NODE_USER
if test -d .sin; then
    echo "renaming directory .sin to .sin1"
    if test -d .sin1; then
        echo "directory .sin1 already exist, rename canceled"
    else
        mv .sin .sin1
    fi
fi

echo "enabling sinovate1.service"
systemctl daemon-reload
systemctl enable sinovate1.service

echo "creating sin1 alias"
cat << 'EOF' > sin1
#!/bin/sh

NODE_USER=$(whoami)
SIN_DIR=$(basename $0)
/home/$NODE_USER/sin-cli -conf=/home/$NODE_USER/.$SIN_DIR/sin.conf -datadir=/home/$NODE_USER/.$SIN_DIR $@
EOF
chmod +x sin1

echo "correcting .sin1/sin.conf: add rpcport and uncomment bind"
sed -i -e '1 s/^/rpcport=20971\n/;' .sin1/sin.conf
sed -i 's/#bind=/bind=/' .sin1/sin.conf

chown -R $NODE_USER:$NODE_USER /home/$NODE_USER

echo "
before starting service need to check and adjust options rpcport, bind, externalip, masternodeprivkey in every sin.conf
for starting node use: sudo systemctl start sinovate1.service
now use sin1 instead of sin-cli, for example: ./sin1 masternode status"
