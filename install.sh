#!/bin/bash

# Function to print characters with delay
print_with_delay() {
    text="$1"
    delay="$2"
    for ((i = 0; i < ${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo
}
#notice
show_notice() {
    local message="$1"

    echo "#######################################################################################################################"
    echo "                                                                                                                       "
    echo "                                ${message}                                                                             "
    echo "                                                                                                                       "
    echo "#######################################################################################################################"
}
# Introduction animation
print_with_delay "sing-reality-hy2-box" 0.05
echo ""
echo ""
# install base
install_base(){
  # Check if jq is installed, and install it if not
  if ! command -v jq &> /dev/null; then
      echo "jq is not installed. Installing..."
      if [ -n "$(command -v apt)" ]; then
          apt update > /dev/null 2>&1
          apt install -y jq > /dev/null 2>&1
      elif [ -n "$(command -v yum)" ]; then
          yum install -y epel-release
          yum install -y jq
      elif [ -n "$(command -v dnf)" ]; then
          dnf install -y jq
      else
          echo "Cannot install jq. Please install jq manually and rerun the script."
          exit 1
      fi
  fi
}

download_sing_box(){
  # Fetch the latest (including pre-releases) release version number from GitHub API
  # 正式版
  #latest_version_tag=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases" | grep -Po '"tag_name": "\K.*?(?=")' | head -n 1)
  #beta版本
  latest_version_tag=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases" | grep -Po '"tag_name": "\K.*?(?=")' | sort -V | tail -n 1)
  latest_version=${latest_version_tag#v}  # Remove 'v' prefix from version number
  echo "Latest version: $latest_version"

  # Detect server architecture
  arch=$(uname -m)
  echo "Architecture: $arch"

  # Map architecture names
  case ${arch} in
      x86_64)
          arch="amd64"
          ;;
      aarch64)
          arch="arm64"
          ;;
      armv7l)
          arch="armv7"
          ;;
  esac

  # Prepare package names
  package_name="sing-box-${latest_version}-linux-${arch}"

  # Prepare download URL
  url="https://github.com/SagerNet/sing-box/releases/download/${latest_version_tag}/${package_name}.tar.gz"

  # Download the latest release package (.tar.gz) from GitHub
  curl -sLo "/root/${package_name}.tar.gz" "$url"


  # Extract the package and move the binary to /root
  tar -xzf "/root/${package_name}.tar.gz" -C /root
  mv "/root/${package_name}/sing-box" /root/

  # Cleanup the package
  rm -r "/root/${package_name}.tar.gz" "/root/${package_name}"

  # Set the permissions
  chown root:root /root/sing-box
  chmod +x /root/sing-box
  echo ""
}


# client configuration
show_client_configuration() {
  # Get current listen port
  current_listen_port=$(jq -r '.inbounds[0].listen_port' /root/sbconfig_server.json)
  # Get current server name
  current_server_name=$(jq -r '.inbounds[0].tls.server_name' /root/sbconfig_server.json)
  # Get the UUID
  uuid=$(jq -r '.inbounds[0].users[0].uuid' /root/sbconfig_server.json)
  # Get the public key from the file, decoding it from base64
  public_key=$(base64 --decode /root/public.key.b64)
  # Get the short ID
  short_id=$(jq -r '.inbounds[0].tls.reality.short_id[0]' /root/sbconfig_server.json)
  # Retrieve the server IP address
  server_ip=$(curl -s https://api.ipify.org)
  echo ""
  echo ""
  show_notice "sing-box 客户端配置文件"
  # Generate the link
  echo ""
  echo ""
  cat /root/sbconfig_client.json
  show_notice "Reality 客户端通用链接" 
  echo ""
  echo ""
  server_link="vless://$uuid@$server_ip:$current_listen_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$current_server_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#SING-BOX-TCP"
  echo ""
  echo ""
  echo "$server_link"
  echo ""
  echo ""
  # Print the server details
  show_notice "Reality 客户端通用参数" 
  echo ""
  echo ""
  echo "服务器ip: $server_ip"
  echo "监听端口: $current_listen_port"
  echo "UUID: $uuid"
  echo "域名SNI: $current_server_name"
  echo "Public Key: $public_key"
  echo "Short ID: $short_id"
  echo ""
  echo ""
  # Get current listen port
  hy_current_listen_port=$(jq -r '.inbounds[1].listen_port' /root/sbconfig_server.json)
  # Get current server name
  hy_current_server_name=$(openssl x509 -in /root/self-cert/cert.pem -noout -subject -nameopt RFC2253 | awk -F'=' '{print $NF}')
  # Get the password
  hy_password=$(jq -r '.inbounds[1].users[0].password' /root/sbconfig_server.json)
  # Generate the link
  hy_server_link="hy2://$hy_password@$server_ip:$hy_current_listen_port?insecure=1&sni=$hy_current_server_name#SING-BOX-HY2"
  show_notice "Hysteria2 客户端通用链接" 
  echo ""
  echo ""
  echo "$hy_server_link"
  echo ""
  echo ""   
  # Print the server details
  show_notice "Hysteria2 客户端通用参数" 
  echo ""
  echo ""  
  echo "服务器ip: $server_ip"
  echo "端口号: $hy_current_listen_port"
  echo "password: $hy_password"
  echo "域名SNI: $hy_current_server_name"
  echo "跳过证书验证: True"
  echo ""
  echo ""
  show_notice "clash-meta配置参数"
cat << EOF

port: 7890
allow-lan: true
mode: rule
log-level: info
unified-delay: true
global-client-fingerprint: chrome
dns:
  enable: true
  listen: :53
  ipv6: true
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  default-nameserver: 
    - 223.5.5.5
    - 8.8.8.8
  nameserver:
    - https://dns.alidns.com/dns-query
    - https://doh.pub/dns-query
  fallback:
    - https://1.0.0.1/dns-query
    - tls://dns.google
  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4

proxies:        
  - name: Reality
    type: vless
    server: $server_ip
    port: $current_listen_port
    uuid: $uuid
    network: tcp
    udp: true
    tls: true
    flow: xtls-rprx-vision
    servername: $current_server_name
    client-fingerprint: chrome
    reality-opts:
      public-key: $public_key
      short-id: $short_id

  - name: Hysteria2
    type: hysteria2
    server: $server_ip
    port: $hy_current_listen_port
    #  up和down均不写或为0则使用BBR流控
    # up: "50 Mbps" # 若不写单位，默认为 Mbps
    # down: "500 Mbps" # 若不写单位，默认为 Mbps
    password: $hy_password
    sni: $hy_current_server_name
    skip-cert-verify: true
    fingerprint: chrome
    alpn:
      - h3

proxy-groups:
  - name: 节点选择
    type: select
    proxies:
      - 自动选择
      - Reality
      - Hysteria2
      - DIRECT

  - name: 自动选择
    type: url-test #选出延迟最低的机场节点
    proxies:
      - Reality
      - Hysteria2
    url: "http://www.gstatic.com/generate_204"
    interval: 300
    tolerance: 50


rules:
    - GEOIP,LAN,DIRECT
    - GEOIP,CN,DIRECT
    - MATCH,节点选择

EOF

}

install_base

# Check if reality.json, sing-box, and sing-box.service already exist
if [ -f "/root/sbconfig_server.json" ] && [ -f "/root/sing-box" ] && [ -f "/root/public.key.b64" ] && [ -f "/etc/systemd/system/sing-box.service" ]; then

    echo "sing-box-reality-hysteria2已经安装"
    echo ""
    echo "请选择选项:"
    echo ""
    echo "1. 重新安装"
    echo "2. 修改配置"
    echo "3. 显示客户端配置"
    echo "4. 卸载"
    echo "5. 更新sing-box内核"
    echo ""
    read -p "Enter your choice (1-5): " choice

    case $choice in
        1)
          show_notice "Reinstalling..."
          # Uninstall previous installation
          systemctl stop sing-box
          systemctl disable sing-box > /dev/null 2>&1
          rm /etc/systemd/system/sing-box.service
          rm /root/sbconfig_server.json
          rm /root/sing-box
	
          # Proceed with installation
        ;;
        2)
          #Reality modify
          show_notice "开始修改reality端口和域名"
          # Get current listen port
          current_listen_port=$(jq -r '.inbounds[0].listen_port' /root/sbconfig_server.json)

          # Ask for listen port
          read -p "Enter desired listen port (Current port is $current_listen_port): " listen_port
          listen_port=${listen_port:-$current_listen_port}

          # Get current server name
          current_server_name=$(jq -r '.inbounds[0].tls.server_name' /root/sbconfig_server.json)

          # Ask for server name (sni)
          read -p "Enter server name/SNI (Current value is $current_server_name): " server_name
          server_name=${server_name:-$current_server_name}
          echo ""
          # modifying hysteria2 configuration
          show_notice "开始修改hysteria2端口"
          echo ""
          # Get current listen port
          hy_current_listen_port=$(jq -r '.inbounds[1].listen_port' /root/sbconfig_server.json)
          
          # Ask for listen port
          read -p "Enter desired hysteria2 listen port (Current port is $hy_current_listen_port): " hy_listen_port
          hy_listen_port=${hy_listen_port:-$hy_current_listen_port}

          # Ask for hysteria server name (sni)
          # hy_current_server_name=$(openssl x509 -noout -subject -in /root/self-cert/cert.pem | sed -n '/^subject/s/^.*CN=//p')
          # read -p "Enter hysteria2 server name/SNI (Current value is $hy_current_server_name): " hy_server_name
          # hy_server_name=${hy_server_name:-$hy_current_server_name}
          # if [ "$hy_server_name" != "$hy_current_server_name" ]; then
          #     mkdir -p /root/self-cert/ && openssl ecparam -genkey -name prime256v1 -out /root/self-cert/private.key && openssl req -new -x509 -days 36500 -key /root/self-cert/private.key -out /root/self-cert/cert.pem -subj "/CN=${hy_server_name}"
          #     echo ""
          # fi

          # Modify reality.json with new settings
          jq --arg listen_port "$listen_port" --arg server_name "$server_name" --arg hy_listen_port "$hy_listen_port" '.inbounds[1].listen_port = ($hy_listen_port | tonumber) | .inbounds[0].listen_port = ($listen_port | tonumber) | .inbounds[0].tls.server_name = $server_name | .inbounds[0].tls.reality.handshake.server = $server_name' /root/sbconfig_server.json > /root/sb_modified.json
          mv /root/sb_modified.json /root/sbconfig_server.json
          # jq --arg listen_port "$listen_port" --arg server_name "$server_name" --arg hy_server_name "$hy_server_name" --arg hy_listen_port "$hy_listen_port"  '.outbounds[2].tls.server_name = $hy_server_name | .outbounds[2].listen_port = ($hy_listen_port | tonumber) | .outbounds[1].listen_port = ($listen_port | tonumber) | .outbounds[1].tls.server_name = $server_name' /root/sbconfig_server.json > /root/sb_cli_modified.json
          # mv /root/sb_cli_modified.json /root/sbconfig_client.json
          jq --arg listen_port "$listen_port" --arg server_name "$server_name" --arg hy_listen_port "$hy_listen_port"  '.outbounds[2].listen_port = ($hy_listen_port | tonumber) | .outbounds[1].listen_port = ($listen_port | tonumber) | .outbounds[1].tls.server_name = $server_name' /root/sbconfig_server.json > /root/sb_cli_modified.json
          mv /root/sb_cli_modified.json /root/sbconfig_client.json
          # Restart sing-box service
          systemctl restart sing-box
          # show client configuration
          show_client_configuration
          exit 0
        ;;
      3)  
          # show client configuration
          show_client_configuration
          exit 0
      ;;	
      4)
          echo "Uninstalling..."
          # Stop and disable sing-box service
          systemctl stop sing-box
          systemctl disable sing-box > /dev/null 2>&1

          # Remove files
          rm /etc/systemd/system/sing-box.service
          rm /root/sbconfig_server.json
          rm /root/sing-box
          rm /root/public.key.b64
          rm /root/self-cert/private.key
          rm /root/self-cert/cert.pem
          rm /root/sbconfig_client.json
          echo "DONE!"
          exit 0
          ;;
      5)
          show_notice "Update Sing-box..."
          # Uninstall previous installation
          # systemctl stop sing-box
          # systemctl disable sing-box > /dev/null 2>&1
          # rm /root/sing-box
          download_sing_box
          # Check configuration and start the service
          if /root/sing-box check -c /root/sbconfig_server.json; then
              echo "Configuration checked successfully. Starting sing-box service..."
              systemctl daemon-reload
              systemctl enable sing-box > /dev/null 2>&1
              systemctl start sing-box
              systemctl restart sing-box
          fi
          echo ""  
          exit 1
          ;;
      *)
          echo "Invalid choice. Exiting."
          exit 1
          ;;
	esac
	fi

