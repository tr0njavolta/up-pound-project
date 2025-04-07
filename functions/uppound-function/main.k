import models.io.crossplane.kubernetes.v1alpha2 as k8sv1alpha2
import models.io.uppound.app.v1alpha1 as appv1alpha1

oxr = appv1alpha1.XApp {**option("params").oxr}
_ocds = option("params").ocds
_dxr = option("params").dxr
dcds = option("params").dcds
_er = option("params")?.extraResources

_metadata = lambda name: str -> any {
    {
        name: name
        annotations = {"krm.kcl.dev/composition-resource-name" = name}
    }
}

_items = [
    # Network
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
    }
    # EKS
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
    }
    # Frontend Deployment
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
                                        image: oxr.spec.parameters.containers[0].image
                                        ports: [
                                            {
                                                containerPort: 80
                                            }
                                        ]
                                        env: [
                                            {
                                                name: "REACT_APP_API_URL"
                                                value: "/api"
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
    # Frontend Service
    k8sv1alpha2.Object {
        metadata: _metadata("{}-frontend-service".format(oxr.metadata.name))
        spec: {
            providerConfigRef: {
                name: oxr.metadata.name
            }
            readiness: {
                policy: "DeriveFromObject"
            }
            forProvider: {
                manifest: {
                    apiVersion: "v1"
                    kind: "Service"
                    metadata: {
                        name: "{}-frontend-service".format(oxr.metadata.name)
                        namespace: "default"
                        annotations: {
                            "service.beta.kubernetes.io/aws-load-balancer-type": "nlb"
                            "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled": "true"
                        }
                    }
                    spec: {
                        selector: {
                            app: "frontend"
                        }
                        ports: [
                            {
                                port: 80
                                targetPort: 80
                            }
                        ]
                        type: "LoadBalancer"
                    }
                }
            }
        }
    }
    # Backend Deployment
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
                                        image: oxr.spec.parameters.containers[1].image
                                        env: [
                                            {
                                                name: "DATABASE_URL"
                                                value: "postgres://postgres:postgres@{}-postgres-service:5432/uppound".format(oxr.metadata.name)

                                            }
                                            {
                                                name: "PORT"
                                                value: "3001"
                                            }
                                            {
                                                name: "DB_MAX_RETRIES"
                                                value: "15"
                                            }
                                            {
                                                name: "DB_RETRY_INTERVAL"
                                                value: "5000"
                                            }
                                        ]
                                        ports: [
                                            {
                                                containerPort: 3001
                                            }
                                        ]
                                        readinessProbe: {
                                            httpGet: {
                                                path: "/health"
                                                port: 3001
                                            }
                                            initialDelaySeconds: 15
                                            periodSeconds: 10
                                            timeoutSeconds: 5
                                            successThreshold: 1
                                            failureThreshold: 3
                                        }
                                        livenessProbe: {
                                            httpGet: {
                                                path: "/health"
                                                port: 3001
                                            }
                                            initialDelaySeconds: 20
                                            periodSeconds: 20
                                            timeoutSeconds: 5
                                            successThreshold: 1
                                            failureThreshold: 3
                                        }
                                        resources: {
                                            requests: {
                                                memory: "256Mi"
                                                cpu: "100m"
                                            }
                                            limits: {
                                                memory: "512Mi"
                                                cpu: "500m"
                                            }
                                        }
                                        volumeMounts: [
                                            {
                                                name: "uploads-volume"
                                                mountPath: "/app/uploads"
                                            }
                                            {
                                                name: "images-volume"
                                                mountPath: "/app/images"
                                            }
                                        ]
                                    }
                                ]
                                volumes: [
                                    {
                                        name: "uploads-volume"
                                        emptyDir: {}
                                    }
                                    {
                                        name: "images-volume"
                                        emptyDir: {}
                                    }
                                ]
                            }
                        }
                    }
                }
            }
        }
    }
    # Backend Service
    k8sv1alpha2.Object {
        metadata: _metadata("{}-backend-service".format(oxr.metadata.name))
        spec: {
            providerConfigRef: {
                name: oxr.metadata.name
            }
            readiness: {
                policy: "DeriveFromObject"
            }
            forProvider: {
                manifest: {
                    apiVersion: "v1"
                    kind: "Service"
                    metadata: {
                        name: "backend"
                        namespace: "default"
                    }
                    spec: {
                        selector: {
                            app: "backend"
                        }
                        ports: [
                            {
                                port: 3001
                                targetPort: 3001
                            }
                        ]
                        type: "ClusterIP"
                    }
                }
            }
        }
    }
    # PostgreSQL Deployment
    k8sv1alpha2.Object {
        metadata: _metadata("{}-postgres-deployment".format(oxr.metadata.name))
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
                    metadata: _metadata("{}-postgres-deployment".format(oxr.metadata.name)) | {
                        namespace: "default"
                    }
                    spec: {
                        replicas: 1
                        selector: {
                            matchLabels: {
                                app: "postgres"
                            }
                        }
                        template: {
                            metadata: {
                                labels: {
                                    app: "postgres"
                                }
                            }
                            spec: {
                                containers: [
                                    {
                                        name: "postgres"
                                        image: "postgres:13.18"
                                        env: [
                                            {
                                                name: "POSTGRES_USER"
                                                value: "postgres"
                                            }
                                            {
                                                name: "POSTGRES_PASSWORD"
                                                value: "postgres"
                                            }
                                            {
                                                name: "POSTGRES_DB"
                                                value: "uppound"
                                            }
                                            {
                                                name: "POSTGRES_HOST_AUTH_METHOD"
                                                value: "trust"
                                            }
                                        ]
                                        ports: [
                                            {
                                                containerPort: 5432
                                            }
                                        ]
                                        volumeMounts: [
                                            {
                                                name: "postgres-data"
                                                mountPath: "/var/lib/postgresql/data"
                                                subPath: "postgres-db"
                                            }
                                            {
                                                name: "db-schema"
                                                mountPath: "/docker-entrypoint-initdb.d"
                                            }
                                        ]
                                        resources: {
                                            requests: {
                                                memory: "256Mi"
                                                cpu: "100m"
                                            }
                                            limits: {
                                                memory: "512Mi"
                                                cpu: "500m"
                                            }
                                        }
                                        readinessProbe: {
                                            exec: {
                                                command: ["pg_isready", "-U", "postgres"]
                                            }
                                            initialDelaySeconds: 5
                                            periodSeconds: 10
                                        }
                                        livenessProbe: {
                                            exec: {
                                                command: ["pg_isready", "-U", "postgres"]
                                            }
                                            initialDelaySeconds: 15
                                            periodSeconds: 20
                                        }
                                    }
                                ]
                                volumes: [
                                    {
                                        name: "postgres-data"
                                        persistentVolumeClaim: {
                                            claimName: "postgres-data-pvc"
                                        }
                                    }
                                    {
                                        name: "db-schema"
                                        configMap: {
                                            name: "db-schema"
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            }
        }
    }
    # PostgreSQL Service
    k8sv1alpha2.Object {
        metadata: _metadata("{}-postgres-service".format(oxr.metadata.name))
        spec: {
            providerConfigRef: {
                name: oxr.metadata.name
            }
            readiness: {
                policy: "DeriveFromObject"
            }
            forProvider: {
                manifest: {
                    apiVersion: "v1"
                    kind: "Service"
                    metadata: {
                        name: "{}-postgres-service".format(oxr.metadata.name)
                        namespace: "default"
                    }
                    spec: {
                        selector: {
                            app: "postgres"
                        }
                        ports: [
                            {
                                port: 5432
                                targetPort: 5432
                            }
                        ]
                        type: "ClusterIP"
                    }
                }
            }
        }
    }
    # Database Schema ConfigMap
    k8sv1alpha2.Object {
        metadata: _metadata("{}-db-schema".format(oxr.metadata.name))
        spec: {
            providerConfigRef: {
                name: oxr.metadata.name
            }
            forProvider: {
                manifest: {
                    apiVersion: "v1"
                    kind: "ConfigMap"
                    metadata: {
                        name: "db-schema"
                        namespace: "default"
                    }
                    data: {
                        "init.sql": """CREATE TABLE IF NOT EXISTS pets (
                          id SERIAL PRIMARY KEY,
                          name VARCHAR(255) NOT NULL,
                          species VARCHAR(100) NOT NULL,
                          breed VARCHAR(100),
                          age INT,
                          description TEXT,
                          image_url VARCHAR(255)
                        );
                        CREATE TABLE IF NOT EXISTS adoptions (
                          id SERIAL PRIMARY KEY,
                          pet_id INT REFERENCES pets(id),
                          applicant_name VARCHAR(255) NOT NULL,
                          email VARCHAR(255) NOT NULL,
                          phone VARCHAR(50),
                          message TEXT,
                          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        );
                        INSERT INTO pets (name, species, breed, age, description, image_url)
                        VALUES 
                          ('Hayden', 'Cat', 'Longhair domestic', 10, 'A sleepy, cuddly companion who can say "Hello" when she wants food.', '/images/hayden.jpg'),
                          ('Milo', 'Dog', 'English Springer Spaniel', 1, 'Sweet and energetic puppy who loves attention', '/images/milo.jpg'),
                          ('Phelix', 'Cat', 'Shorthair domestic', 1, 'Curious and playful kitten', '/images/phelix.jpg'),
                          ('Jerry', 'Small', 'Ferret', 100, 'A wizard turned into a ferret after a spell gone wrong.', '/images/jerry.jpg'),
                          ('Boogie', 'Dog', 'French Bulldog', 5, 'A lazy, loyal family dog', '/images/boogie.jpg'),
                          ('Artemis', 'Cat', 'Tabby', 6, 'Artemis is blinged-out. If you have to ask you can''t afford her', '/images/artemis.jpg'),
                          ('Simon', 'Cat', 'American Shorthair', 5, 'Cross-eyed and cuddly, Simon only has eyes for you', '/images/simon.jpg'),
                          ('Eva', 'Dog', 'Bearded Collie', 16, 'She isn''t just a good dog, she''s the best dog, and will not tolerate any other dog that gets in the way of that', '/images/eva.jpg'),
                          ('Rosie', 'Dog', 'Airedale', 5,'Rosie''s always up for an adventure... or a nap...','/images/rosie.jpg'),
                          ('Winnie', 'Dog', 'Mini Schauzer', 5,'Winnie *allegedly* commited some light breaking and entering for a PupCup' ,'/images/winnie.jpg'),
                          ('Luffy', 'Cat', 'Tuxedo', 5,'Luffy''s always ready for a black-tie event' ,'/images/luffy.jpg'),
                          ('Minik', 'Cat', 'Shorthair domestic', 6,'Minik loves treats, catnip, and controlling the weather with his mind' ,'/images/minik.jpg'),
                          ('Mochi', 'Dog', 'Sharpei', 16, 'A handsome, well-dressed adventurer with a knack for finding the coziest cuddle spots', '/images/mochi.jpg');"""
                    }
                }
            }
        }
    }
    # PostgreSQL PersistentVolumeClaim
    k8sv1alpha2.Object {
        metadata: _metadata("{}-postgres-pvc".format(oxr.metadata.name))
        spec: {
            providerConfigRef: {
                name: oxr.metadata.name
            }
            forProvider: {
                manifest: {
                    apiVersion: "v1"
                    kind: "PersistentVolumeClaim"
                    metadata: {
                        name: "postgres-data-pvc"
                        namespace: "default"
                    }
                    spec: {
                        accessModes: ["ReadWriteOnce"]
                        resources: {
                            requests: {
                                storage: "1Gi"
                            }
                        }
                        storageClassName: "gp2"
                    }
                }
            }
        }
    }
    # Ingress Controller Namespace
    k8sv1alpha2.Object {
        metadata: _metadata("{}-ingress-nginx-namespace".format(oxr.metadata.name))
        spec: {
            providerConfigRef: {
                name: oxr.metadata.name
            }
            forProvider: {
                manifest: {
                    apiVersion: "v1"
                    kind: "Namespace"
                    metadata: {
                        name: "ingress-nginx"
                    }
                }
            }
        }
    }
    k8sv1alpha2.Object {
        metadata: _metadata("{}-frontend-ingress".format(oxr.metadata.name))
        spec: {
            providerConfigRef: {
                name: oxr.metadata.name
            }
            readiness: {
                policy: "DeriveFromObject"
            }
            forProvider: {
                manifest: {
                    apiVersion: "networking.k8s.io/v1"
                    kind: "Ingress"
                    metadata: {
                        name: "{}-frontend-ingress".format(oxr.metadata.name)
                        namespace: "default"
                        annotations: {
                            "kubernetes.io/ingress.class": "alb"
                            "alb.ingress.kubernetes.io/scheme": "internet-facing"
                            "alb.ingress.kubernetes.io/target-type": "ip"
                            "alb.ingress.kubernetes.io/listen-ports": '[{"HTTP": 80}]'
                            "alb.ingress.kubernetes.io/group.name": oxr.metadata.name
                            "alb.ingress.kubernetes.io/target-port": "3002"
                            "alb.ingress.kubernetes.io/rewrite-target": "/$2"
                        }
                    }
                    spec: {
                        rules: [
                            {
                                http: {
                                    paths: [
                                        {
                                            path: "/api(/|$)(.*)"
                                            pathType: "Prefix"
                                            backend: {
                                                service: {
                                                    name: "{}-backend-service".format(oxr.metadata.name)
                                                    port: {
                                                        number: 3001
                                                    }
                                                }
                                            }
                                        }
                                        {
                                            path: "/debug-"
                                            pathType: "Prefix"
                                            backend: {
                                                service: {
                                                    name: "backend"
                                                    port: {
                                                        number: 3002
                                                    }
                                                }
                                            }
                                        }
                                        {
                                            path: "/health"
                                            pathType: "Exact"
                                            backend: {
                                                service: {
                                                    name: "backend"
                                                    port: {
                                                        number: 3002
                                                    }
                                                }
                                            }
                                        }
                                        {
                                            path: "/"
                                            pathType: "Prefix"
                                            backend: {
                                                service: {
                                                    name: "{}-frontend-service".format(oxr.metadata.name)
                                                    port: {
                                                        number: 80
                                                    }
                                                }
                                            }
                                        }
                                    ]
                                }
                            }
                        ]
                    }
                }
            }
        }
    }
]

items = _items

