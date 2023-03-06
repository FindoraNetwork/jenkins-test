#!/bin/bash

localhost="0.0.0.0"
base_url="tcp:\/\/${localhost}:"

default_proxy_app_port=26658
default_rpc_laddr_port=26657
default_p2p_laddr_port=26656

blocks_interval=0
timeout_commit=5

rm -rvf node*
tendermint testnet --v 1 --n 3 --o . 

i=0
nodes=`ls -d ./node* | sort -V`
for node in $nodes
do
    config_toml=$node/config/config.toml
    persistent_peers=`sed -n "/^persistent_peers = \"/p" $config_toml | awk -F '"' '{print $2}'`
    peers=(${persistent_peers//,/ })
    tmp_peer=""
    for j in "${!peers[@]}"
    do
        if [ $j == $i ]
        then
            continue
        fi
        tmp=`echo "${peers[j]}" | awk -F ':' '{print $1}'`
        if [ -z "$tmp_peer" ]
        then
            tmp_peer="$tmp:${default_p2p_laddr_port}"
        else
            tmp_peer="$tmp_peer,$tmp:${default_p2p_laddr_port}"
        fi
    done

    sed -i "13s/proxy_app = .*/proxy_app = \"${base_url}${default_proxy_app_port}\"/g" $config_toml
    sed -i "84s/laddr = .*/laddr = \"${base_url}${default_rpc_laddr_port}\"/g" $config_toml
    sed -i "163s/laddr = .*/laddr = \"${base_url}${default_p2p_laddr_port}\"/g" $config_toml
    sed -i "175s/persistent_peers = .*/persistent_peers = \"${tmp_peer}\"/g" $config_toml
    sed -i "272s/timeout_commit = .*/timeout_commit = \"${timeout_commit}s\"/g" $config_toml
    sed -i "279s/create_empty_blocks_interval = .*/create_empty_blocks_interval = \"${blocks_interval}s\"/g" $config_toml
    sed -i "315s/index_all_keys = .*/index_all_keys = true/g" $config_toml
done