download_sing_box

# reality
echo "Start configuring Reality config..."
echo ""
# Generate key pair
echo "Generating key pair..."
key_pair=$(/root/sing-box generate reality-keypair)
echo "Key pair generation complete."
echo ""

# Extract private key and public key
private_key=$(echo "$key_pair" | awk '/PrivateKey/ {print $2}' | tr -d '"')
public_key=$(echo "$key_pair" | awk '/PublicKey/ {print $2}' | tr -d '"')

# Save the public key in a file using base64 encoding
echo "$public_key" | base64 > /root/public.key.b64

# Generate necessary values
uuid=$(/root/sing-box generate uuid)
short_id=$(/root/sing-box generate rand --hex 8)

# Ask for listen port
read -p "Enter Reality desired listen port (default: 443): " listen_port
listen_port=${listen_port:-443}
echo ""
# Ask for server name (sni)
read -p "Enter server name/SNI (default: itunes.apple.com): " server_name
server_name=${server_name:-itunes.apple.com}
echo ""
# hysteria2
echo "Start configuring Hysteria2 config..."
echo ""
# Generate hysteria necessary values
hy_password=$(/root/sing-box generate rand --hex 8)

# Ask for listen port
read -p "Enter desired hysteria2 listen port (default: 8443): " hy_listen_port
hy_listen_port=${hy_listen_port:-8443}
echo ""

