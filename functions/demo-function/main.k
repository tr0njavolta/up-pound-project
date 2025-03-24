import models.com.uppound.app.v1alpha1 as appv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1
import datetime
import models.io.upbound.aws.ec2.v1beta1 as ec2v1alpha1
import models.io.upbound.aws.ec2.v1beta2 as ec2v1beta2
import models.io.upbound.aws.eks.v1beta1 as eksv1beta1
import models.io.upbound.aws.eks.v1beta2 as eksv1beta2
import models.io.upbound.aws.iam.v1beta1 as iamv1beta1
import models.io.upbound.aws.rds.v1beta1 as rdsv1beta1
import models.io.upbound.aws.rds.v1beta2 as rdsv1beta2
import models.io.upbound.aws.rds.v1beta3 as rdsv1beta3
import models.io.upbound.aws.s3.v1beta1 as s3v1beta1
import models.io.upbound.aws.s3.v1beta2 as s3v1beta2

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
engine: any =oxr.spec.parameters.engine
baseName = "{}-{}".format(oxr.metadata.name, time)


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
    }
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
    }
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
    }
    {
        "apiVersion" = "aws.platform.upbound.io/v1alpha1"
        "kind" = "XRDS"
        "metadata" = {
            "name" = "configuration-aws-rds"
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
            }
        }
    }
]

items = _items
