from crossplane.function import resource
from crossplane.function.proto.v1 import run_function_pb2 as fnv1
from .model.io.upbound.aws.s3.bucket import v1beta1 as bucketv1beta1
from .model.com.uppound.app.xapp import v1alpha1 as appv1alpha1
from datetime import datetime


def compose(req: fnv1.RunFunctionRequest, rsp: fnv1.RunFunctionResponse):
    # Retrieve the composite resource 
    observed_xr = appv1alpha1.XApp(**req.observed.composite.resource)
    baseName = "{}-{}".format(observed_xr.metadata.name, datetime.now())

    # Example S3 Bucket managed resource configuration; update as needed
    bucket = bucketv1beta1.Bucket(
        spec=bucketv1beta1.Spec(
            forProvider=bucketv1beta1.ForProvider(
                region=observed_xr.spec.region,
            ),
        ),
    )
    resource.update(rsp.desired.resources["bucket"], bucket)

    configurationAwsNetwork = any(
        kind="XNetwork",
        apiVersion="aws.platform.upbound.io/v1alpha1",
        metadata=any(
            name="configuration-aws-network",
        ),
        spec=any(
            parameters=any(
                id="{}-{}".format(baseName, id),
                region=observed_xr.spec.region,
            ),
        ),
    )
    resource.update(rsp.desired.resources["configurationAwsNetwork"], configurationAwsNetwork)

    configurationAwsEks = any(
        kind="XEKS",
        apiVersion="aws.platform.upbound.io/v1alpha1",
        metadata=any(
            name="configuration-aws-eks",
        ),
        spec=any(
            parameters=any(
                id="{}-{}".format(baseName, id),
                region=observed_xr.spec.region,
                version=observed_xr.spec.version,
                nodes=any(
                    count=observed_xr.spec.count,
                    instanceType=observed_xr.spec.instanceType
                )
            ),
        ),
    )
    resource.update(rsp.desired.resources["configurationAwsEks"], configurationAwsEks)

    configurationAwsDatabase = any(
        kind="XSQLInstance",
        apiVersion="aws.platform.upbound.io/v1alpha1",
        metadata=any(
            name="configuration-aws-database",
        ),
        spec=any(
            parameters=any(
                id="{}-{}".format(baseName, id),
                region=observed_xr.spec.region,
                engine=observed_xr.spec.engine,
                storageGb=1,
                passwordSecretRef=any(
                    key="password",
                    name="psqlsecret",
                    namespace="default"
                )
            ),
        ),
    )
    resource.update(rsp.desired.resources["configurationAwsDatabase"], configurationAwsDatabase)

    deployment = any(
        kind="Object",
        apiVersion="kubernetes.crossplane.io/v1alpha2",
        metadata=any(
            name="app-deployment",
        ),
        spec=any(
            forProvider=any(
                manifest=any(
                    kind="Deployment",
                    apiVersion="apps/v1",
                    metadata=any(
                        name="app-deployment",
                    ),
                    spec=any(
                        replicas=1,
                        selector=any(
                            matchLabels=any(
                                app="frontend"
                            )
                        )
                    )
                )
            ),
        ),
    )
    resource.update(rsp.desired.resources["deployment"], deployment)
