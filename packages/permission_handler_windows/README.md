# Mimio Windows permission handler patch

Vendored from permission_handler_windows 0.2.1 (Baseflow), retaining AUTHORS and LICENSE.

Upstream eagerly creates a Geolocator and registers PositionChanged in the plugin constructor, including when only microphone permissions are used. Mimio has no location feature. This fork removes all native geolocation objects, subscriptions and location service queries; location service status falls through to NOT_APPLICABLE. Other permission handlers are unchanged. The root dependency override ensures this patch also applies to mini-window engine registration and survives pub get.

Do not replace this fork with the hosted package until its startup geolocation side effect is absent and regression coverage passes.
