/*
 * wl-inhibit -- hold a Wayland idle inhibitor until terminated.
 *
 * Creates a zwp_idle_inhibitor_v1 on a bare surface and blocks. While this
 * process runs, any compositor that honours idle-inhibit (labwc does) stops
 * sending idle notifications, so swayidle will not lock/blank/hibernate.
 *
 * Build:
 *   cc -O2 -o wl-inhibit wl-inhibit.c $(pkg-config --cflags --libs wayland-client)
 *
 * Minimal hand-written bindings for idle-inhibit-unstable-v1, to avoid needing
 * the wayland-protocols package at build time.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-client.h>

struct zwp_idle_inhibitor_v1;
struct zwp_idle_inhibit_manager_v1;

#define ZWP_IDLE_INHIBIT_MANAGER_V1_DESTROY 0
#define ZWP_IDLE_INHIBIT_MANAGER_V1_CREATE_INHIBITOR 1
#define ZWP_IDLE_INHIBITOR_V1_DESTROY 0

extern const struct wl_interface zwp_idle_inhibitor_v1_interface;

static const struct wl_interface *idle_inhibit_types[] = {
	&zwp_idle_inhibitor_v1_interface,
	&wl_surface_interface,
};

static const struct wl_message idle_inhibit_manager_requests[] = {
	{ "destroy", "", NULL },
	{ "create_inhibitor", "no", idle_inhibit_types },
};

const struct wl_interface zwp_idle_inhibit_manager_v1_interface = {
	"zwp_idle_inhibit_manager_v1", 1,
	2, idle_inhibit_manager_requests,
	0, NULL,
};

static const struct wl_message idle_inhibitor_requests[] = {
	{ "destroy", "", NULL },
};

const struct wl_interface zwp_idle_inhibitor_v1_interface = {
	"zwp_idle_inhibitor_v1", 1,
	1, idle_inhibitor_requests,
	0, NULL,
};

static inline struct zwp_idle_inhibitor_v1 *
zwp_idle_inhibit_manager_v1_create_inhibitor(
	struct zwp_idle_inhibit_manager_v1 *manager, struct wl_surface *surface)
{
	struct wl_proxy *id = wl_proxy_marshal_flags(
		(struct wl_proxy *)manager,
		ZWP_IDLE_INHIBIT_MANAGER_V1_CREATE_INHIBITOR,
		&zwp_idle_inhibitor_v1_interface,
		wl_proxy_get_version((struct wl_proxy *)manager), 0, NULL, surface);
	return (struct zwp_idle_inhibitor_v1 *)id;
}

static struct zwp_idle_inhibit_manager_v1 *inhibit_manager;
static struct wl_compositor *compositor;

static void
registry_global(void *data, struct wl_registry *registry, uint32_t name,
		const char *interface, uint32_t version)
{
	(void)data;
	(void)version;
	if (!strcmp(interface, zwp_idle_inhibit_manager_v1_interface.name)) {
		inhibit_manager = wl_registry_bind(registry, name,
			&zwp_idle_inhibit_manager_v1_interface, 1);
	} else if (!strcmp(interface, wl_compositor_interface.name)) {
		compositor = wl_registry_bind(registry, name,
			&wl_compositor_interface, 4);
	}
}

static void
registry_global_remove(void *data, struct wl_registry *registry, uint32_t name)
{
	(void)data;
	(void)registry;
	(void)name;
}

static const struct wl_registry_listener registry_listener = {
	.global = registry_global,
	.global_remove = registry_global_remove,
};

int
main(void)
{
	struct wl_display *display = wl_display_connect(NULL);
	if (!display) {
		fprintf(stderr, "wl-inhibit: cannot connect to Wayland display\n");
		return 1;
	}

	struct wl_registry *registry = wl_display_get_registry(display);
	wl_registry_add_listener(registry, &registry_listener, NULL);
	wl_display_roundtrip(display);

	if (!inhibit_manager || !compositor) {
		fprintf(stderr, "wl-inhibit: idle-inhibit protocol not supported\n");
		return 2;
	}

	struct wl_surface *surface = wl_compositor_create_surface(compositor);
	struct zwp_idle_inhibitor_v1 *inhibitor =
		zwp_idle_inhibit_manager_v1_create_inhibitor(inhibit_manager, surface);
	if (!inhibitor) {
		fprintf(stderr, "wl-inhibit: failed to create inhibitor\n");
		return 3;
	}

	wl_display_flush(display);
	while (wl_display_dispatch(display) != -1) {
		/* hold the inhibitor until terminated */
	}

	return 0;
}
