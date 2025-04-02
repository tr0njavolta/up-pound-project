import models.com.uppound.app.v1alpha1 as appv1alpha1
import models.io.upbound.aws.s3.v1beta2 as s3v1beta2
import models.io.crossplane.kubernetes.v1alpha2 as k8sv1alpha2

oxr = appv1alpha1.XApp {**option("params").oxr}
_ocds = option("params").ocds
_dxr = option("params").dxr
dcds = option("params").dcds

_metadata = lambda name: str -> any {
    {
        name: name
        annotations = {"krm.kcl.dev/composition-resource-name" = name}
    }
}

# This fetches the RDSInstance composed by the XSQLInstance XR, since the URL it's serving from gets posted on the status of this resource.
_details = {
    apiVersion: "meta.krm.kcl.dev/v1alpha1"
    kind: "ExtraResources"
    requirements = {
        rdsInstance = {
            apiVersion: "rds.aws.upbound.io/v1beta1",
            kind: "Instance",
            matchLabels: {
                "crossplane.io/claim-name": oxr.metadata.labels["crossplane.io/claim-name"]
            }
        }
    }
}
_dbUrl = ""
if _er?.rdsInstance:
    _dbUrl = _er?.rdsInstance[0]?.Resource?.status?.atProvider?.address or ""

_items = [
    # bucket config
    s3v1beta2.Bucket {
        metadata: _metadata("{}-bucket-{}".format(oxr.metadata.name, "upbound"))
        spec = {
            forProvider: {
                region: oxr.spec.parameters.region
            }
        }
    },

    {
        apiVersion: "aws.platform.upbound.io/v1alpha1"
        kind: "XNetwork"
        metadata: _metadata("{}-xnetwork".format(oxr.metadata.name))
        spec: {
            parameters: {
                id: oxr.metadata.name
                region: oxr.spec.parameters.region
            }
        }
    },

    {
        apiVersion: "aws.platform.upbound.io/v1alpha1"
        kind: "XEKS"
        metadata: _metadata("{}-xeks".format(oxr.metadata.name))
        spec: {
            parameters: {
                id: oxr.metadata.name
                region: oxr.spec.parameters.region
                version: oxr.spec.parameters.version
                nodes: {
                    count: oxr.spec.parameters.nodes.count
                    instanceType: oxr.spec.parameters.nodes.instanceType
                }
            }
        }
    },

    {
        apiVersion = "aws.platform.upbound.io/v1alpha1"
        kind = "XSQLInstance"
        metadata: _metadata("{}-xsqlinstance".format(oxr.metadata.name))
        spec = {
            parameters: {
                engine: oxr.spec.parameters.engine
                engineVersion: oxr.spec.parameters.dbVersion
                networkRef: {
                    id: oxr.metadata.name
                }
                region: oxr.spec.parameters.region
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
        metadata: _metadata("{}-frontend-deployment".format(oxr.metadata.name))
        spec: {
            providerConfigRef: {
                name: oxr.metadata.name
            }
            readiness: {
                policy: "DeriveFromObject"
            }
            forProvider: {
                manifest: {
                    apiVersion: "apps/v1"
                    kind: "Deployment"
                    metadata: _metadata("{}-frontend-deployment".format(oxr.metadata.name)) | {
                        namespace: "default" # ToDo(haarchri): you want to hardcode this namespace?
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
                                    image: oxr.spec.parameters.containers[0].image
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
        metadata: _metadata("{}-backend-deployment".format(oxr.metadata.name))
        spec: {
            providerConfigRef: {
                name: oxr.metadata.name
            }
            readiness: {
                policy: "DeriveFromObject"
            }
            forProvider: {
                manifest: {
                    apiVersion: "apps/v1"
                    kind: "Deployment"
                    metadata: _metadata("{}-backend-deployment".format(oxr.metadata.name)) | {
                        namespace: "default" # ToDo(haarchri): you want to hardcode this namespace?
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
                                    image: oxr.spec.parameters.containers[1].image
                                    env: [
                                        {
                                            name: 'DATABASE_URL'
                                            value: _dbUrl
                                        }
                                    ]
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

items = _items
