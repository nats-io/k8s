package test

import (
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
	"testing"
)

func TestConfigDisable(t *testing.T) {
	t.Parallel()
	test := DefaultTest()
	test.Values = `
config:
  jetstream:
    enabled: false
  cluster:
    enabled: false
  monitor:
    enabled: false
`
	expected := DefaultResources(t, test)
	delete(expected.Conf.Value, "jetstream")
	delete(expected.Conf.Value, "cluster")
	delete(expected.Conf.Value, "http_port")

	expected.StatefulSet.Value.Spec.VolumeClaimTemplates = nil
	vm := expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].VolumeMounts
	expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].VolumeMounts = append(vm[:2], vm[3:]...)
	expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].LivenessProbe = nil
	expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].ReadinessProbe = nil
	expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].StartupProbe = nil

	cp := expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].Ports
	expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].Ports = []corev1.ContainerPort{cp[0]}

	hsp := expected.HeadlessService.Value.Spec.Ports
	expected.HeadlessService.Value.Spec.Ports = []corev1.ServicePort{hsp[0]}

	RenderAndCheck(t, test, expected)
}

func TestConfigOptions(t *testing.T) {
	t.Parallel()
	test := DefaultTest()
	test.Values = `
config:
  jetstream:
    fileStore:
      dir: /mnt
      pvc:
        size: 5Gi
        storageClassName: gp3
      maxSize: 1Gi
    memoryStore:
      enabled: true
      maxSize: 2Gi
  resolver:
    enabled: true
    dir: /mnt/resolver
    pvc:
      size: 5Gi
      storageClassName: gp3
`
	expected := DefaultResources(t, test)

	expected.Conf.Value["jetstream"].(map[string]any)["store_dir"] = "/mnt"
	expected.Conf.Value["jetstream"].(map[string]any)["max_file_store"] = int64(1073741824)
	expected.Conf.Value["jetstream"].(map[string]any)["max_memory_store"] = int64(2147483648)
	expected.Conf.Value["resolver"] = map[string]any{
		"dir": "/mnt/resolver",
	}

	vct := expected.StatefulSet.Value.Spec.VolumeClaimTemplates
	resource5Gi, _ := resource.ParseQuantity("5Gi")
	storageClassGp3 := "gp3"
	vct[0].Spec.StorageClassName = &storageClassGp3
	vct[0].Spec.Resources.Requests["storage"] = resource5Gi
	expected.StatefulSet.Value.Spec.VolumeClaimTemplates = append(vct, corev1.PersistentVolumeClaim{
		ObjectMeta: v1.ObjectMeta{
			Name: test.FullName + "-resolver",
		},
		Spec: corev1.PersistentVolumeClaimSpec{
			AccessModes: []corev1.PersistentVolumeAccessMode{
				"ReadWriteOnce",
			},
			Resources: corev1.ResourceRequirements{
				Requests: corev1.ResourceList{
					"storage": resource5Gi,
				},
			},
			StorageClassName: &storageClassGp3,
		},
	})

	vm := expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].VolumeMounts
	vm[2].MountPath = "/mnt/jetstream"
	expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].VolumeMounts = append(vm, corev1.VolumeMount{
		MountPath: "/mnt/resolver",
		Name:      test.FullName + "-resolver",
	})

	RenderAndCheck(t, test, expected)
}

