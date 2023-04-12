package test

import (
	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	"github.com/stretchr/testify/require"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
	"sync"
	"testing"
)

type DynamicDefaults struct {
	VersionLabel      string
	HelmChartLabel    string
	NatsImage         string
	PromExporterImage string
	ReloaderImage     string
	NatsBoxImage      string
}

type DynamicDefaultsGetter struct {
	mu  sync.Mutex
	set bool
	dd  DynamicDefaults
}

var ddg DynamicDefaultsGetter

func (d *DynamicDefaultsGetter) Get(t *testing.T) DynamicDefaults {
	t.Helper()

	d.mu.Lock()
	defer d.mu.Unlock()
	if d.set {
		return d.dd
	}

	test := DefaultTest()
	test.Values = `
promExporter:
  enabled: true
`
	r := HelmRender(t, test)

	require.True(t, r.StatefulSet.HasValue)

	var ok bool
	d.dd.VersionLabel, ok = r.StatefulSet.Value.Labels["app.kubernetes.io/version"]
	require.True(t, ok)
	d.dd.HelmChartLabel, ok = r.StatefulSet.Value.Labels["helm.sh/chart"]
	require.True(t, ok)

	containers := r.StatefulSet.Value.Spec.Template.Spec.Containers
	require.Len(t, containers, 3)
	d.dd.NatsImage = containers[0].Image
	d.dd.ReloaderImage = containers[1].Image
	d.dd.PromExporterImage = containers[2].Image

	require.True(t, r.NatsBoxDeployment.HasValue)
	containers = r.NatsBoxDeployment.Value.Spec.Template.Spec.Containers
	require.Len(t, containers, 1)
	d.dd.NatsBoxImage = containers[0].Image

	return d.dd
}

