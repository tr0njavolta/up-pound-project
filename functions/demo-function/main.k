import models.com.upppound.app.v1alpha1 as appv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1
import models.io.upbound.aws.s3.v1beta2 as s3v1beta2
import models.io.crossplane.helm.v1alpha1 as helmv1alpha1
import models.io.crossplane.helm.v1beta1 as helmv1beta1
import models.io.crossplane.kubernetes.v1alpha1 as kubernetesv1alpha1
import models.io.crossplane.kubernetes.v1alpha2 as kubernetesv1alpha2
import models.io.upbound.aws.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.aws.ec2.v1beta2 as ec2v1beta2
import models.io.upbound.aws.eks.v1beta1 as eksv1beta1
import models.io.upbound.aws.eks.v1beta2 as eksv1beta2
import models.io.upbound.aws.iam.v1beta1 as iamv1beta1
import models.io.upbound.aws.rds.v1beta1 as rdsv1beta1
import models.io.upbound.aws.rds.v1beta2 as rdsv1beta2
import models.io.upbound.aws.rds.v1beta3 as rdsv1beta3
import models.io.upbound.aws.s3.v1beta1 as s3v1beta1
import models.io.upbound.aws.s3.v1beta2 as s3v1beta2
import models.io.upbound.aws.v1alpha1 as awsv1alpha1
import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1
import datetime


_metadata = lambda name: str -> any {
    {
        annotations = {"krm.kcl.dev/composition-resource-name" = name}
    }
}

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

# Infrastructure resources (non-namespaced)
_items = [
    # bucket config
    s3v1beta2.Bucket {
        metadata = {
            annotations = {
                "krm.kcl.dev/composition-resource-name": "{}-bucket".format(baseName)
            }
        }
        spec = {
            forProvider: {
                region: region
            }
        }
    }
    # Create network infrastructure
    {
        "apiVersion": "aws.platform.upbound.io/v1alpha1"
        "kind": "XNetwork"
        "metadata": {
            "name": "configuration-aws-network-kcl"
            "annotations": {
                "krm.kcl.dev/composition-resource-name": "{}-network".format(baseName)
                "render.crossplane.io/composition-path": "apis/kcl/composition.yaml"
                "render.crossplane.io/function-path": "examples/functions.yaml"
            }
        }
        "spec": {
            "compositionSelector": {
                "matchLabels": {
                    "function": "kcl"
                }
            }
            "parameters": {
                "id": "{}-{}".format(baseName, id)
                "region": "us-east-2"
                "vpcCidrBlock": "192.168.0.0/16"
                "subnets": [
                    {
                        "availabilityZone": "{}a".format(region)
                        "cidrBlock": "192.168.0.0/18"
                        "type": "public"
                    }
                    {
                        "availabilityZone": "{}b".format(region)
                        "cidrBlock": "192.168.64.0/18"
                        "type": "public"
                    }
                    {
                        "availabilityZone": "{}a".format(region)
                        "cidrBlock": "192.168.128.0/18"
                        "type": "private"
                    }
                    {
                        "availabilityZone": "{}b".format(region)
                        "cidrBlock": "192.168.192.0/18"
                        "type": "private"
                    }
                ]
            }
        }
    }
    {
        "apiVersion": "aws.platform.upbound.io/v1alpha1"
        "kind": "XEKS"
        "metadata": {
            "name": "configuration-aws-eks-kcl"
            "annotations": {
                "krm.kcl.dev/composition-resource-name": "{}-eks".format(baseName)
                "render.crossplane.io/composition-path": "apis/kcl/composition.yaml"
                "render.crossplane.io/function-path": "examples/functions.yaml"
            }
        }
        "spec": {
            "compositionSelector": {
                "matchLabels": {
                    "function": "kcl"
                }
            }
            "parameters": {
                "id": "{}-{}".format(baseName, id)
                "region": region
                "version": version
                "nodes": {
                    "count": count
                    "instanceType": instanceType
                }
            }
            "writeConnectionSecretToRef": {
                "name": "{}-eks-kubeconfig".format(baseName)
                "namespace": "default"
            }
        }
    }
    {
        "apiVersion": "aws.platform.upbound.io/v1alpha1"
        "kind": "XSQLInstance"
        "metadata": {
            "name": "configuration-aws-database"
            "annotations": {
                "krm.kcl.dev/composition-resource-name": "{}-database".format(baseName)
                "render.crossplane.io/composition-path": "apis/kcl/composition.yaml"
                "render.crossplane.io/function-path": "examples/functions.yaml"
            }
        }
        "spec": {
            "compositionSelector": {
                "matchLabels": {
                    "function": "kcl"
                }
            }
            "parameters": {
                "engine": engine
                "networkRef": {
                    "id": "{}-{}".format(baseName, id)
                }
                "region": region
                "storageGB": 2
                "passwordSecretRef": {
                    "key": "password"
                    "name": "psqlsecret"
                    "namespace": "default"
                }
            }
            "writeConnectionSecretToRef": {
                "name": "{}-db-connection".format(baseName)
                "namespace": "default"
            }
        }
    }
]

items = _items

