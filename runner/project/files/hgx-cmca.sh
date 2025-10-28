#!/usr/bin/env bash

cat<<EOF>/tmp/auto-tls/key.pwd
Super@Secret1
EOF

openssl req -new -x509 -keyout ca-key -out ca.pem -days 365 -subj "/C=US/ST=California/L=Palo Alto/O=Cloudera/CN=Cloudera" -passout pass:Super@Secret1

openssl genrsa -out server-key.pem 2048

cat <<EOF >server.cnf
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn


[ dn ]
countryName                = US
stateOrProvinceName        = California
localityName               = Palo Alto
organizationName           = Cloudera
commonName                 = 0398-dsm-lvcpu.kcloud-dev.comops.cloudera.com.maintenance.kcloud-dev.comops.cloudera.com

[ req_ext ]
subjectAltName = @alt_names

[alt_names]
DNS.1 = 0398-dsm-lvcpu.kcloud-dev.comops.cloudera.com

[ v3_ext ]
keyUsage=critical,nonRepudiation,digitalSignature,keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
EOF

openssl req -new -key server-key.pem -out server.csr -config server.cnf

openssl x509 -req -in server.csr -CA ca.pem -CAkey ca-key -CAcreateserial -out server.pem -days 100 -extensions v3_ext -extfile server.cnf -passin pass:Super@Secret1

cp  * /tmp/auto-tls

chown -R cloudera-scm:cloudera-scm /tmp/auto-tls

#mkdir /opt/cloudera/auto-tls

chown cloudera-scm:cloudera-scm /opt/cloudera/auto-tls

cd /root

curl -ik -v -u admin:admin  --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
"location" : "/opt/cloudera/auto-tls",
"customCA" : false,
"interpretAsFilenames" : false,
"cmHostCert" : "",
"cmHostKey" : "",
"caCert" : "",
"keystorePasswd" : "",
"truststorePasswd" : "",
"trustedCaCerts" : "",
"hostCerts" : [ {
"hostname" : "0398-dsm-lvcpu.kcloud-dev.comops.cloudera.com.maintenance.kcloud-dev.comops.cloudera.com",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}, {
"hostname" : "0398-dsm-lvcpu.kcloud-dev.comops.cloudera.com.maintenance.kcloud-dev.comops.cloudera.com",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}, {
"hostname" : "0400-dsm-lvcpu.kcloud-dev.comops.cloudera.com.maintenance.kcloud-dev.comops.cloudera.com",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}, {
"hostname" : "0401-dsm-lvcpu.kcloud-dev.comops.cloudera.com.maintenance.kcloud-dev.comops.cloudera.com",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}, {
"hostname" : "0402-dsm-lvcpu.kcloud-dev.comops.cloudera.com.maintenance.kcloud-dev.comops.cloudera.com",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}, {
"hostname" : "0403-dsm-lvcpu.kcloud-dev.comops.cloudera.com.maintenance.kcloud-dev.comops.cloudera.com",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}, {
"hostname" : "0404-dsm-lvcpu.kcloud-dev.comops.cloudera.com.maintenance.kcloud-dev.comops.cloudera.com",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}],
"configureAllServices" : "true",
"sshPort" : 22,
"userName" : "root",
"password" : "",
"privateKey":"-----BEGIN RSA PRIVATE KEY-----\n[FIXME]\n-----END RSA PRIVATE KEY-----\n\n",
passphrase": "Super@Secret1"
}' 'http://0398-dsm-lvcpu.kcloud-dev.comops.cloudera.com.maintenance.kcloud-dev.comops.cloudera.com:7180/api/v43/cm/commands/generateCmca'