# Ask for self-signed certificate domain
read -p "Enter the domain name for a self-signed certificate (default: bing.com): " hy_server_name
hy_server_name=${hy_server_name:-bing.com}
mkdir -p /root/self-cert/ && openssl ecparam -genkey -name prime256v1 -out /root/self-cert/private.key && openssl req -new -x509 -days 36500 -key /root/self-cert/private.key -out /root/self-cert/cert.pem -subj "/CN=${hy_server_name}"
echo "self-signed certificate generated"

# Retrieve the server IP address
server_ip=$(curl -s https://api.ipify.org)

# Create reality.json using jq
jq -n --arg listen_port "$listen_port" --arg server_name "$server_name" --arg private_key "$private_key" --arg short_id "$short_id" --arg uuid "$uuid" --arg hy_listen_port "$hy_listen_port" --arg hy_password "$hy_password" --arg server_ip "$server_ip" '{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": ($listen_port | tonumber),
      "sniff": true,
      "sniff_override_destination": true,
      "domain_strategy": "ipv4_only",
      "users": [
        {
          "uuid": $uuid,
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": $server_name,
        "reality": {
          "enabled": true,
          "handshake": {
            "server": $server_name,
            "server_port": 443
          },
          "private_key": $private_key,
          "short_id": [$short_id]
        }
      }
    },
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": ($hy_listen_port | tonumber),
      "users": [
        {
          "password": $hy_password
        }
      ],
      "tls": {
        "enabled": true,
        "alpn": [
          "h3"
        ],
        "certificate_path": "/root/self-cert/cert.pem",
        "key_path": "/root/self-cert/private.key"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "action": "direct"
      },
      {
        "inbound": ["vless-in", "hy2-in"],
        "action": "direct"
      }
    ],
    "final": "direct"
  }
}' > /root/sbconfig_server.json


