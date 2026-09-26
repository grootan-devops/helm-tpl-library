# Migration Guide

This document records required consumer actions when upgrading between releases.
Breaking changes must include an entry before release.

## 1.3.0

No breaking changes. Workloads may now leave `.Values.containers.<name>.image.repository` empty to automatically derive the standard `{global.partOf}/{component}/{subComponent}` image repository path. Explicit repository values remain fully supported.

## 1.2.0

No consumer configuration changes are required. Start at the README index and follow its
task-specific documentation links; update any bookmarks to moved sections. Existing chart templates remain compatible.

## 1.1.0

No migration is required. Existing consumers can continue to use the chart
templates with the new chart version.

## 1.0.0

No migration is required for the initial release.
