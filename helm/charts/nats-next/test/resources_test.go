package test

import (
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
	"testing"
)

func TestResourceOptions(t *testing.T) {
	t.Parallel()
	test := DefaultTest()
	test.Values = `
global:
  image:
    pullPolicy: Always
    registry: docker.io
config:
  websocket:
    enabled: true
container:
  image:
    pullPolicy: IfNotPresent
    registry: gcr.io
promExporter:
  enabled: true
`
	expected := DefaultResources(t, test)

	expected.Conf.Value["websocket"] = map[string]any{
		"port":        int64(8080),
		"no_tls":      true,
		"compression": true,
	}

	dd := ddg.Get(t)
	ctr := expected.StatefulSet.Value.Spec.Template.Spec.Containers
	ctr[0].Image = "gcr.io/" + ctr[0].Image
	ctr[0].ImagePullPolicy = "IfNotPresent"
	ctr[1].Image = "docker.io/" + ctr[1].Image
	ctr[1].ImagePullPolicy = "Always"
	ctr = append(ctr, corev1.Container{
		Args: []string{
			"-connz",
			"-routez",
			"-subz",
			"-varz",
			"-prefix=nats",
			"-use_internal_server_id",
			"-jsz=all",
			"http://localhost:8222/",
		},
		Image:           "docker.io/" + dd.PromExporterImage,
		ImagePullPolicy: "Always",
		Name:            "prom-exporter",
		Ports: []corev1.ContainerPort{
			{
				Name:          "prom-metrics",
				ContainerPort: 7777,
			},
		},
	})
	expected.StatefulSet.Value.Spec.Template.Spec.Containers = ctr

	nbCtr := expected.NatsBoxDeployment.Value.Spec.Template.Spec.Containers[0]
	nbCtr.Image = "docker.io/" + nbCtr.Image
	nbCtr.ImagePullPolicy = "Always"
	expected.NatsBoxDeployment.Value.Spec.Template.Spec.Containers[0] = nbCtr

	expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].Ports = []corev1.ContainerPort{
		{
			Name:          "nats",
			ContainerPort: 4222,
		},
		{
			Name:          "websocket",
			ContainerPort: 8080,
		},
		{
			Name:          "cluster",
			ContainerPort: 6222,
		},
		{
			Name:          "monitor",
			ContainerPort: 8222,
		},
	}

	expected.HeadlessService.Value.Spec.Ports = []corev1.ServicePort{
		{
			Name:       "nats",
			Port:       4222,
			TargetPort: intstr.FromString("nats"),
		},
		{
			Name:       "websocket",
			Port:       8080,
			TargetPort: intstr.FromString("websocket"),
		},
		{
			Name:       "cluster",
			Port:       6222,
			TargetPort: intstr.FromString("cluster"),
		},
		{
			Name:       "monitor",
			Port:       8222,
			TargetPort: intstr.FromString("monitor"),
		},
	}

	expected.Service.Value.Spec.Ports = []corev1.ServicePort{
		{
			Name:       "nats",
			Port:       4222,
			TargetPort: intstr.FromString("nats"),
		},
		{
			Name:       "websocket",
			Port:       8080,
			TargetPort: intstr.FromString("websocket"),
		},
	}

	RenderAndCheck(t, test, expected)
}

