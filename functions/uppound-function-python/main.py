from crossplane.function import resource
from crossplane.function.proto.v1 import run_function_pb2 as fnv1
# Example to add models as import; update as needed
# from .model.io.upbound.aws.s3.bucket import v1beta1 as bucketv1beta1
from .model.io.crossplane.kubernetes import v1alpha2 as k8sv1alpha2
from .model.io.uppound.app import v1alpha1 as appv1alpha1


def compose(req: fnv1.RunFunctionRequest, rsp: fnv1.RunFunctionResponse):
    observed_xr = appv1alpha1.XApp(**req.observed.composite.resource)
    baseName = "{}".format(observed_xr.metadata.name)

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