func DefaultResources(t *testing.T, test *Test) *Resources {
	fullName := test.FullName
	chartName := test.ChartName
	releaseName := test.ReleaseName

	dd := ddg.Get(t)
	dr := GenerateResources(fullName)

	natsLabels := map[string]string{
		"app.kubernetes.io/component":  "nats",
		"app.kubernetes.io/instance":   releaseName,
		"app.kubernetes.io/managed-by": "Helm",
		"app.kubernetes.io/name":       chartName,
		"app.kubernetes.io/version":    dd.VersionLabel,
		"helm.sh/chart":                dd.HelmChartLabel,
	}
	natsSelectorLabels := map[string]string{
		"app.kubernetes.io/component": "nats",
		"app.kubernetes.io/instance":  releaseName,
		"app.kubernetes.io/name":      chartName,
	}
	natsBoxLabels := map[string]string{
		"app.kubernetes.io/component":  "nats-box",
		"app.kubernetes.io/instance":   releaseName,
		"app.kubernetes.io/managed-by": "Helm",
		"app.kubernetes.io/name":       chartName,
		"app.kubernetes.io/version":    dd.VersionLabel,
		"helm.sh/chart":                dd.HelmChartLabel,
	}
	natsBoxSelectorLabels := map[string]string{
		"app.kubernetes.io/component": "nats-box",
		"app.kubernetes.io/instance":  releaseName,
		"app.kubernetes.io/name":      chartName,
	}

	oneReplica := int32(1)
	trueBool := true
	resource10Gi, _ := resource.ParseQuantity("10Gi")

	return &Resources{
		Conf: Resource[map[string]any]{
			ID:       dr.Conf.ID,
			HasValue: true,
			Value: map[string]any{
				"cluster": map[string]any{
					"name":         "nats",
					"no_advertise": true,
					"port":         int64(6222),
					"routes": []any{
						"nats://nats-0.nats-headless:6222",
					},
				},
				"http_port": int64(8222),
				"jetstream": map[string]any{
					"max_memory_store": int64(0),
					"store_dir":        "/data",
				},
				"lame_duck_duration":     "30s",
				"lame_duck_grace_period": "10s",
				"pid_file":               "/var/run/nats/nats.pid",
				"port":                   int64(4222),
				"server_name":            "nats-0",
			},
		},
		ConfigMap: Resource[corev1.ConfigMap]{
			ID:       dr.ConfigMap.ID,
			HasValue: true,
			Value: corev1.ConfigMap{
				TypeMeta: v1.TypeMeta{
					Kind:       "ConfigMap",
					APIVersion: "v1",
				},
				ObjectMeta: v1.ObjectMeta{
					Name:   fullName + "-config",
					Labels: natsLabels,
				},
			},
		},
		HeadlessService: Resource[corev1.Service]{
			ID:       dr.HeadlessService.ID,
			HasValue: true,
			Value: corev1.Service{
				TypeMeta: v1.TypeMeta{
					Kind:       "Service",
					APIVersion: "v1",
				},
				ObjectMeta: v1.ObjectMeta{
					Name:   fullName + "-headless",
					Labels: natsLabels,
				},
				Spec: corev1.ServiceSpec{
					Ports: []corev1.ServicePort{
						{
							Name:       "nats",
							Port:       4222,
							TargetPort: intstr.FromString("nats"),
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
					},
					Selector:                 natsSelectorLabels,
					ClusterIP:                "None",
					PublishNotReadyAddresses: true,
				},
			},
		},
		Ingress: Resource[networkingv1.Ingress]{
			ID:       dr.Ingress.ID,
			HasValue: false,
			Value: networkingv1.Ingress{
				TypeMeta: v1.TypeMeta{
					Kind:       "Ingress",
					APIVersion: "v1",
				},
				ObjectMeta: v1.ObjectMeta{
					Name:   fullName + "-ws",
					Labels: natsLabels,
				},
			},
		},
		NatsBoxContentsSecret: Resource[corev1.Secret]{
			ID:       dr.NatsBoxContentsSecret.ID,
			HasValue: true,
			Value: corev1.Secret{
				TypeMeta: v1.TypeMeta{
					Kind:       "Secret",
					APIVersion: "v1",
				},
				ObjectMeta: v1.ObjectMeta{
					Name:   fullName + "-box-contents",
					Labels: natsBoxLabels,
				},
				Type: "Opaque",
			},
		},
		NatsBoxContextSecret: Resource[corev1.Secret]{
			ID:       dr.NatsBoxContextSecret.ID,
			HasValue: true,
			Value: corev1.Secret{
				TypeMeta: v1.TypeMeta{
					Kind:       "Secret",
					APIVersion: "v1",
				},
				ObjectMeta: v1.ObjectMeta{
					Name:   fullName + "-box-context",
					Labels: natsBoxLabels,
				},
				Type: "Opaque",
				StringData: map[string]string{
					"default.json": `{
  "url": "nats://` + fullName + `"
}
`,
				},
			},
		},
		NatsBoxDeployment: Resource[appsv1.Deployment]{
			ID:       dr.NatsBoxDeployment.ID,
			HasValue: true,
			Value: appsv1.Deployment{
				TypeMeta: v1.TypeMeta{
					Kind:       "Deployment",
					APIVersion: "apps/v1",
				},
				ObjectMeta: v1.ObjectMeta{
					Name:   fullName + "-box",
					Labels: natsBoxLabels,
				},
				Spec: appsv1.DeploymentSpec{
					Replicas: &oneReplica,
					Selector: &v1.LabelSelector{
						MatchLabels: natsBoxSelectorLabels,
					},
					Template: corev1.PodTemplateSpec{
						ObjectMeta: v1.ObjectMeta{
							Labels: natsBoxLabels,
						},
						Spec: corev1.PodSpec{
							Containers: []corev1.Container{
								{
									Args: []string{
										"-c",
										`mkdir -p "$XDG_CONFIG_HOME/nats"
cd "$XDG_CONFIG_HOME/nats"
if ! [ -s context ]; then
  ln -s /etc/nats-context context
fi
if ! [ -f context.txt ]; then
  echo -n "default" > context.txt
fi
stop_signal () {
  exit 0
}
trap stop_signal SIGINT SIGTERM
while true; do
  sleep 0.1
done
`,
									},
									Command:         []string{"sh"},
									Image:           dd.NatsBoxImage,
									ImagePullPolicy: "IfNotPresent",
									Name:            "nats-box",
									VolumeMounts: []corev1.VolumeMount{
										{
											MountPath: "/etc/nats-context",
											Name:      "context",
										},
										{
											MountPath: "/etc/nats-contents",
											Name:      "contents",
										},
									},
								},
							},
							Volumes: []corev1.Volume{
								{
									Name: "context",
									VolumeSource: corev1.VolumeSource{
										Secret: &corev1.SecretVolumeSource{
											SecretName: "nats-box-context",
										},
									},
								},
								{
									Name: "contents",
									VolumeSource: corev1.VolumeSource{
										Secret: &corev1.SecretVolumeSource{
											SecretName: "nats-box-contents",
										},
									},
								},
							},
						},
					},
				},
			},
		},
		Service: Resource[corev1.Service]{
			ID:       dr.Service.ID,
			HasValue: true,
			Value: corev1.Service{
				TypeMeta: v1.TypeMeta{
					Kind:       "Service",
					APIVersion: "v1",
				},
				ObjectMeta: v1.ObjectMeta{
					Name:   fullName,
					Labels: natsLabels,
				},
				Spec: corev1.ServiceSpec{
					Ports: []corev1.ServicePort{
						{
							Name:       "nats",
							Port:       4222,
							TargetPort: intstr.FromString("nats"),
						},
					},
					Selector: natsSelectorLabels,
				},
			},
		},
		StatefulSet: Resource[appsv1.StatefulSet]{
			ID:       dr.StatefulSet.ID,
			HasValue: true,
			Value: appsv1.StatefulSet{
				TypeMeta: v1.TypeMeta{
					Kind:       "StatefulSet",
					APIVersion: "apps/v1",
				},
				ObjectMeta: v1.ObjectMeta{
					Name:   fullName,
					Labels: natsLabels,
				},
				Spec: appsv1.StatefulSetSpec{
					Replicas: &oneReplica,
					Selector: &v1.LabelSelector{
						MatchLabels: natsSelectorLabels,
					},
					Template: corev1.PodTemplateSpec{
						ObjectMeta: v1.ObjectMeta{
							Labels: natsLabels,
						},
						Spec: corev1.PodSpec{
							Containers: []corev1.Container{
								{
									Args: []string{
										"--config",
										"/etc/nats-config/nats.conf",
									},
									Image:           dd.NatsImage,
									ImagePullPolicy: "IfNotPresent",
									Lifecycle: &corev1.Lifecycle{
										PreStop: &corev1.LifecycleHandler{
											Exec: &corev1.ExecAction{
												Command: []string{
													"nats-server",
													"-sl=ldm=/var/run/nats/nats.pid",
												},
											},
										},
									},
									LivenessProbe: &corev1.Probe{
										ProbeHandler: corev1.ProbeHandler{
											HTTPGet: &corev1.HTTPGetAction{
												Path: "/healthz?js-enabled-only=true",
												Port: intstr.FromString("monitor"),
											},
										},
										InitialDelaySeconds: 10,
										TimeoutSeconds:      5,
										PeriodSeconds:       30,
										SuccessThreshold:    1,
										FailureThreshold:    3,
									},
									Name: "nats",
									Ports: []corev1.ContainerPort{
										{
											Name:          "nats",
											ContainerPort: 4222,
										},
										{
											Name:          "cluster",
											ContainerPort: 6222,
										},
										{
											Name:          "monitor",
											ContainerPort: 8222,
										},
									},
									ReadinessProbe: &corev1.Probe{
										ProbeHandler: corev1.ProbeHandler{
											HTTPGet: &corev1.HTTPGetAction{
												Path: "/healthz?js-server-only=true",
												Port: intstr.FromString("monitor"),
											},
										},
										InitialDelaySeconds: 10,
										TimeoutSeconds:      5,
										PeriodSeconds:       10,
										SuccessThreshold:    1,
										FailureThreshold:    3,
									},
									StartupProbe: &corev1.Probe{
										ProbeHandler: corev1.ProbeHandler{
											HTTPGet: &corev1.HTTPGetAction{
												Path: "/healthz",
												Port: intstr.FromString("monitor"),
											},
										},
										InitialDelaySeconds: 10,
										TimeoutSeconds:      5,
										PeriodSeconds:       10,
										SuccessThreshold:    1,
										FailureThreshold:    90,
									},
									VolumeMounts: []corev1.VolumeMount{
										{
											MountPath: "/etc/nats-config",
											Name:      "config",
										},
										{
											MountPath: "/var/run/nats",
											Name:      "pid",
										},
										{
											MountPath: "/data/jetstream",
											Name:      fullName + "-js",
										},
									},
								},
								{
									Args: []string{
										"-pid",
										"/var/run/nats/nats.pid",
										"-config",
										"/etc/nats-config/nats.conf",
									},
									Image:           dd.ReloaderImage,
									ImagePullPolicy: "IfNotPresent",
									Name:            "reloader",
									VolumeMounts: []corev1.VolumeMount{
										{
											MountPath: "/var/run/nats",
											Name:      "pid",
										},
										{
											MountPath: "/etc/nats-config",
											Name:      "config",
										},
									},
								},
							},
							ShareProcessNamespace: &trueBool,
							Volumes: []corev1.Volume{
								{
									Name: "config",
									VolumeSource: corev1.VolumeSource{
										ConfigMap: &corev1.ConfigMapVolumeSource{
											LocalObjectReference: corev1.LocalObjectReference{
												Name: "nats-config",
											},
										},
									},
								},
								{
									Name: "pid",
									VolumeSource: corev1.VolumeSource{
										EmptyDir: &corev1.EmptyDirVolumeSource{},
									},
								},
							},
						},
					},
					VolumeClaimTemplates: []corev1.PersistentVolumeClaim{
						{
							ObjectMeta: v1.ObjectMeta{
								Name: fullName + "-js",
							},
							Spec: corev1.PersistentVolumeClaimSpec{
								AccessModes: []corev1.PersistentVolumeAccessMode{
									"ReadWriteOnce",
								},
								Resources: corev1.ResourceRequirements{
									Requests: corev1.ResourceList{
										"storage": resource10Gi,
									},
								},
							},
						},
					},
					ServiceName:         fullName + "-headless",
					PodManagementPolicy: "Parallel",
				},
			},
		},
		PodMonitor: Resource[monitoringv1.PodMonitor]{
			ID:       dr.PodMonitor.ID,
			HasValue: false,
			Value: monitoringv1.PodMonitor{
				TypeMeta: v1.TypeMeta{
					Kind:       "PodMonitor",
					APIVersion: "v1",
				},
				ObjectMeta: v1.ObjectMeta{
					Name:   fullName,
					Labels: natsLabels,
				},
			},
		},
		ExtraResource0: Resource[corev1.ConfigMap]{
			ID:       dr.ExtraResource0.ID,
			HasValue: false,
			Value: corev1.ConfigMap{
				TypeMeta: v1.TypeMeta{
					Kind:       "ConfigMap",
					APIVersion: "v1",
				},
				ObjectMeta: v1.ObjectMeta{
					Name:   fullName + "-extra",
					Labels: natsLabels,
				},
			},
		},
		ExtraResource1: Resource[corev1.Service]{
			ID:       dr.ExtraResource1.ID,
			HasValue: false,
			Value: corev1.Service{
				TypeMeta: v1.TypeMeta{
					Kind:       "Service",
					APIVersion: "v1",
				},
				ObjectMeta: v1.ObjectMeta{
					Name:   fullName + "-extra",
					Labels: natsLabels,
				},
			},
		},
	}
}

func TestDefaultValues(t *testing.T) {
	t.Parallel()
	test := DefaultTest()
	expected := DefaultResources(t, test)
	RenderAndCheck(t, test, expected)
}
