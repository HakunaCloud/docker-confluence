FROM ubuntu:18.04

ENV CONFLUENCE_VERSION=7.2.0
RUN apt-get update && apt-get install -y wget xmlstarlet fontconfig

WORKDIR /opt

RUN wget https://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${CONFLUENCE_VERSION}-x64.bin

RUN chmod a+x atlassian-confluence-${CONFLUENCE_VERSION}-x64.bin
COPY confluence-responses.varfile /tmp/response.varfile
RUN ./atlassian-confluence-${CONFLUENCE_VERSION}-x64.bin -q -varfile /tmp/response.varfile

ENV DOMAIN=confluence.example.com

WORKDIR /var/atlassian/application-data/confluence/tls/
COPY ${DOMAIN}.p12 ./

RUN xmlstarlet ed --inplace --update '/Server/Service/Connector[@port=8090]/@port' -v "8443" /opt/atlassian/confluence/conf/server.xml && \
    xmlstarlet ed --inplace --delete '/Server/Service/Connector[@redirectPort=8443]/@redirectPort' /opt/atlassian/confluence/conf/server.xml  && \
    xmlstarlet ed --inplace --insert '/Server/Service/Connector' -t attr -n 'SSLEnabled' -v "true" /opt/atlassian/confluence/conf/server.xml  && \
    xmlstarlet ed --inplace --insert '/Server/Service/Connector' -t attr -n 'scheme' -v "https" /opt/atlassian/confluence/conf/server.xml && \
    xmlstarlet ed --inplace --insert '/Server/Service/Connector' -t attr -n 'secure' -v "true" /opt/atlassian/confluence/conf/server.xml && \
    xmlstarlet ed --inplace --insert '/Server/Service/Connector' -t attr -n 'keyAlias' -v "wiki" /opt/atlassian/confluence/conf/server.xml && \
    xmlstarlet ed --inplace --insert '/Server/Service/Connector' -t attr -n 'keystoreFile' -v "/var/atlassian/application-data/confluence/tls/${DOMAIN}.keystore" /opt/atlassian/confluence/conf/server.xml && \
    xmlstarlet ed --inplace --insert '/Server/Service/Connector' -t attr -n 'keystorePass' -v "lopilopi" /opt/atlassian/confluence/conf/server.xml && \
    xmlstarlet ed --inplace --insert '/Server/Service/Connector' -t attr -n 'keystoreType' -v "JKS" /opt/atlassian/confluence/conf/server.xml
#
RUN /opt/atlassian/confluence/jre/bin/keytool -importkeystore \
            -deststorepass 1234 \
            -destkeypass 1234 \
            -destkeystore ${DOMAIN}.keystore \
             -srckeystore ${DOMAIN}.p12 \
             -srcstoretype PKCS12 \
             -srcstorepass 1234 \
             -deststoretype pkcs12 \
             -alias wiki

RUN rm ${DOMAIN}.p12
VOLUME ["/var/atlassian/application-data/confluence"]

EXPOSE 8443
COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start-confluence"]