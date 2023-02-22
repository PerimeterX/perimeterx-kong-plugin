FROM kong:2.8.3-ubuntu
USER root
ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt-get -qq -y install make

RUN luarocks install perimeterx-nginx-plugin
RUN ln -s /usr/local/lib/lua/px /usr/local/share/lua/5.1/px

COPY . /tmp/perimeterx-kong-plugin
RUN cd /tmp/perimeterx-kong-plugin && luarocks make
COPY kong/config/kong.yml /etc/kong/

EXPOSE 8000 8443 8001 8444

USER kong
ENTRYPOINT ["/docker-entrypoint.sh"]
STOPSIGNAL SIGQUIT

CMD ["kong", "docker-start"]
