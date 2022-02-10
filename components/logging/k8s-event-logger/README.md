# K8s event logger 
K8s event logger puts all the k8s events in the cluster as logs. The log collector(for example promtail) running in the cluster can collect these logs and push them to the log store(for example loki) where they can be stored and used for debugging/monitoring purposes.

Source - https://github.com/max-rocket-internet/k8s-event-logger