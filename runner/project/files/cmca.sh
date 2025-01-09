#!/usr/bin/env bash

mkdir /tmp/auto-tls

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
commonName                 = admin-02.dev.metal.zndx.org

[ req_ext ]
subjectAltName = @alt_names

[alt_names]
DNS.1 = admin-02.dev.metal.zndx.org
#DNS.2 = admin-02.dev.metal.zndx.org

[ v3_ext ]
keyUsage=critical,nonRepudiation,digitalSignature,keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
EOF

openssl req -new -key server-key.pem -out server.csr -config server.cnf

openssl x509 -req -in server.csr -CA ca.pem -CAkey ca-key -CAcreateserial -out server.pem -days 100 -extensions v3_ext -extfile server.cnf -passin pass:Super@Secret1

cp  * /tmp/auto-tls

chown -R cloudera-scm:cloudera-scm /tmp/auto-tls

mkdir /opt/cloudera/auto-tls

chown cloudera-scm:cloudera-scm /opt/cloudera/auto-tls

cd /root

curl -ik -v -u admin:admin -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
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
"hostname" : "admin-02.dev.metal.zndx.org",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}, {
"hostname" : "admin-02.dev.metal.zndx.org",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}, {
"hostname" : "base-01.dev.metal.zndx.org",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}, {
"hostname" : "base-02.dev.metal.zndx.org",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}, {
"hostname" : "base-03.dev.metal.zndx.org",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}, {
"hostname" : "base-04.dev.metal.zndx.org",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}, {
"hostname" : "base-05.dev.metal.zndx.org",
"certificate" : "/tmp/auto-tls/server.pem",
"key" : "/tmp/auto-tls/server-key.pem"
}],
"configureAllServices" : "true",
"sshPort" : 22,
"userName" : "root",
"password" : "",
"privateKey":"-----BEGIN RSA PRIVATE KEY-----\n[FIXME]\n-----END RSA PRIVATE KEY-----\n\n",
passphrase": "Super@Secret1"
}' 'http://admin-02.dev.metal.zndx.org:7180/api/v43/cm/commands/generateCmca'