func TestConfigMergePatch(t *testing.T) {
	t.Parallel()
	test := DefaultTest()
	test.Values = `
config:
  merge:
    ping_interval: 5m
  patch: [{op: add, path: /ping_max, value: 3}]
  jetstream:
    merge:
      max_outstanding_catchup: "<< 64MB >>"
    patch: [{op: add, path: /max_file_store, value: "<< 1GB >>"}]
    fileStore:
      pvc:
        merge:
          spec:
            storageClassName: gp3
        patch: [{op: add, path: /spec/accessModes/-, value: ReadWriteMany}]
  leafnodes:
    enabled: true
    merge:
      no_advertise: false
    patch: [{op: add, path: /advertise, value: "demo.nats.io:7422"}]
  websocket:
    enabled: true
    merge:
      compression: false
    patch: [{op: add, path: /same_origin, value: true}]
  mqtt:
    enabled: true
    merge:
      ack_wait: 1m
    patch: [{op: add, path: /max_ack_pending, value: 100}]
  cluster:
    merge:
      no_advertise: false
    patch: [{op: add, path: /advertise, value: "demo.nats.io:4222"}]
  gateway:
    enabled: true
    merge:
      gateways:
      - name: nats
        url: nats://demo.nats.io:7222
    patch: [{op: add, path: /advertise, value: "demo.nats.io:7222"}]
  resolver:
    enabled: true
    merge:
      type: full
    patch: [{op: add, path: /allow_delete, value: true}]
    pvc:
      merge:
        spec:
          storageClassName: gp3
      patch: [{op: add, path: /spec/accessModes/-, value: ReadWriteMany}]
`
	expected := DefaultResources(t, test)
	expected.Conf.Value["ping_interval"] = "5m"
	expected.Conf.Value["ping_max"] = int64(3)
	expected.Conf.Value["jetstream"].(map[string]any)["max_file_store"] = int64(1073741824)
	expected.Conf.Value["jetstream"].(map[string]any)["max_outstanding_catchup"] = int64(67108864)
	expected.Conf.Value["leafnodes"] = map[string]any{
		"port":         int64(7422),
		"no_advertise": false,
		"advertise":    "demo.nats.io:7422",
	}
	expected.Conf.Value["websocket"] = map[string]any{
		"port":        int64(8080),
		"compression": false,
		"no_tls":      true,
		"same_origin": true,
	}
	expected.Conf.Value["mqtt"] = map[string]any{
		"port":            int64(1883),
		"ack_wait":        "1m",
		"max_ack_pending": int64(100),
	}
	expected.Conf.Value["cluster"].(map[string]any)["no_advertise"] = false
	expected.Conf.Value["cluster"].(map[string]any)["advertise"] = "demo.nats.io:4222"
	expected.Conf.Value["gateway"] = map[string]any{
		"port":      int64(7222),
		"name":      "nats",
		"advertise": "demo.nats.io:7222",
		"gateways": []any{
			map[string]any{
				"name": "nats",
				"url":  "nats://demo.nats.io:7222",
			},
		},
	}
	expected.Conf.Value["resolver"] = map[string]any{
		"dir":          "/data/resolver",
		"type":         "full",
		"allow_delete": true,
	}

	vct := expected.StatefulSet.Value.Spec.VolumeClaimTemplates
	resource1Gi, _ := resource.ParseQuantity("1Gi")
	storageClassGp3 := "gp3"
	vct[0].Spec.StorageClassName = &storageClassGp3
	vct[0].Spec.AccessModes = append(vct[0].Spec.AccessModes, "ReadWriteMany")
	expected.StatefulSet.Value.Spec.VolumeClaimTemplates = append(vct, corev1.PersistentVolumeClaim{
		ObjectMeta: v1.ObjectMeta{
			Name: test.FullName + "-resolver",
		},
		Spec: corev1.PersistentVolumeClaimSpec{
			AccessModes: []corev1.PersistentVolumeAccessMode{
				"ReadWriteOnce",
				"ReadWriteMany",
			},
			Resources: corev1.ResourceRequirements{
				Requests: corev1.ResourceList{
					"storage": resource1Gi,
				},
			},
			StorageClassName: &storageClassGp3,
		},
	})

	vm := expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].VolumeMounts
	expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].VolumeMounts = append(vm, corev1.VolumeMount{
		MountPath: "/data/resolver",
		Name:      test.FullName + "-resolver",
	})

	expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].Ports = []corev1.ContainerPort{
		{
			Name:          "nats",
			ContainerPort: 4222,
		},
		{
			Name:          "leafnodes",
			ContainerPort: 7422,
		},
		{
			Name:          "websocket",
			ContainerPort: 8080,
		},
		{
			Name:          "mqtt",
			ContainerPort: 1883,
		},
		{
			Name:          "cluster",
			ContainerPort: 6222,
		},
		{
			Name:          "gateway",
			ContainerPort: 7222,
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
			Name:       "leafnodes",
			Port:       7422,
			TargetPort: intstr.FromString("leafnodes"),
		},
		{
			Name:       "websocket",
			Port:       8080,
			TargetPort: intstr.FromString("websocket"),
		},
		{
			Name:       "mqtt",
			Port:       1883,
			TargetPort: intstr.FromString("mqtt"),
		},
		{
			Name:       "cluster",
			Port:       6222,
			TargetPort: intstr.FromString("cluster"),
		},
		{
			Name:       "gateway",
			Port:       7222,
			TargetPort: intstr.FromString("gateway"),
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
			Name:       "leafnodes",
			Port:       7422,
			TargetPort: intstr.FromString("leafnodes"),
		},
		{
			Name:       "websocket",
			Port:       8080,
			TargetPort: intstr.FromString("websocket"),
		},
		{
			Name:       "mqtt",
			Port:       1883,
			TargetPort: intstr.FromString("mqtt"),
		},
	}

	RenderAndCheck(t, test, expected)
}

