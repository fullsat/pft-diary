---
title: certificate
icon: fas fa-info
layout: page
order: 1
---

## 証明書

### x509のフォーマット

```
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            7f:d4:28:82:c7:bc:97:fa:67:1c:d3:59:f1:2a:2b:13:e8:98:c0:04        # シリアル番号
        Signature Algorithm: sha256WithRSAEncryption                           # 署名アルゴリズム(認証局が署名するときのアルゴリズム)
        Issuer: C = JP, ST = Tokyo, O = Personal, OU = win11, CN = win11.intra # 発行者
        Validity                                                               # 有効期限
            Not Before: Apr 23 05:25:44 2024 GMT
            Not After : Apr 23 05:25:44 2025 GMT
        Subject: C = JP, ST = Tokyo, O = Personal, OU = win11, CN = win11-svc  # 証明書の所有者
        Subject Public Key Info:                                               # 公開鍵情報
            Public Key Algorithm: rsaEncryption                                # 公開鍵暗号方式(RSA/DSA/ECDSA)
                Public-Key: (2048 bit)
                Modulus:
                    00:c0:34:20:ed:3e:c1:52:18:73:ae:88:0f:cf:b0:
                Exponent: 65537 (0x10001)
        X509v3 extensions:                                                     # x509のv3の拡張領域
            X509v3 Basic Constraints:                                          # 認証局か、そうでないかを判定、チェーンの長さも規定できる
                CA:FALSE
            X509v3 Subject Key Identifier:                                     # 所有者の公開鍵の識別子
                F1:C4:B6:7E:67:0B:37:7F:53:B8:EF:37:17:0C:79:5D:A4:21:0E:86
            X509v3 Authority Key Identifier:                                   # 認証局の秘密鍵の識別子
                52:87:FB:3B:57:35:AC:DE:75:DB:B3:93:3D:89:C6:67:04:D4:0B:E9
    Signature Algorithm: sha256WithRSAEncryption                               # 署名アルゴリズム(署名前証明書に含まれない領域)
    Signature Value:                                                           # 署名前証明書を署名した時の値
        66:bf:4a:4f:66:14:c7:3a:d9:5a:40:3a:06:f3:99:ea:6a:b8:
```

拡張は他にも

