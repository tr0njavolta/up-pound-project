import models.com.upppound.app.v1alpha1 as appv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1
import datetime
import models.io.upbound.aws.s3.v1beta2 as s3v1beta2
import models.k8s.api.apps.v1 as appsv1
import models.k8s.api.core.v1 as corev1

time = datetime.ticks()
# observed composite resource
oxr = option("params").oxr
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
dbversion: any = oxr.spec.parameters.dbversion

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
        "apiVersion" = "aws.platform.upbound.io/v1alpha1"
        "kind" = "XNetwork"
        "metadata" = {
            "name" = "configuration-aws-network-kcl"
        }
        "spec" = {
            "compositionSelector" = {
                "matchLabels" = {
                    "function" = "kcl"
                }
            }
            "parameters" = {
                "id" = "{}-{}".format(baseName, id)
                "region" = region
            }
        }
    },
    {
        "apiVersion" = "aws.platform.upbound.io/v1alpha1"
        "kind" = "XEKS"
        "metadata" = {
            "name" = "configuration-aws-eks-kcl"
        }
        "spec" = {
            "compositionSelector" = {
                "matchLabels" = {
                    "function" = "kcl"
                }
            }
            "parameters" = {
                "id" = "{}-{}".format(baseName, id)
                "region" = region
                "version" = version
                "nodes" = {
                    "count" = count
                    "instanceType" = instanceType
                }
            }
        }
    },
    {
        "apiVersion" = "aws.platform.upbound.io/v1alpha1"
        "kind" = "XSQLInstance"
        "metadata" = {
            "name" = "configuration-aws-database"
        }
        "spec" = {
            "compositionSelector" = {
                "matchLabels" = {
                    "function" = "kcl"
                }
            }
            "parameters" = {
                "id" = "{}-{}".format(baseName, id)
                "engine" = engine
                "networkRef" = {
                    id = ""
                }
                "region" = region
                "storageGB" = 1
                "passwordSecretRef" = {
                    "key" = "password"
                    "name" = "psqlsecret"
                    "namespace" = "default"
                }
            }
        }
    },
    {
        "apiVersion" = "apps/v1"
        "kind" = "Deployment"
        "metadata" = _metadata("{}-frontend".format(baseName))
        "spec" = {
            "replicas" = 1
            "selector" = {
                "matchLabels" = {
                    "app" = "frontend"
                }
            }
        }

    }

]


items = _items
