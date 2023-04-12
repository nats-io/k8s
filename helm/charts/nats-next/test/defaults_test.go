package test

import (
	"github.com/stretchr/testify/require"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
	"testing"
)

func TestDefault(t *testing.T) {
	r := HelmRender(t, &Test{})

	require.True(t, r.Conf.HasValue)
	require.Equal(t, map[string]any{
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
	}, r.Conf.Value)

	require.True(t, r.ConfigMap.HasValue)
	require.True(t, r.HeadlessService.HasValue)
	require.False(t, r.Ingress.HasValue)
	require.True(t, r.NatsBoxContentsSecret.HasValue)
	require.True(t, r.NatsBoxContextSecret.HasValue)

	require.True(t, r.Service.HasValue)
	require.Equal(t, []corev1.ServicePort{
		{
			Name:       "nats",
			Port:       4222,
			TargetPort: intstr.FromString("nats"),
		},
	}, r.Service.Value.Spec.Ports)

	require.True(t, r.StatefulSet.HasValue)
	require.False(t, r.PodMonitor.HasValue)
	require.False(t, r.ExtraResource0.HasValue)
	require.False(t, r.ExtraResource1.HasValue)
}
