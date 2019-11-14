FROM synadia/nats-box:latest

ENV KUBECTL_VERSION 1.16.2
ENV DEFAULT_NSC_DIR /nsc

RUN set -eux; \
	wget -O /kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl; \
	chmod +x /kubectl && mv /kubectl /usr/local/bin/kubectl

COPY nats-setup.sh /usr/local/bin/nats-setup.sh
ENTRYPOINT []
CMD ["/bin/sleep", "300"]