func TestResourcesMergePatch(t *testing.T) {
	t.Parallel()
	test := DefaultTest()
	test.Values = `
config:
  websocket:
    enabled: true
container:
  merge:
    stdin: true
  patch: [{op: add, path: /tty, value: true}]
reloader:
  merge:
    stdin: true
  patch: [{op: add, path: /tty, value: true}]
promExporter:
  enabled: true
  merge:
    stdin: true
  patch: [{op: add, path: /tty, value: true}]
  podMonitor:
    enabled: true
    merge:
      metadata:
        annotations:
          test: test
    patch: [{op: add, path: /metadata/labels/test, value: "test"}]
service:
  enabled: true
  merge:
    metadata:
      annotations:
        test: test
  patch: [{op: add, path: /metadata/labels/test, value: "test"}]
ingress:
  enabled: true
  hosts:
  - demo.nats.io
  merge:
    metadata:
      annotations:
        test: test
  patch: [{op: add, path: /metadata/labels/test, value: "test"}]
statefulSet:
  merge:
    metadata:
      annotations:
        test: test
  patch: [{op: add, path: /metadata/labels/test, value: "test"}]
podTemplate:
  merge:
    metadata:
      annotations:
        test: test
  patch: [{op: add, path: /metadata/labels/test, value: "test"}]
headlessService:
  merge:
    metadata:
      annotations:
        test: test
  patch: [{op: add, path: /metadata/labels/test, value: "test"}]
configMap:
  merge:
    metadata:
      annotations:
        test: test
  patch: [{op: add, path: /metadata/labels/test, value: "test"}]
natsBox:
  context:
    default:
      merge:
        user: foo
      patch: [{op: add, path: /password, value: "bar"}]
  container:
    merge:
      stdin: true
    patch: [{op: add, path: /tty, value: true}]
  podTemplate:
    merge:
      metadata:
        annotations:
          test: test
    patch: [{op: add, path: /metadata/labels/test, value: "test"}]
  deployment:
    merge:
      metadata:
        annotations:
          test: test
    patch: [{op: add, path: /metadata/labels/test, value: "test"}]
  contextSecret:
    merge:
      metadata:
        annotations:
          test: test
    patch: [{op: add, path: /metadata/labels/test, value: "test"}]
  contentsSecret:
    merge:
      metadata:
        annotations:
          test: test
    patch: [{op: add, path: /metadata/labels/test, value: "test"}]
`
	expected := DefaultResources(t, test)

	expected.Conf.Value["websocket"] = map[string]any{
		"port":        int64(8080),
		"no_tls":      true,
		"compression": true,
	}

	annotations := func() map[string]string {
		return map[string]string{
			"test": "test",
		}
	}

	dd := ddg.Get(t)
	ctr := expected.StatefulSet.Value.Spec.Template.Spec.Containers
	ctr[0].Stdin = true
	ctr[0].TTY = true
	ctr[1].Stdin = true
	ctr[1].TTY = true
	ctr = append(ctr, corev1.Container{
		Args: []string{
			"-connz",
			"-routez",
			"-subz",
			"-varz",
			"-prefix=nats",
			"-use_internal_server_id",
			"-jsz=all",
			"http://localhost:8222/",
		},
		Image: dd.PromExporterImage,
		Name:  "prom-exporter",
		Ports: []corev1.ContainerPort{
			{
				Name:          "prom-metrics",
				ContainerPort: 7777,
			},
		},
		Stdin: true,
		TTY:   true,
	})
	expected.StatefulSet.Value.Spec.Template.Spec.Containers = ctr

	expected.NatsBoxDeployment.Value.Spec.Template.Spec.Containers[0].Stdin = true
	expected.NatsBoxDeployment.Value.Spec.Template.Spec.Containers[0].TTY = true

	expected.StatefulSet.Value.ObjectMeta.Annotations = annotations()
	expected.StatefulSet.Value.ObjectMeta.Labels["test"] = "test"

	expected.StatefulSet.Value.Spec.Template.ObjectMeta.Annotations = annotations()
	expected.StatefulSet.Value.Spec.Template.ObjectMeta.Labels["test"] = "test"

	expected.NatsBoxDeployment.Value.ObjectMeta.Annotations = annotations()
	expected.NatsBoxDeployment.Value.ObjectMeta.Labels["test"] = "test"

	expected.NatsBoxDeployment.Value.Spec.Template.ObjectMeta.Annotations = annotations()
	expected.NatsBoxDeployment.Value.Spec.Template.ObjectMeta.Labels["test"] = "test"

	expected.PodMonitor.HasValue = true
	expected.PodMonitor.Value.ObjectMeta.Annotations = annotations()
	expected.PodMonitor.Value.ObjectMeta.Labels["test"] = "test"

	expected.Ingress.HasValue = true
	expected.Ingress.Value.ObjectMeta.Annotations = annotations()
	expected.Ingress.Value.ObjectMeta.Labels["test"] = "test"

	expected.NatsBoxContextSecret.Value.ObjectMeta.Annotations = annotations()
	expected.NatsBoxContextSecret.Value.ObjectMeta.Labels["test"] = "test"
	expected.NatsBoxContextSecret.Value.StringData["default.json"] = `{
  "password": "bar",
  "url": "nats://` + test.FullName + `",
  "user": "foo"
}
`

	expected.NatsBoxContentsSecret.Value.ObjectMeta.Annotations = annotations()
	expected.NatsBoxContentsSecret.Value.ObjectMeta.Labels["test"] = "test"

	expected.Service.Value.ObjectMeta.Annotations = annotations()
	expected.Service.Value.ObjectMeta.Labels["test"] = "test"

	expected.HeadlessService.Value.ObjectMeta.Annotations = annotations()
	expected.HeadlessService.Value.ObjectMeta.Labels["test"] = "test"

	expected.ConfigMap.Value.ObjectMeta.Annotations = annotations()
	expected.ConfigMap.Value.ObjectMeta.Labels["test"] = "test"

	expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].Ports = []corev1.ContainerPort{
		{
			Name:          "nats",
			ContainerPort: 4222,
		},
		{
			Name:          "websocket",
			ContainerPort: 8080,
		},
		{
			Name:          "cluster",
			ContainerPort: 6222,
		},
		{
			Name:          "monitor",
			ContainerPort: 8222,
		},
	}

	expected.HeadlessService.Value.Spec.Ports = []corev1.ServicePort{
		{
			Name:       "nats",
			Port:       4222,
			TargetPort: intstr.FromString("nats"),
		},
		{
			Name:       "websocket",
			Port:       8080,
			TargetPort: intstr.FromString("websocket"),
		},
		{
			Name:       "cluster",
			Port:       6222,
			TargetPort: intstr.FromString("cluster"),
		},
		{
			Name:       "monitor",
			Port:       8222,
			TargetPort: intstr.FromString("monitor"),
		},
	}

	expected.Service.Value.Spec.Ports = []corev1.ServicePort{
		{
			Name:       "nats",
			Port:       4222,
			TargetPort: intstr.FromString("nats"),
		},
		{
			Name:       "websocket",
			Port:       8080,
			TargetPort: intstr.FromString("websocket"),
		},
	}

	RenderAndCheck(t, test, expected)
}
