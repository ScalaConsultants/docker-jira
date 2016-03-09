FROM scalac/java8

MAINTAINER Jakub Zubielik <jakub.zubielik@scalac.io>

ENV JIRA_VERSION 7.1.1
ENV MYSQL_CONNECTOR_VERSION 5.1.38

RUN wget \
    https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-$JIRA_VERSION-jira-$JIRA_VERSION-x64.bin \
    -O /opt/atlassian-jira-software-$JIRA_VERSION-jira-$JIRA_VERSION-x64.bin && \
    chmod +x /opt/atlassian-jira-software-$JIRA_VERSION-jira-$JIRA_VERSION-x64.bin

RUN cd /opt && \
    echo 'o\n1\n' | ./atlassian-jira-software-$JIRA_VERSION-jira-$JIRA_VERSION-x64.bin && \
    rm -rf /opt/atlassian-jira-software-$JIRA_VERSION-jira-$JIRA_VERSION-x64.bin

RUN wget \
    http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-$MYSQL_CONNECTOR_VERSION.tar.gz -O - 2>/dev/null \
    | tar -zxO mysql-connector-java-$MYSQL_CONNECTOR_VERSION/mysql-connector-java-$MYSQL_CONNECTOR_VERSION-bin.jar \
    > /opt/atlassian/jira/lib/mysql-connector-java-$MYSQL_CONNECTOR_VERSION-bin.jar

RUN echo '<?xml version="1.0" encoding="UTF-8"?>\n\
\n\
<jira-database-config>\n\
  <name>defaultDS</name>\n\
  <delegator-name>default</delegator-name>\n\
  <database-type>mysql</database-type>\n\
  <jdbc-datasource>\n\
    <url>jdbc:mysql://dbserver:3306/jira?useUnicode=true&amp;characterEncoding=UTF8&amp;sessionVariables=storage_engine=InnoDB</url>\n\
    <driver-class>com.mysql.jdbc.Driver</driver-class>\n\
    <username>jira</username>\n\
    <password>jira</password>\n\
    <pool-min-size>20</pool-min-size>\n\
    <pool-max-size>20</pool-max-size>\n\
    <pool-max-wait>30000</pool-max-wait>\n\
    <validation-query>select 1</validation-query>\n\
    <min-evictable-idle-time-millis>60000</min-evictable-idle-time-millis>\n\
    <time-between-eviction-runs-millis>300000</time-between-eviction-runs-millis>\n\
    <pool-max-idle>20</pool-max-idle>\n\
    <pool-remove-abandoned>true</pool-remove-abandoned>\n\
    <pool-remove-abandoned-timeout>300</pool-remove-abandoned-timeout>\n\
    <pool-test-while-idle>true</pool-test-while-idle>\n\
  </jdbc-datasource>\n\
</jira-database-config>' \
> /var/atlassian/application-data/jira/dbconfig.xml

RUN chown -R jira:jira /opt/atlassian /var/atlassian

RUN mkdir -p /etc/my_init.d

RUN echo '#!/bin/bash\n\
sed -i -e "s#<url>.*<\/#<url>`echo $DB_URL | sed -e "s/\\\\\\\\&/\\\\\\\\\\\\\\\\&/g"`<\/#" /var/atlassian/application-data/jira/dbconfig.xml\n\
sed -i -e "s#<username>.*<\/#<username>$DB_USER<\/#" /var/atlassian/application-data/jira/dbconfig.xml\n\
sed -i -e "s#<password>.*<\/#<password>$DB_PASS<\/#" /var/atlassian/application-data/jira/dbconfig.xml\n\
cd "/opt/atlassian/jira/bin"\n\
./start-jira.sh -fg' \
> /etc/my_init.d/jira

RUN chmod +x /etc/my_init.d/jira

EXPOSE 8005 8080

CMD  ["/sbin/my_init"]