func TestConfigTls(t *testing.T) {
	t.Parallel()
	test := DefaultTest()
	test.Values = `
config:
  nats:
    tls:
      enabled: true
      secretName: nats-tls
      ca: tls.ca
      merge:
        verify_cert_and_check_known_urls: true
      patch: [{op: add, path: /verify_and_map, value: true}]
  leafnodes:
    enabled: true
    tls:
      enabled: true
      secretName: leafnodes-tls
  websocket:
    enabled: true
    tls:
      enabled: true
      secretName: websocket-tls
  mqtt:
    enabled: true
    tls:
      enabled: true
      secretName: mqtt-tls
  cluster:
    tls:
      enabled: true
      secretName: cluster-tls
  gateway:
    enabled: true
    tls:
      enabled: true
      secretName: gateway-tls
`
	expected := DefaultResources(t, test)
	expected.Conf.Value["leafnodes"] = map[string]any{
		"port":         int64(7422),
		"no_advertise": true,
	}
	expected.Conf.Value["websocket"] = map[string]any{
		"port":        int64(8080),
		"compression": true,
	}
	expected.Conf.Value["mqtt"] = map[string]any{
		"port": int64(1883),
	}
	expected.Conf.Value["gateway"] = map[string]any{
		"port": int64(7222),
		"name": "nats",
	}

	volumes := expected.StatefulSet.Value.Spec.Template.Spec.Volumes
	natsVm := expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].VolumeMounts
	reloaderVm := expected.StatefulSet.Value.Spec.Template.Spec.Containers[1].VolumeMounts
	for _, protocol := range []string{"nats", "leafnodes", "websocket", "mqtt", "cluster", "gateway"} {
		tls := map[string]any{
			"cert_file": "/etc/nats-certs/" + protocol + "/tls.crt",
			"key_file":  "/etc/nats-certs/" + protocol + "/tls.key",
		}
		if protocol == "nats" {
			tls["ca_file"] = "/etc/nats-certs/" + protocol + "/tls.ca"
			tls["verify"] = true
			tls["verify_cert_and_check_known_urls"] = true
			tls["verify_and_map"] = true
			expected.Conf.Value["tls"] = tls
		} else {
			expected.Conf.Value[protocol].(map[string]any)["tls"] = tls
		}

		volumes = append(volumes, corev1.Volume{
			Name: protocol + "-tls",
			VolumeSource: corev1.VolumeSource{
				Secret: &corev1.SecretVolumeSource{
					SecretName: protocol + "-tls",
				},
			},
		})

		natsVm = append(natsVm, corev1.VolumeMount{
			MountPath: "/etc/nats-certs/" + protocol,
			Name:      protocol + "-tls",
		})

		reloaderVm = append(reloaderVm, corev1.VolumeMount{
			MountPath: "/etc/nats-certs/" + protocol,
			Name:      protocol + "-tls",
		})
	}

	expected.StatefulSet.Value.Spec.Template.Spec.Volumes = volumes
	expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].VolumeMounts = natsVm
	expected.StatefulSet.Value.Spec.Template.Spec.Containers[1].VolumeMounts = reloaderVm

	// reloader certs are alphabetized
	reloaderArgs := expected.StatefulSet.Value.Spec.Template.Spec.Containers[1].Args
	for _, protocol := range []string{"cluster", "gateway", "leafnodes", "mqtt", "nats", "websocket"} {
		if protocol == "nats" {
			reloaderArgs = append(reloaderArgs, "-config", "/etc/nats-certs/"+protocol+"/tls.ca")
		}
		reloaderArgs = append(reloaderArgs, "-config", "/etc/nats-certs/"+protocol+"/tls.crt", "-config", "/etc/nats-certs/"+protocol+"/tls.key")
	}

	expected.StatefulSet.Value.Spec.Template.Spec.Containers[1].Args = reloaderArgs

	expected.StatefulSet.Value.Spec.Template.Spec.Containers[0].Ports = []corev1.ContainerPort{
		{
			Name:          "nats",
			ContainerPort: 4222,
		},
		{
			Name:          "leafnodes",
			ContainerPort: 7422,
		},
		{
			Name:          "websocket",
			ContainerPort: 8080,
		},
		{
			Name:          "mqtt",
			ContainerPort: 1883,
		},
		{
			Name:          "cluster",
			ContainerPort: 6222,
		},
		{
			Name:          "gateway",
			ContainerPort: 7222,
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
			Name:       "leafnodes",
			Port:       7422,
			TargetPort: intstr.FromString("leafnodes"),
		},
		{
			Name:       "websocket",
			Port:       8080,
			TargetPort: intstr.FromString("websocket"),
		},
		{
			Name:       "mqtt",
			Port:       1883,
			TargetPort: intstr.FromString("mqtt"),
		},
		{
			Name:       "cluster",
			Port:       6222,
			TargetPort: intstr.FromString("cluster"),
		},
		{
			Name:       "gateway",
			Port:       7222,
			TargetPort: intstr.FromString("gateway"),
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
			Name:       "leafnodes",
			Port:       7422,
			TargetPort: intstr.FromString("leafnodes"),
		},
		{
			Name:       "websocket",
			Port:       8080,
			TargetPort: intstr.FromString("websocket"),
		},
		{
			Name:       "mqtt",
			Port:       1883,
			TargetPort: intstr.FromString("mqtt"),
		},
	}

	RenderAndCheck(t, test, expected)
}

