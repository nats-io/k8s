# Running NATS on K8S

In this repository you can find several examples of how to deploy NATS
and NATS Streaming on Kubernetes.

### Getting started

The fastest and easiest way to get started is with just one shell command:

```sh
curl -sSL https://nats-io.github.io/k8s/setup.sh | sh
```

This will run a `nats-setup` container with the [required policy](https://github.com/nats-io/k8s/blob/master/setup/bootstrap-policy.yml)
and deploy a NATS cluster on Kubernetes with external access, TLS and
decentralized authorization.

By default, the installer will deploy the [Prometheus Operator](https://github.com/coreos/prometheus-operator) and the
[Cert Manager](https://github.com/jetstack/cert-manager) for metrics and TLS support, and the NATS instances will
also bind the 4222 host port for external access.

You can customize the installer to install without TLS or without Auth
to have a simpler setup as follows:

```sh
# Disable TLS
curl -sSL https://nats-io.github.io/k8s/setup.sh | sh -s -- --without-tls

# Disable Auth and TLS (also disables NATS surveyor and NATS Streaming)
curl -sSL https://nats-io.github.io/k8s/setup.sh | sh -s -- --without-tls --without-auth
```

**Note**: Since NATS Streaming will be running as a leafnode to NATS
(under the STAN account) and that NATS Surveyor requires the system
account to monitor events, disabling auth also means that NATS
Streaming and NATS Surveyor based monitoring will be disabled.

#### Example

Running the installer setup with the defaults:

```
curl -sSL https://nats-io.github.io/k8s/setup.sh |  sh
serviceaccount/nats-setup created
clusterrolebinding.rbac.authorization.k8s.io/nats-setup-binding created
clusterrole.rbac.authorization.k8s.io/nats-setup created
pod/nats-setup created
pod/nats-setup condition met

##############################################
#                                            #
#  _   _    _  _____ ____   _  _____ ____    #
# | \ | |  / \|_   _/ ___| | |/ ( _ ) ___|   #
# |  \| | / _ \ | | \___ \ | ' // _ \___ \   #
# | |\  |/ ___ \| |  ___) || . \ (_) |__) |  #
# |_| \_/_/   \_\_| |____(_)_|\_\___/____/   #
#                                            #
##############################################

 +---------------------+---------------------+
 |                 OPTIONS                   |
 +---------------------+---------------------+
         nats server   | true                
         nats surveyor | true      
         nats tls      | true           
        enable auth    | true          
  install cert_manager | true  
      nats streaming   | true          
 +-------------------------------------------+
 |                                           |
 | Starting setup...                         |
 |                                           |
 +-------------------------------------------+

[ OK ] generated and stored operator key "OBGRWYNKEB7WBTUF4UW7FIVGSPZND4YRWBXUL33OYIOBJ4DK2QTCIVTI"
[ OK ] added operator "KO"
[ OK ] generated and stored account key "ADZUTBLE7KYVZQJY33ETGVVQTO4WWNTRKU5QJGVTGULGQR7BNDCAX6HO"
[ OK ] added account "SYS"
[ OK ] generated and stored user key "UDN6THNKUIAN6XCRJR3GRGKLBDDQJR7WQU2VGBOY2ZE5B5YX67WU6KR2"
[ OK ] generated user creds file "/nsc/nkeys/creds/KO/SYS/sys.creds"
[ OK ] added user "sys" to account "SYS"
[ OK ] generated and stored account key "AATABTBQMBAWEEJ4PJMSX2WVDEQP3P36F73LNZMS6XW6E43ZDGSMZV3Q"
[ OK ] added account "TEST"
[ OK ] generated and stored user key "UA6BIMAJ3L5HXWY66LY6ZBAFZMWNC5BPTDSIQO32CWLSZ2DGLMGV3CVV"
[ OK ] generated user creds file "/nsc/nkeys/creds/KO/TEST/test.creds"
[ OK ] added user "test" to account "TEST"
[ OK ] generated and stored account key "AB2IZ6UF43CAY2XO52PTLBXN3NPGXWLDNPC3XFDKEV4ZVPGM6XLS6HRN"
[ OK ] added account "STAN"
[ OK ] generated and stored user key "UDMAVGWD6QRJZYWF7JY6UHMCOL7EIKOWPT4FWWL3GAJBAJTKOAY5YXH3"
[ OK ] generated user creds file "/nsc/nkeys/creds/KO/STAN/stan.creds"
[ OK ] added user "stan" to account "STAN"
secret/nats-sys-creds created
secret/nats-test-creds created
secret/stan-creds created
configmap/nats-accounts created
customresourcedefinition.apiextensions.k8s.io/challenges.acme.cert-manager.io configured
customresourcedefinition.apiextensions.k8s.io/orders.acme.cert-manager.io configured
customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io configured
customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io configured
customresourcedefinition.apiextensions.k8s.io/clusterissuers.cert-manager.io configured
customresourcedefinition.apiextensions.k8s.io/issuers.cert-manager.io configured
namespace/cert-manager unchanged
serviceaccount/cert-manager-cainjector unchanged
serviceaccount/cert-manager unchanged
serviceaccount/cert-manager-webhook unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-cainjector unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-cainjector unchanged
role.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection unchanged
rolebinding.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection configured
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-webhook:auth-delegator configured
rolebinding.rbac.authorization.k8s.io/cert-manager-webhook:webhook-authentication-reader configured
clusterrole.rbac.authorization.k8s.io/cert-manager-webhook:webhook-requester unchanged
role.rbac.authorization.k8s.io/cert-manager:leaderelection unchanged
rolebinding.rbac.authorization.k8s.io/cert-manager:leaderelection configured
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-issuers unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificates unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-orders unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-challenges unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-leaderelection unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-issuers unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificates unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-orders unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-challenges unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-view unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-edit unchanged
service/cert-manager unchanged
service/cert-manager-webhook unchanged
deployment.apps/cert-manager-cainjector configured
deployment.apps/cert-manager unchanged
deployment.apps/cert-manager-webhook configured
apiservice.apiregistration.k8s.io/v1beta1.webhook.cert-manager.io unchanged
mutatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook unchanged
validatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook unchanged
clusterissuer.cert-manager.io/selfsigning unchanged
certificate.cert-manager.io/nats-ca configured
issuer.cert-manager.io/nats-ca unchanged
certificate.cert-manager.io/nats-server-tls configured
certificate.cert-manager.io/nats-client-tls configured
configmap/nats-config created
service/nats created
statefulset.apps/nats created
serviceaccount/nats-server unchanged
clusterrole.rbac.authorization.k8s.io/nats-server unchanged
clusterrolebinding.rbac.authorization.k8s.io/nats-server-binding unchanged
pod/nats-box created
configmap/stan-config unchanged
service/stan unchanged
statefulset.apps/stan created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-operator unchanged
clusterrole.rbac.authorization.k8s.io/prometheus-operator unchanged
deployment.apps/prometheus-operator created
serviceaccount/prometheus-operator unchanged
service/prometheus-operator created
serviceaccount/prometheus unchanged
clusterrole.rbac.authorization.k8s.io/prometheus unchanged
clusterrolebinding.rbac.authorization.k8s.io/prometheus unchanged
service/nats-prometheus created
prometheus.monitoring.coreos.com/nats-prometheus created
servicemonitor.monitoring.coreos.com/nats unchanged
service/grafana created
deployment.apps/nats-surveyor-grafana created
service/nats-surveyor-prometheus created
deployment.apps/nats-surveyor created
service/nats-surveyor created
prometheus.monitoring.coreos.com/nats-surveyor created
servicemonitor.monitoring.coreos.com/nats-surveyor unchanged
pod/nats-0 condition met
pod/nats-box condition met

 +------------------------------------------+
 |                                          |
 | Done. Enjoy your new NATS cluster!       |
 |                                          |
 +------------------------------------------+

=== Getting started

You can now start receiving and sending messages using 
the nats-box instance deployed into your namespace:

  kubectl exec -it pod/nats-box /bin/sh

Using the test user account:

  nats-sub -creds /var/run/nats/creds/test/test.creds -s nats 'test.>' &
  nats-pub -creds /var/run/nats/creds/test/test.creds -s nats test.hi 'Hello World'

Using the system account:

  nats-sub -creds /var/run/nats/creds/sys/sys.creds -s nats://nats:4222 '>'

The nats-box also includes nats-top which you can use to
inspect the flow of messages from one of the members
of the cluster.

  nats-top -s nats

NATS Streaming with persistence is also available as part of your cluster.
It is installed under the STAN account so you can use the following credentials:

  stan-pub -creds /var/run/nats/creds/stan/stan.creds -s nats -c stan test.hi 'Hello World'
  stan-sub -creds /var/run/nats/creds/stan/stan.creds -s nats -c stan 'test.>'

You can also connect to your monitoring dashboard:

  kubectl port-forward deployments/nats-surveyor-grafana 3000:3000

Then open the following in your browser:

  http://127.0.0.1:3000/d/nats/nats-surveyor?refresh=5s&orgId=1
```
