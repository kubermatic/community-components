## component override controller

This bash-controller watches over Cluster objects and controls part of the spec.componentOverride.

In its current status it filters Clusters with non-existent spec.componentOverride.apiserver.replicas and fills them with a configurable number. It might get extended to also fill in other parts of the componentOverride spec. A project-id (or multiple) can be specified in the configuration to limit the controllers activity to that project.