func TestConfigInclude(t *testing.T) {
	t.Parallel()
	test := DefaultTest()
	test.Values = `
config:
  jetstream:
    merge:
      000$include: "js.conf"
  merge:
    $include: "my-config.conf"
    zzz$include: "my-config-last.conf"
configMap:
  merge:
    data:
      js.conf: |
        max_file_store:  1GB
        max_outstanding_catchup: 64MB
      my-config.conf: |
        ping_interval: "5m"
      my-config-last.conf: |
        ping_max: 3
`
	expected := DefaultResources(t, test)
	expected.Conf.Value["ping_interval"] = "5m"
	expected.Conf.Value["ping_max"] = int64(3)
	expected.Conf.Value["jetstream"].(map[string]any)["max_file_store"] = int64(1073741824)
	expected.Conf.Value["jetstream"].(map[string]any)["max_outstanding_catchup"] = int64(67108864)

	expected.ConfigMap.Value.Data = map[string]string{
		"js.conf": `max_file_store:  1GB
max_outstanding_catchup: 64MB
`,
		"my-config.conf": `ping_interval: "5m"
`,
		"my-config-last.conf": `ping_max: 3
`,
	}

	reloaderArgs := expected.StatefulSet.Value.Spec.Template.Spec.Containers[1].Args
	reloaderArgs = append(reloaderArgs, "-config", "/etc/nats-config/my-config.conf")
	reloaderArgs = append(reloaderArgs, "-config", "/etc/nats-config/js.conf")
	reloaderArgs = append(reloaderArgs, "-config", "/etc/nats-config/my-config-last.conf")
	expected.StatefulSet.Value.Spec.Template.Spec.Containers[1].Args = reloaderArgs

	RenderAndCheck(t, test, expected)
}
