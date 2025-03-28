import models.io.upbound.aws.s3.v1beta2 as s3v1beta2
import models.io.crossplane.kubernetes.v1alpha2 as k8sv1alpha2
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "xapps"
        spec= {
            assertResources: [
                s3v1beta2.Bucket {
                    metadata: {
                        name: "example-bucket-upbound"
                        annotations: {
                            "crossplane.io/composition-resource-name": "example-bucket-upbound"
                        }
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                        }
                    }
                },

                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "XNetwork"
                    metadata: {
                        name: "example-xnetwork"
                        annotations: {
                            "crossplane.io/composition-resource-name": "example-xnetwork"
                        }
                    }
                    spec: {
                        parameters: {
                            id: "example"
                            region: "us-west-2"
                        }
                    }
                },

                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "XEKS"
                    metadata: {
                        name: "example-xeks"
                        annotations: {
                            "crossplane.io/composition-resource-name": "example-xeks"
                        }
                    }
                    spec: {
                        parameters: {
                            id: "example"
                            region: "us-west-2"
                            version: "1.27"
                            nodes: {
                                count: 2
                                instanceType: "t3.small"
                            }
                        }
                    }
                },

                {
                    apiVersion = "aws.platform.upbound.io/v1alpha1"
                    kind = "XSQLInstance"
                    metadata: {
                        name: "example-xsqlinstance"
                        annotations: {
                            "crossplane.io/composition-resource-name": "example-xsqlinstance"
                        }
                    }
                    spec = {
                        parameters: {
                            engine: "postgres"
                            engineVersion: "13.18"
                            networkRef: {
                                id: "example"
                            }
                            region: "us-west-2"
                            storageGB: 5
                            autoGeneratePassword: True
                            passwordSecretRef: {
                                key: "password"
                                name: "psqlsecret"
                                namespace: "default"
                            }
                        }
                    }
                },

                k8sv1alpha2.Object {
                    metadata: {
                        name: "example-frontend-deployment"
                        annotations: {
                            "crossplane.io/composition-resource-name": "example-frontend-deployment"
                        }
                    }
                    spec: {
                        providerConfigRef: {
                            name: "example"
                        }
                        readiness: {
                            policy: "DeriveFromObject"
                        }
                        forProvider: {
                            manifest: {
                                apiVersion: "apps/v1"
                                kind: "Deployment"
                                metadata: {
                                    name: "example-frontend-deployment"
                                    namespace: "default"
                                }
                                spec: {
                                    replicas: 1
                                    selector: {
                                        matchLabels: {
                                            app: "frontend"
                                        }
                                    }
                                    template: {
                                        metadata: {
                                            labels: {
                                                app: "frontend"
                                            }
                                        }
                                        spec: {
                                            containers: [
                                            {
                                                name: "frontend"
                                                image: "tr0njavolta/uppound-demo-frontend:latest"
                                                ports: [
                                                    {
                                                        containerPort: 80
                                                    }
                                                ]
                                            }
                                            ]
                                        }
                                    }
                                }
                            }
                        }
                    }
                },

                k8sv1alpha2.Object {
                    metadata: {
                        name: "example-backend-deployment"
                        annotations: {
                            "crossplane.io/composition-resource-name": "example-backend-deployment"
                        }
                    }
                    spec: {
                        providerConfigRef: {
                            name: "example"
                        }
                        readiness: {
                            policy: "DeriveFromObject"
                        }
                        forProvider: {
                            manifest: {
                                apiVersion: "apps/v1"
                                kind: "Deployment"
                                metadata: {
                                    name: "example-backend-deployment"
                                    namespace: "default"
                                }
                                spec: {
                                    replicas: 1
                                    selector: {
                                        matchLabels: {
                                            app: "backend"
                                        }
                                    }
                                   template: {
                                        metadata: {
                                            labels: {
                                                app: "backend"
                                            }
                                        }
                                        spec: {
                                            containers: [
                                               {
                                                name: "backend"
                                                image: "tr0njavolta/uppound-demo-backend:latest"
                                                ports: [
                                                    {
                                                        containerPort: 80
                                                    }
                                                ]
                                               }
                                            ]
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

            ]
            compositionPath: "apis/xapps/kcl/composition.yaml"
            xrPath: "examples/demo/kcl/example-xr.yaml"
            xrdPath: "apis/xapps/definition.yaml"
            timeoutSeconds: 60
            validate: False
        }
    }
]
items= _items