* keyUsage: 鍵の用途
* subjectAltName: 複数ドメインに対応する、公開鍵の所有者の別名(DNS:example.com,URI:http://example.com、などで指定する)

---

### アルゴリズムの強度

https://www.cryptrec.go.jp/list.html

どのアルゴリズムを使えばいいのか迷って調べると、強度を報告してくれる組織があるっぽい。

---

### 秘密鍵


```
* openssl(RSA)
openssl genrsa -out rsa-private.key -des3 2048 # -outでファイル名
                                           # -des3は共有鍵の暗号方式(鍵に鍵をかけられる)
                                           # 2048はrsaのビット数1024は脆弱になりつつあるらしいので2048

* openssl(DSA)
openssl dsaparam -out dsa-param.pem 2048   # パラメータファイルを作成する必要がある
openssl gendsa -out dsa-private.key dsa-param.pem

* openssl(ECDSA)
openssl ecparam --list_curves                                     # 楕円曲線暗号という名の通りの楕円をどれにするか選ぶ(らしい)
openssl ecparam -genkey -name [short_name] -out ecdsa-private.key # short_nameは選んだ楕円を選択

* cfssl
vim csr.json
{
    "CN": "tamamushi.example.com",
    "hosts": [
        "tamamushi.example.com",
        "www.tamamushi.example.com",
        "https://www.tamamushi.example.com",
        "127.0.0.1"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C":  "JP",
            "L":  "Tamamushi City",
            "O":  "Tamamushi City Gym",
            "ST": "Kanto"
        }
    ]
}
cfssl genkey csr.json | cfssljson -bare # csrとkeyが出来る
```

---

### 公開鍵

秘密鍵があれば公開鍵を出せるので、サーバ証明書においてはこれらはあまり利用しない

```
* openssl(RSA)
openssl rsa -in rsa-private.key -pubout -out rsa-public.key

* openssl(DSA)
openssl dsa -in dsa-private.key -pubout -out dsa-public.key

* openssl(ECDSA)
openssl ec -in ecdsa-private.key -pubout -out ecdsa-public.key

* cfssl
# 見当たらず
```

---

### 証明書署名要求

```
openssl req -new -key rsa-private.key -out rsa-csr.pem
openssl req -new -key dsa-private.key -out dsa-csr.pem
openssl req -new -key ecdsa-private.key -out ecdsa-csr.pem
cfssl genkey csr.json | cfssljson -bare # 秘密鍵と一緒に作成するしかないっぽい
```

聞かれるもの

* Common Name: FQDN(サーバ証明書の場合)
* Organization: 組織名
* Organizational Unit: 部門名(EV認証の場合は表示される、ドメイン認証時は不要)
* Locality: 所在地の市町村
* State or Province: 都道府県名
* Country: 国識別子

入力不要

* E-Mail address
* Challenge password: 秘密鍵の鍵、ミドルウェア立ち上げ時に入力を求められる

---

### 自己署名

```
openssl req -x509 -key rsa-private.key -out rsa-selfsign.pem
openssl req -x509 -key dsa-private.key -out dsa-selfsign.pem
openssl req -x509 -key ecdsa-private.key -out ecdsa-selfsign.pem
cfssl selfsign tamamushi.example.com csr.json | cfssljson -bare # csr.jsonは前述したものを使う
```

※CA:TRUEになっていたopenssl.cnfをいじるべき
※cfsslはCA:FALSE、でおそらくこちらにするようにするのが正しい

---

### 認証局(ルート証明書)

* opensslの場合

```
vim /etc/ssl/openssl.cnf
#---
[v3_ca]
basicConstraints = critical,CA:true
keyUsage = cRLSign, KeyCertSign

[ CA_default ]
dir		= ./demoCA
certs		= $dir/certs
crl_dir		= $dir/crl
database	= $dir/index.txt
new_certs_dir	= $dir/newcerts
certificate	= $dir/cacert.pem 	# The CA certificate
serial		= $dir/serial 		# The current serial number
crlnumber	= $dir/crlnumber	# the current crl number
#---

# dirが相対になっているため、/etc/pki/tls/demoCAなどを作ったり、
# カレントディレクトリにdemoCAを作ったりする
# 最低限の準備は下記のディレクトリとファイル

mkdir -p demoCA/newcerts
touch demoCA/index.txt
echo "00" > demoCA/serial

openssl req -new -keyout ca.key -out careq.pem # 秘密鍵もこれで作成
openssl req -new -key xxx.key -out careq.pem   # これでも多分可能

openssl ca -create_serial 
           -out ca.pem
           -days 3650
           -batch
           -keyfile ca.key
           -selfsign
           -extensions v3_ca
           -infiles careq.pem
```

* cfsslの場合

```
cfssl genkey -initca csr.json | cfssljson -bare ca
```

---

### 認証局によるサーバ証明書の署名

* opensslの場合

```
# /usr/lib/ssl/openssl.cnfを参照しているため、認証局の秘密鍵と証明書は各ディレクトリに配置する
mkdir -p demoCA/private/
cp ca.key demoCA/private/cakey.pem
cp ca.crt demoCA/cacert.pem

openssl ca -policy policy_any -days 365 -infiles server.csr -out server.crt
```

* cfsslの場合

```
cfssl gencert -ca ca.pem -ca-key ca-key.pem csr.json
```

---

### クライアント証明書

```
openssl req -new -key client.key -out client.csr
openssl ca -policy policy_any -days 365 -out client.crt -infiles client.csr # outはinfilesの前にないとだめらしい
openssl pkcs12 -export -in client.crt                # クライアント証明書はpkcs#12形式が多いはず
               -inkey client.key -out client.pfx 
               -name "nibicity.example.com"          # nameはエイリアスで、keytoolの検索等に利用されるっぽい
# cfsslでpkcs12にする方法はよくわからなかった
```


---

### 証明書失効

```
cat demoCA/index.tx
V       340522122957Z           2315356389      unknown /C=JP/ST=Tokyo/O=Pokemon/CN=Satoshi
V       250524125024Z           231535638A      unknown /C=JP/ST=Tokyo/L=Tamamushi City/O=Tamamushi City Gym/CN=tamamushi.example.com
V       250524133447Z           231535638B      unknown /C=JP/ST=Kanto/L=Nibi City/O=Nibi City Gym/CN=nibicity.example.com
                                ----------
# シリアルをメモしておく
openssl ca -revoke demoCA/newcerts/231535638B.pem 

cat demoCA/index.txt
V       340522122957Z           2315356389      unknown /C=JP/ST=Tokyo/O=Pokemon/CN=Satoshi
V       250524125024Z           231535638A      unknown /C=JP/ST=Tokyo/L=Tamamushi City/O=Tamamushi City Gym/CN=tamamushi.example.com
R       250524133447Z   240524134150Z   231535638B      unknown /C=JP/ST=Kanto/L=Nibi City/O=Nibi City Gym/CN=nibicity.example.com

# Rになっている

# リストを更新
echo "00" > demoCA/crlnumber
openssl ca -gencrl -crldays 60 -out crl.pem

openssl ca -revoke demoCA?newcerts/231535638A.pem 
openssl ca -gencrl -crldays 60 -out crl.pem # 更新
openssl crl -in crl.pem                     # 失効した証明書のシリアルが増えている
```

* cfsslの場合

```
openssl x509 -in server.pem -noout -serial | awk -F '=' '{print $2}' > serial.txt
cfssl gencrl serial.txt ca.pem ca-key.pem | base64 -d | openssl crl -inform DER -out crl.pem
```

---

### 秘密鍵でファイルの暗号化

```
openssl pkeyutl -encrypt -pubin -inkey public.key -in sample.txt -out sample.txt.enc # lpic303教本ではrsautlとあるが現状はpkeyutlに代わっている
openssl pkeyutl -decrypt -inkey private.key -in sample.txt.enc -out sample.txt
```

