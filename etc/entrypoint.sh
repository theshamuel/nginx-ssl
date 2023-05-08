#!/bin/sh
echo "Configuring nginx..."
echo "LETSENCRYPT=${LETSENCRYPT:=$LETSENCRYPT}"

if [ ${LETSENCRYPT} != "true" ]; then
    echo "Cerificates is disabled"
    sed -i "s|return 301 https://\$host\$request_uri|index index.html index.htm|g" /etc/nginx/nginx.conf
    nginx -g "daemon off;"
    return 1
fi

#Generate Diffie-Hellman key
if [ ! -f /etc/nginx/ssl/dh2048.pem ]; then
    mkdir -p /etc/nginx/ssl
    cd /etc/nginx/ssl
    openssl dhparam -out dh2048.pem 2048
    chmod 600 dh2048.pem
    echo "Successful created dh2048.pem"
fi


# Set key paths
echo "your domain=${DOMAIN:=$DOMAIN}"
echo "your email=${EMAIL:=$EMAIL}"

FILE_KEY=/etc/nginx/ssl/certificates/_.${DOMAIN}.key
FILE_CRT=/etc/nginx/ssl/certificates/_.${DOMAIN}.crt
echo "your SSL_KEY=${FILE_KEY}"
echo "your SSL_CRT=${FILE_CRT}"


FILES="/etc/nginx/conf.d/*.conf"
for f in $FILES
do
  echo "Processing $f file..."
  sed -i "s|FILE_KEY|${FILE_KEY}|g" $f
  sed -i "s|FILE_CRT|${FILE_CRT}|g" $f
done

(
while :
do
  sed -i "s|include \/etc\/nginx\/conf.d\/\*.conf|#include \/etc\/nginx\/conf.d\/*.conf|g" /etc/nginx/nginx.conf

  if [ ! -f /etc/nginx/ssl/certificates/_.${DOMAIN}.key ]; then
    if [ ${DNS} != "" ]; then
      lego -a --path=/etc/nginx/ssl --email="${EMAIL}" --domains="*.${DOMAIN}" --domains="${DOMAIN}" --dns="${DNS}" --http.port=80 run #Generate new certificates
    fi
  else
    # 6825600 seconds in 79 days 
    if ! $(openssl x509 -checkend 6825600 -noout -in /etc/nginx/ssl/certificates/_.${DOMAIN}.key); then
      if [ ${DNS} != "" ]; then
        lego -a --path=/etc/nginx/ssl --email="${EMAIL}" --domains="*.${DOMAIN}" --domains="${DOMAIN}" --dns="${DNS}" --http.port=81 renew #Update certificates
      else
        lego -a --path=/etc/nginx/ssl --email="${EMAIL}" --domains="*.${DOMAIN}" --domains="${DOMAIN}" --http --http.port=81 renew #Update certificates
      fi
    fi  
  fi
  sed -i "s|#include \/etc\/nginx\/conf.d\/\*.conf|include \/etc\/nginx\/conf.d\/*.conf|g" /etc/nginx/nginx.conf
  
  echo "Restart nginx after certs generation..."
  nginx -s reload
  sleep 80d
done
)&

nginx -g "daemon off;"
exit $?
