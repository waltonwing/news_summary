# generate ssh key
ssh-keygen -t ecdsa -b 521

# add the public key to authorized_keys on the remote machine
cat ~/.ssh/id_ecdsa.pub | ssh waltonwing@10.0.0.145 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'

# basic ssh
ssh waltonwing@10.0.0.145