# docker-confluence
Docker image for Atlassian Confluence with TLS/SSL support enabled

# Build
To build this image, you must have a `PKCS12` certificate for SSL/TLS. You can get one for free from Let's Encrypt using [certbot](https://certbot.eff.org/):
```
certbot certonly --standalone -d wiki.example.com 
``` 

Convert it in a PKCS12 archive format:
```
sudo openssl pkcs12  -export -out ./wiki.example.com.p12 \
                -in /etc/letsencrypt/live/wiki.example.com/fullchain.pem \
                -inkey /etc/letsencrypt/live/wiki.example.com/privkey.pem \
                -name wiki
```

Last step is to copy the `PKCS12` archive in the same path of this `Dockerfile`.

Then build the image as usual:
```
docker build -t hakunacloud/wiki .
```
 
# Run
Atlassian JIRA requires a PostgreSQL database.  To make data persistent, we need 2 volumes to hold data for Jira datadir and PostgreSQL datadir. 

We also need to create a 
```bash
docker network create wiki-net

docker volume create wiki_data
docker volume create wiki_pg
```

Start a PostgreSQL database:
```bash
# Start PostgreSQL
docker run --name wiki_pg \
    --network wiki-net \
    -e POSTGRES_PASSWORD=mysecretpassword \
    -e POSTGRES_USER=wiki \
    -e POSTGRES_DB=wiki  \
    -v wiki_pg:/var/lib/postgresql/data \
    -d postgres
```


And wiki server
```bash
# Start Jira
beekube run --name confluence \
    --network wiki-net \
    -v confluence_data:/var/atlassian/application-data/confluence \
    --cpus 8 --memory=4g \
    -p 8443:8443 \
    242728094507.dkr.ecr.eu-central-1.amazonaws.com/hakunacloud/confluence:7.2.0v1
```

Open a browser to https://localhost:8443 and proceed with the configuration of Confluence