# Create reality.json using jq
jq -n --arg listen_port "$listen_port" --arg server_name "$server_name" --arg public_key "$public_key" --arg short_id "$short_id" --arg uuid "$uuid" --arg hy_listen_port "$hy_listen_port" --arg hy_password "$hy_password" --arg hy_server_name "$hy_server_name" --arg server_ip "$server_ip" '{
  "dns": {
    "servers": [
      {
        "address": "https://1.1.1.1/dns-query",
        "tag": "remote"
      },
      {
        "address": "https://223.5.5.5/dns-query",
        "tag": "local"
      }
    ],
    "rules": [
      {
        "rule_set": "geosite-cn",
        "server": "local"
      }
    ],
    "strategy": "ipv4_only"
  },
  "experimental": {
    "clash_api": {
      "external_controller": "127.0.0.1:9090",
      "secret": "",
      "store_selected": true
    }
  },
  "inbounds": [
    {
      "auto_route": true,
      "domain_strategy": "ipv4_only",
      "endpoint_independent_nat": true,
      "inet4_address": "172.19.0.1/30",
      "mtu": 9000,
      "sniff": true,
      "sniff_override_destination": true,
      "strict_route": true,
      "type": "tun"
    },
    {
      "domain_strategy": "ipv4_only",
      "listen": "127.0.0.1",
      "listen_port": 2333,
      "sniff": true,
      "sniff_override_destination": true,
      "tag": "socks-in",
      "type": "socks"
    },
    {
      "domain_strategy": "ipv4_only",
      "listen": "127.0.0.1",
      "listen_port": 2334,
      "sniff": true,
      "sniff_override_destination": true,
      "tag": "mixed-in",
      "type": "mixed"
    }
  ],
  "log": {
    "level": "info",
    "timestamp": true
  },
  "outbounds": [
    {
      "tag": "proxy",
      "type": "selector",
      "outbounds": [
        "auto",
        "sing-box-reality",
        "sing-box-hysteria2",
        "direct"
      ]
    },
    {
      "tag": "auto",
      "type": "urltest",
      "outbounds": [
        "sing-box-reality",
        "sing-box-hysteria2"
      ],
      "url": "https://www.gstatic.com/generate_204",
      "interval": "1m",
      "tolerance": 50
    },
    {
      "type": "vless",
      "tag": "sing-box-reality",
      "uuid": $uuid,
      "flow": "xtls-rprx-vision",
      "packet_encoding": "xudp",
      "server": $server_ip,
      "server_port": ($listen_port | tonumber),
      "tls": {
        "enabled": true,
        "server_name": $server_name,
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
        "reality": {
          "enabled": true,
          "public_key": $public_key,
          "short_id": $short_id
        }
      }
    },
    {
      "type": "hysteria2",
      "server": $server_ip,
      "server_port": ($hy_listen_port | tonumber),
      "tag": "sing-box-hysteria2",
      "up_mbps": 30,
      "down_mbps": 150,
      "password": $hy_password,
      "tls": {
        "enabled": true,
        "server_name": $hy_server_name,
        "insecure": true,
        "alpn": [
          "h3"
        ]
      }
    },
    {
      "tag": "direct",
      "type": "direct"
    },
    {
      "tag": "block",
      "type": "block"
    },
    {
      "tag": "dns-out",
      "type": "dns"
    }
  ],
  "route": {
    "auto_detect_interface": true,
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      {
        "rule_set": "geosite-category-ads-all",
        "action": "block"
      },
      {
        "rule_set": ["geoip-cn", "geosite-cn"],
        "action": "direct"
      },
      {
        "rule_set": "geosite-geolocation-!cn",
        "action": "proxy"
      }
    ],
    "rule_set": [
      {
        "tag": "geoip-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs"
      },
      {
        "tag": "geosite-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs"
      },
      {
        "tag": "geosite-category-ads-all",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs"
      },
      {
        "tag": "geosite-geolocation-!cn",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-geolocation-!cn.srs"
      }
    ],
    "final": "proxy"
  }
}' > /root/sbconfig_client.json


# Create sing-box.service
cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/root/sing-box run -c /root/sbconfig_server.json
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF


# Check configuration and start the service
if /root/sing-box check -c /root/sbconfig_server.json; then
    echo "Configuration checked successfully. Starting sing-box service..."
    systemctl daemon-reload
    systemctl enable sing-box > /dev/null 2>&1
    systemctl start sing-box
    systemctl restart sing-box

    show_client_configuration


else
    echo "Error in configuration. Aborting"
fi
