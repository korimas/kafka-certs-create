#!/bin/bash

VALIDITY_DAYS=3650
STORE_PASS=hillstone
STORE_KEY_PASS=hillstone
CA_KEY_PASS=hillstone
CLIENT_KEY_PASS=hillstone

keytool -keystore server.keystore.jks \
        -alias kafkaserver \
        -validity $VALIDITY_DAYS \
        -keyalg RSA \
        -storepass $STORE_PASS \
        -keypass $STORE_KEY_PASS \
        -genkey \
        -dname "C=CN,ST=JS,L=SZ,O=HillStone,OU=StoneOS,CN=kafkaserver"

# generate ca
openssl req -new -x509 \
            -keyout cakey.pem \
            -out cacert.pem \
            -days $VALIDITY_DAYS \
            -passout pass:$CA_KEY_PASS \
            -subj "/C=CN/ST=JS/L=SZ/O=HillStone/OU=StoneOS/CN=ZPZHOU.COM"

# import ca cert to truststore
keytool -keystore server.truststore.jks \
        -alias caroot \
        -import -file cacert.pem \
        -storepass $STORE_PASS

# export servercert.csr
keytool -keystore server.keystore.jks \
        -alias kafkaserver \
        -certreq -file servercert.csr \
        -storepass $STORE_PASS

# self signed
openssl x509 -req \
             -CA cacert.pem \
             -CAkey cakey.pem \
             -in servercert.csr \
             -out servercert.pem \
             -days $VALIDITY_DAYS \
             -CAcreateserial -passin pass:$CA_KEY_PASS

# import ca cert to keystore
keytool -keystore server.keystore.jks \
        -alias caroot \
        -import -file cacert.pem \
        -storepass $STORE_PASS

# import server cert to keystore
keytool -keystore server.keystore.jks \
        -alias kafkaserver \
        -import -file servercert.pem \
        -storepass $STORE_PASS

openssl genrsa -passout pass:$CLIENT_KEY_PASS -out clientkey.pem -des3 4096

openssl req -new -days $VALIDITY_DAYS -key clientkey.pem -out clientcert.csr -passin pass:$CLIENT_KEY_PASS -subj "/C=CN/ST=JS/L=SZ/O=HillStone/OU=StoneOS/CN=kafkaclient"

openssl ca -days $VALIDITY_DAYS -keyfile cakey.pem -cert cacert.pem -in clientcert.csr -out clientcert.pem -config ./ca/openssl.cnf -passin pass:$CA_KEY_PASS


mkdir -p target
mv ca*.pem target
mv cacert.srl target
mv client* target
mv server* target

