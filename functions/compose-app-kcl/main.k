import models.com.uppound.app.v1alpha1 as appv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1
import datetime
import models.io.upbound.aws.s3.v1beta2 as s3v1beta2
import models.io.crossplane.kubernetes.v1alpha2 as k8sv1alpha2
import models.io.crossplane.kubernetes.v1alpha1 as k8sv1alpha1


time = datetime.ticks()
# observed composite resource
oxr =  appv1alpha1.XApp {**option("params").oxr}
# observed composed resources
_ocds = option("params").ocds
# desired composite resource
_dxr = option("params").dxr
# desired composed resources
dcds = option("params").dcds

id: any = oxr.spec.parameters.id
region = oxr.spec.parameters.region
version: any = oxr.spec.parameters.version
instanceType: any = oxr.spec.parameters.nodes.instanceType
count: any = oxr.spec.parameters.nodes.count
size: any = oxr.spec.parameters.size
engine: any = oxr.spec.parameters.engine
baseName = "{}-{}".format(oxr.metadata.name, time)
dbversion: any = oxr.spec.parameters.dbVersion

_metadata = lambda name: str -> any {
    {
        annotations = {"krm.kcl.dev/composition-resource-name" = name}
    }
}

_items = [
    # bucket config
    s3v1beta2.Bucket {
        metadata: _metadata("{}-bucket".format(baseName))
        spec = {
            forProvider: {
                region: region
            }
        }
    },
    {
        apiVersion = "aws.platform.upbound.io/v1alpha1"
        kind = "XNetwork"
        metadata = {
            name = "configuration-aws-network-kcl"
        }
        spec = {
            parameters = {
                id = "{}-{}".format(baseName, id)
                region = region
            }
        }
    },
    {
        apiVersion = "aws.platform.upbound.io/v1alpha1"
        kind = "XEKS"
        metadata = {
            name = "configuration-aws-eks-kcl"
        }
        spec = {
            parameters = {
                id = "{}-{}".format(baseName, id)
                region = region
                version = version
                nodes = {
                    count = count
                    instanceType = instanceType
                }
            }
            writeConnectionSecretToRef = {
                name: "configuration-aws-eks-kcl-kubeconfig"
                namespace: oxr.spec?.claimRef?.namespace or "default"
            }
        }
    },
    {
        apiVersion = "aws.platform.upbound.io/v1alpha1"
        kind = "XSQLInstance"
        metadata = {
            name = "configuration-aws-database"
        }
        spec = {
            parameters = {
                engine = engine
                engineVersion = dbversion
                networkRef = {
                    id = "configuration-aws-network-kcl"
                }
                region = region
                storageGB = 1
                passwordSecretRef = {
                    key = "password"
                    name = "psqlsecret"
                    namespace = "default"
                }
            }
            writeConnectionSecretToRef = {
                name: "configuration-aws-database-postgres"
                namespace: oxr.spec?.claimRef?.namespace or "default"
            }
        }
    },
    k8sv1alpha2.Object {
        metadata = _metadata("app-deployment-frontend")
        metadata.name = "app-deployment-frontend"
        spec.forProvider.manifest = {
            apiVersion = "apps/v1"
            kind = "Deployment"
            metadata = _metadata("{}-frontend".format(baseName))
            spec = {
                replicas = 1
                selector = {
                    matchLabels = {
                        app = "frontend"
                    }
                }
            }
        }
    },
    k8sv1alpha2.Object {
        metadata = _metadata("app-deployment-backend")
        metadata.name = "app-deployment-backend"
        spec.forProvider.manifest = {
            apiVersion = "apps/v1"
            kind = "Deployment"
            metadata = _metadata("{}-backend".format(baseName))
            spec = {
                replicas = 1
                selector = {
                    matchLabels = {
                        app = "backend"
                    }
                }
            }
        }
    },
    k8sv1alpha1.ProviderConfig {
        metadata = _metadata("eks-providerconfig")
        metadata.name = "default"
        spec.credentials = {
            source: "Secret"
            secretRef = {
                key: "kubeconfig"
                name: "configuration-aws-eks-kcl-kubeconfig"
                namespace: "default"
            }
        }
    }
]

items = _items
