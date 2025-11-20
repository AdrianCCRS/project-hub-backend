# 📚 Guía Completa de Archivos Kubernetes - ProjectHub

Esta guía explica **cada archivo YAML** en la carpeta `k8s/`, por qué existe, qué hace, y cómo funciona.

---

## 📁 Estructura de Archivos

```
k8s/
├── namespace.yaml           # Organización en 3 namespaces
├── mysql-secret.yaml        # Credenciales de MySQL
├── mysql-configmap.yaml     # Configuración de MySQL
├── mysql-pvc.yaml           # Almacenamiento persistente
├── mysql-deployment.yaml    # Contenedor de MySQL
├── mysql-service.yaml       # Punto de acceso a MySQL
├── app-secret.yaml          # Credenciales del backend
├── app-configmap.yaml       # Configuración del backend
├── app-deployment.yaml      # Contenedor de Spring Boot
├── app-service.yaml         # Punto de acceso al backend
└── ingress.yaml             # Puerta de entrada HTTP
```

---

## 1️⃣ namespace.yaml - Organización de Recursos

### ¿Por qué existe?

Los **namespaces** son como "carpetas virtuales" en Kubernetes que permiten organizar y aislar recursos. Es como tener diferentes habitaciones en una casa.

### Contenido

```yaml
# Backend Namespace
apiVersion: v1              # Versión de la API de Kubernetes
kind: Namespace             # Tipo de recurso: Namespace
metadata:
  name: projecthub-backend  # Nombre único del namespace
  labels:                   # Etiquetas para organización
    name: projecthub-backend
    tier: backend           # Indica que es la capa de backend
    environment: production # Ambiente de producción
---
# Database Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: projecthub-database
  labels:
    name: projecthub-database
    tier: database
    environment: production
---
# Frontend Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: projecthub-frontend
  labels:
    name: projecthub-frontend
    tier: frontend
    environment: production
```

### Namespaces creados

- **`projecthub-backend`** → Para la aplicación Spring Boot
- **`projecthub-database`** → Para MySQL
- **`projecthub-frontend`** → Para el frontend (futuro)

### Beneficios

✅ **Aislamiento** - Recursos separados por capa  
✅ **Seguridad** - Políticas RBAC diferentes por namespace  
✅ **Organización** - Fácil de entender quién posee qué  
✅ **Escalabilidad** - Escalar namespaces independientemente

---

## 2️⃣ Archivos de Base de Datos (MySQL)

### mysql-secret.yaml - Credenciales Sensibles

#### ¿Por qué existe?

Almacena información **sensible** (contraseñas) de forma segura. Los Secrets en Kubernetes están diseñados para datos confidenciales.

#### Contenido

```yaml
apiVersion: v1
kind: Secret                      # Tipo: Secret (datos sensibles)
metadata:
  name: mysql-secret
  namespace: projecthub-database  # Vive en el namespace de database
type: Opaque                      # Tipo genérico de secret
data:
  # Valores codificados en Base64 (NO es encriptación, solo encoding)
  MYSQL_ROOT_PASSWORD: cm9vdHBhc3N3b3Jk    # "rootpassword"
  MYSQL_USER: cHJvamVjdGh1Yg==             # "projecthub"
  MYSQL_PASSWORD: cHJvamVjdGh1YjEyMw==     # "projecthub123"
```

#### Cómo codificar valores

```bash
echo -n 'tu-contraseña' | base64
```

> **⚠️ IMPORTANTE:** Base64 NO es encriptación, es solo encoding. Para producción usa herramientas como **Sealed Secrets** o servicios externos de gestión de secretos (AWS Secrets Manager, HashiCorp Vault, etc.).

---

### mysql-configmap.yaml - Configuración No Sensible

#### ¿Por qué existe?

Almacena configuración que **NO es sensible**. Los ConfigMaps son para datos de configuración públicos.

#### Contenido

```yaml
apiVersion: v1
kind: ConfigMap                   # Tipo: ConfigMap (configuración)
metadata:
  name: mysql-config
  namespace: projecthub-database
data:
  MYSQL_DATABASE: "project_db"    # Nombre de la base de datos a crear
```

#### Diferencia con Secret

| ConfigMap | Secret |
|-----------|--------|
| Datos no sensibles | Datos sensibles |
| Nombres, URLs, configuraciones | Contraseñas, tokens, certificados |
| Visible en `kubectl describe` | Oculto en `kubectl describe` |

---

### mysql-pvc.yaml - Almacenamiento Persistente

#### ¿Por qué existe?

MySQL necesita guardar datos de forma **permanente**. Si el pod de MySQL se reinicia, los datos NO deben perderse. El **PVC** (PersistentVolumeClaim) solicita espacio de almacenamiento persistente.

#### Contenido

```yaml
apiVersion: v1
kind: PersistentVolumeClaim      # Solicitud de almacenamiento
metadata:
  name: mysql-pvc
  namespace: projecthub-database
spec:
  accessModes:
    - ReadWriteOnce              # Solo un nodo puede escribir a la vez
  resources:
    requests:
      storage: 5Gi               # Solicita 5GB de espacio
```

#### Analogía

Es como pedir un **disco duro de 5GB** para MySQL. Aunque el contenedor se destruya, los datos permanecen en este "disco".

#### Access Modes

- **ReadWriteOnce (RWO)** - Un solo nodo puede montar el volumen (lectura/escritura)
- **ReadOnlyMany (ROX)** - Múltiples nodos pueden montar (solo lectura)
- **ReadWriteMany (RWX)** - Múltiples nodos pueden montar (lectura/escritura)

---

### mysql-deployment.yaml - El Contenedor de MySQL

#### ¿Por qué existe?

Este es el archivo **más importante** para MySQL. Define CÓMO se ejecuta el contenedor de MySQL, cuántos recursos usa, y cómo se conecta al almacenamiento.

#### Contenido explicado

```yaml
apiVersion: apps/v1
kind: Deployment                    # Tipo: Deployment (gestiona pods)
metadata:
  name: mysql
  namespace: projecthub-database
  labels:
    app: mysql

spec:
  replicas: 1                       # Solo 1 instancia de MySQL
  selector:
    matchLabels:
      app: mysql                    # Selecciona pods con esta etiqueta
  
  strategy:
    type: Recreate                  # ⚠️ IMPORTANTE para bases de datos
                                    # Destruye el pod viejo antes de crear uno nuevo
                                    # (evita que 2 MySQL escriban al mismo disco)
  
  template:                         # Plantilla del pod
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0            # Imagen oficial de MySQL 8.0
        ports:
        - containerPort: 3306       # Puerto de MySQL
          name: mysql
        
        # Variables de entorno (inyectadas desde ConfigMap y Secret)
        env:
        - name: MYSQL_DATABASE
          valueFrom:
            configMapKeyRef:        # Lee desde mysql-config
              name: mysql-config
              key: MYSQL_DATABASE
        
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:           # Lee desde mysql-secret
              name: mysql-secret
              key: MYSQL_ROOT_PASSWORD
        
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_USER
        
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_PASSWORD
        
        # Montaje del volumen persistente
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql # Donde MySQL guarda sus datos
        
        # Recursos (CPU y memoria)
        resources:
          requests:                 # Mínimo garantizado
            memory: "512Mi"
            cpu: "250m"             # 0.25 cores
          limits:                   # Máximo permitido
            memory: "1Gi"
            cpu: "500m"             # 0.5 cores
        
        # Prueba de vida (¿está vivo el proceso?)
        livenessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 30   # Espera 30s antes de empezar
          periodSeconds: 10         # Revisa cada 10s
          timeoutSeconds: 5
        
        # Prueba de disponibilidad (¿está listo para recibir tráfico?)
        readinessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
      
      # Definición del volumen
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc      # Usa el PVC que creamos antes
```

#### Conceptos clave

- **replicas: 1** → Solo una instancia de MySQL (las bases de datos no se escalan horizontalmente fácilmente)
- **Recreate strategy** → Evita que dos MySQL escriban al mismo disco
- **Probes** → Kubernetes revisa si MySQL está funcionando correctamente

#### Probes explicados

| Probe | ¿Qué hace? | Si falla |
|-------|-----------|----------|
| **livenessProbe** | Verifica si el proceso está vivo | Kubernetes REINICIA el pod |
| **readinessProbe** | Verifica si está listo para tráfico | Kubernetes NO envía tráfico (pero no reinicia) |

---

### mysql-service.yaml - Punto de Acceso a MySQL

#### ¿Por qué existe?

Los pods en Kubernetes tienen IPs que **cambian** cuando se reinician. Un **Service** proporciona una IP estable y un nombre DNS para acceder a MySQL.

#### Contenido

```yaml
apiVersion: v1
kind: Service                     # Tipo: Service (punto de acceso)
metadata:
  name: mysql                     # ⚠️ IMPORTANTE: Este nombre es el DNS
  namespace: projecthub-database
  labels:
    app: mysql

spec:
  type: ClusterIP                 # Solo accesible dentro del cluster
  ports:
  - port: 3306                    # Puerto del servicio
    targetPort: 3306              # Puerto del contenedor
    protocol: TCP
    name: mysql
  
  selector:
    app: mysql                    # Enruta tráfico a pods con esta etiqueta
```

#### Cómo funciona

- Otros servicios pueden conectarse usando: `mysql.projecthub-database.svc.cluster.local:3306`
- El Service encuentra automáticamente los pods con la etiqueta `app: mysql`
- Si el pod se reinicia con nueva IP, el Service sigue funcionando

#### Tipos de Service

| Tipo | Descripción | Uso |
|------|-------------|-----|
| **ClusterIP** | Solo accesible dentro del cluster | Servicios internos (MySQL) |
| **NodePort** | Expone en un puerto del nodo | Desarrollo local |
| **LoadBalancer** | Crea un balanceador externo | Producción en cloud |

---

## 3️⃣ Archivos de Backend (Spring Boot)

### app-secret.yaml - Credenciales del Backend

#### ¿Por qué existe?

Guarda las credenciales **sensibles** que tu aplicación Spring Boot necesita: contraseña de la base de datos y el JWT secret.

#### Contenido

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  namespace: projecthub-backend    # Vive en el namespace de backend
type: Opaque
data:
  # Usuario de la base de datos: "projecthub"
  SPRING_DATASOURCE_USERNAME: cHJvamVjdGh1Yg==
  
  # Contraseña de la base de datos: "projecthub123"
  SPRING_DATASOURCE_PASSWORD: cHJvamVjdGh1YjEyMw==
  
  # Clave secreta para firmar JWT tokens
  JWT_SECRET: eW91ci1zZWNyZXQta2V5LWNoYW5nZS10aGlzLWluLXByb2R1Y3Rpb24tbWFrZS1pdC1sb25nLWFuZC1yYW5kb20=
```

#### Nota

Estos valores se inyectan como **variables de entorno** en tu aplicación Spring Boot.

---

### app-configmap.yaml - Configuración del Backend

#### ¿Por qué existe?

Configuración **no sensible** de tu aplicación Spring Boot.

#### Contenido

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: projecthub-backend
data:
  # Perfil de Spring Boot a activar
  SPRING_PROFILES_ACTIVE: "docker"
  
  # ⚠️ IMPORTANTE: URL con nombre completo para cross-namespace
  SPRING_DATASOURCE_URL: "jdbc:mysql://mysql.projecthub-database.svc.cluster.local:3306/project_db"
  #                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #                                     Nombre completo porque MySQL está en otro namespace
  
  # Driver de MySQL
  SPRING_DATASOURCE_DRIVER_CLASS_NAME: "com.mysql.cj.jdbc.Driver"
  
  # Puerto del servidor
  SERVER_PORT: "8080"
```

#### Clave importante

La URL usa el nombre completo `mysql.projecthub-database.svc.cluster.local` porque MySQL está en un namespace diferente (`projecthub-database`) y tu app está en `projecthub-backend`.

#### Formato de DNS en Kubernetes

```
<service-name>.<namespace>.svc.cluster.local
```

Ejemplo:
- **Mismo namespace:** `mysql` (nombre corto)
- **Diferente namespace:** `mysql.projecthub-database.svc.cluster.local` (FQDN)

---

### app-deployment.yaml - El Contenedor de Spring Boot

#### ¿Por qué existe?

Este es el archivo **más importante** para tu backend. Define cómo se ejecuta tu aplicación Spring Boot.

#### Contenido explicado

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: projecthub-app
  namespace: projecthub-backend
  labels:
    app: projecthub

spec:
  replicas: 2                       # ⚠️ 2 instancias de tu app (alta disponibilidad)
  
  selector:
    matchLabels:
      app: projecthub
  
  strategy:
    type: RollingUpdate             # Actualización sin downtime
    rollingUpdate:
      maxSurge: 1                   # Puede crear 1 pod extra durante actualización
      maxUnavailable: 0             # Siempre mantiene al menos 2 pods corriendo
  
  template:
    metadata:
      labels:
        app: projecthub
    spec:
      # ⚠️ INIT CONTAINER - Se ejecuta ANTES del contenedor principal
      initContainers:
      - name: wait-for-mysql
        image: busybox:1.35
        command:
        - sh
        - -c
        - |
          # Espera hasta que MySQL esté disponible
          until nc -z mysql.projecthub-database.svc.cluster.local 3306; do
            echo "Waiting for MySQL to be ready..."
            sleep 3
          done
          echo "MySQL is ready!"
      
      # CONTENEDOR PRINCIPAL - Tu aplicación Spring Boot
      containers:
      - name: projecthub
        image: projecthub:latest     # Tu imagen Docker
        imagePullPolicy: IfNotPresent # Usa imagen local si existe
        ports:
        - containerPort: 8080
          name: http
        
        # Variables de entorno inyectadas desde ConfigMap y Secret
        env:
        - name: SPRING_PROFILES_ACTIVE
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: SPRING_PROFILES_ACTIVE
        
        - name: SPRING_DATASOURCE_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: SPRING_DATASOURCE_URL
        
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:             # Lee desde Secret
              name: app-secret
              key: SPRING_DATASOURCE_USERNAME
        
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: SPRING_DATASOURCE_PASSWORD
        
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: JWT_SECRET
        
        # Recursos de CPU y memoria
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"               # 0.25 cores
          limits:
            memory: "1Gi"
            cpu: "1000m"              # 1 core
        
        # Prueba de vida - ¿está vivo el proceso?
        livenessProbe:
          httpGet:
            path: /actuator/health    # Endpoint de Spring Boot Actuator
            port: 8080
          initialDelaySeconds: 90     # Espera 90s (Spring Boot tarda en iniciar)
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3         # Reinicia si falla 3 veces
        
        # Prueba de disponibilidad - ¿está listo para recibir tráfico?
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
```

#### Conceptos clave

**1. replicas: 2** → Alta disponibilidad. Si un pod falla, el otro sigue funcionando.

**2. RollingUpdate** → Cuando actualizas tu app:
   - Crea un nuevo pod
   - Espera a que esté listo
   - Destruye un pod viejo
   - Repite
   - **Resultado:** Sin downtime

**3. initContainer** → Se ejecuta ANTES de tu app para asegurar que MySQL esté listo. Tu app no arranca hasta que MySQL responda.

**4. livenessProbe vs readinessProbe:**

| Probe | Propósito | Si falla |
|-------|-----------|----------|
| **livenessProbe** | ¿Está vivo el proceso? | Kubernetes REINICIA el pod |
| **readinessProbe** | ¿Está listo para tráfico? | Kubernetes NO envía tráfico (pero no reinicia) |

---

### app-service.yaml - Punto de Acceso al Backend

#### ¿Por qué existe?

Proporciona una IP estable para acceder a tus pods de Spring Boot. Balancea el tráfico entre las 2 réplicas.

#### Contenido

```yaml
apiVersion: v1
kind: Service
metadata:
  name: projecthub-service
  namespace: projecthub-backend
  labels:
    app: projecthub

spec:
  type: LoadBalancer              # ⚠️ Expone el servicio externamente
                                  # (en cloud crea un Load Balancer real)
                                  # (en Minikube/local usa NodePort)
  ports:
  - port: 80                      # Puerto externo (lo que ves desde fuera)
    targetPort: 8080              # Puerto del contenedor (Spring Boot)
    protocol: TCP
    name: http
  
  selector:
    app: projecthub               # Enruta a pods con esta etiqueta
```

#### Cómo funciona

- Recibe tráfico en el puerto **80**
- Lo distribuye entre los **2 pods** de Spring Boot (puerto 8080)
- Si un pod falla, solo envía tráfico al pod sano

#### Balanceo de carga

```
Request → Service (puerto 80)
            ├─→ Pod 1 (8080) ✅
            └─→ Pod 2 (8080) ✅
```

---

### ingress.yaml - Puerta de Entrada HTTP

#### ¿Por qué existe?

El **Ingress** es como un "reverse proxy" que maneja el tráfico HTTP/HTTPS entrante. Permite usar nombres de dominio y rutas.

#### Contenido

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: projecthub-ingress
  namespace: projecthub-backend
  annotations:
    # Configuración para NGINX Ingress Controller
    nginx.ingress.kubernetes.io/rewrite-target: /
    
    # Habilita CORS (Cross-Origin Resource Sharing)
    nginx.ingress.kubernetes.io/enable-cors: "true"

spec:
  ingressClassName: nginx         # Usa NGINX como controlador
  
  rules:
  - host: projecthub.local        # ⚠️ Dominio (cámbialo por tu dominio real)
    http:
      paths:
      - path: /                   # Todas las rutas (/, /api, etc.)
        pathType: Prefix
        backend:
          service:
            name: projecthub-service  # Enruta al Service
            port:
              number: 80
  
  # TLS/HTTPS (comentado, para cuando tengas certificados)
  # tls:
  # - hosts:
  #   - projecthub.local
  #   secretName: projecthub-tls
```

#### Cómo funciona

```
Usuario → http://projecthub.local/api/users
           ↓
      Ingress (NGINX)
           ↓
    projecthub-service (puerto 80)
           ↓
    Pod 1 o Pod 2 (puerto 8080)
           ↓
    Spring Boot responde
```

#### Para desarrollo local

Agrega a `/etc/hosts`:
```bash
127.0.0.1  projecthub.local
```

Luego accede a: `http://projecthub.local`

---

## 📊 Arquitectura Visual

```
┌─────────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         Namespace: projecthub-backend              │    │
│  │                                                     │    │
│  │  ┌──────────────┐                                  │    │
│  │  │   Ingress    │ ← Entrada HTTP                   │    │
│  │  └──────┬───────┘                                  │    │
│  │         │                                           │    │
│  │  ┌──────▼───────┐                                  │    │
│  │  │   Service    │ ← Balanceador                    │    │
│  │  └──────┬───────┘                                  │    │
│  │         │                                           │    │
│  │    ┌────┴────┐                                     │    │
│  │    │         │                                     │    │
│  │  ┌─▼──┐   ┌─▼──┐                                  │    │
│  │  │Pod1│   │Pod2│ ← Spring Boot (2 réplicas)       │    │
│  │  └────┘   └────┘                                  │    │
│  │    │         │                                     │    │
│  │  ┌─▼─────────▼─┐                                  │    │
│  │  │ ConfigMap   │ ← Configuración                  │    │
│  │  │   Secret    │ ← Credenciales                   │    │
│  │  └─────────────┘                                  │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│                          │                                   │
│                          │ Cross-namespace                   │
│                          │ (FQDN)                           │
│                          ▼                                   │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         Namespace: projecthub-database             │    │
│  │                                                     │    │
│  │  ┌──────────────┐                                  │    │
│  │  │   Service    │ ← mysql.projecthub-database...   │    │
│  │  └──────┬───────┘                                  │    │
│  │         │                                           │    │
│  │  ┌──────▼───────┐                                  │    │
│  │  │  MySQL Pod   │ ← Base de datos                  │    │
│  │  └──────┬───────┘                                  │    │
│  │         │                                           │    │
│  │  ┌──────▼───────┐                                  │    │
│  │  │     PVC      │ ← Almacenamiento persistente     │    │
│  │  └──────────────┘                                  │    │
│  │         │                                           │    │
│  │  ┌──────▼───────┐                                  │    │
│  │  │ ConfigMap    │ ← Configuración DB               │    │
│  │  │   Secret     │ ← Contraseñas DB                 │    │
│  │  └──────────────┘                                  │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         Namespace: projecthub-frontend             │    │
│  │                 (Vacío - para futuro)              │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Orden de Despliegue

Es importante desplegar en el orden correcto:

```bash
# 1. Namespaces primero
kubectl apply -f namespace.yaml

# 2. Secrets y ConfigMaps (antes de los Deployments)
kubectl apply -f mysql-secret.yaml
kubectl apply -f mysql-configmap.yaml
kubectl apply -f app-secret.yaml
kubectl apply -f app-configmap.yaml

# 3. Almacenamiento persistente
kubectl apply -f mysql-pvc.yaml

# 4. Deployments
kubectl apply -f mysql-deployment.yaml
kubectl apply -f app-deployment.yaml

# 5. Services
kubectl apply -f mysql-service.yaml
kubectl apply -f app-service.yaml

# 6. Ingress (último)
kubectl apply -f ingress.yaml
```

### Despliegue rápido (todo a la vez)

```bash
kubectl apply -f k8s/
```

Kubernetes aplicará los archivos en el orden correcto automáticamente.

---

## 🎯 Conceptos Clave de Kubernetes

### 1. Namespaces
- **Qué:** Organización y aislamiento de recursos
- **Analogía:** Carpetas en un sistema de archivos

### 2. Secrets
- **Qué:** Datos sensibles (contraseñas, tokens)
- **Analogía:** Caja fuerte para guardar información confidencial

### 3. ConfigMaps
- **Qué:** Configuración no sensible
- **Analogía:** Archivo de configuración público

### 4. PersistentVolumeClaim (PVC)
- **Qué:** Almacenamiento que sobrevive reinicios
- **Analogía:** Disco duro externo

### 5. Deployments
- **Qué:** Define CÓMO corren tus contenedores
- **Analogía:** Receta para crear y gestionar aplicaciones

### 6. Services
- **Qué:** Punto de acceso estable con DNS
- **Analogía:** Número de teléfono fijo (no cambia aunque te mudes)

### 7. Ingress
- **Qué:** Puerta de entrada HTTP/HTTPS
- **Analogía:** Recepcionista que dirige visitantes a la oficina correcta

---

## 🔍 Comandos Útiles

### Ver recursos

```bash
# Ver todos los recursos en un namespace
kubectl get all -n projecthub-backend
kubectl get all -n projecthub-database

# Ver todos los namespaces
kubectl get namespaces

# Ver pods
kubectl get pods -n projecthub-backend
kubectl get pods -n projecthub-database

# Ver servicios
kubectl get services -n projecthub-backend
kubectl get services -n projecthub-database

# Ver secrets
kubectl get secrets -n projecthub-backend
kubectl get secrets -n projecthub-database

# Ver configmaps
kubectl get configmaps -n projecthub-backend
kubectl get configmaps -n projecthub-database
```

### Ver detalles

```bash
# Describir un pod
kubectl describe pod <pod-name> -n projecthub-backend

# Ver logs de un pod
kubectl logs <pod-name> -n projecthub-backend

# Ver logs en tiempo real
kubectl logs -f <pod-name> -n projecthub-backend

# Ver logs de init container
kubectl logs <pod-name> -n projecthub-backend -c wait-for-mysql
```

### Debugging

```bash
# Ejecutar comando en un pod
kubectl exec -it <pod-name> -n projecthub-backend -- bash

# Probar conectividad a MySQL desde backend
kubectl exec -it <app-pod-name> -n projecthub-backend -- nc -zv mysql.projecthub-database.svc.cluster.local 3306

# Ver eventos
kubectl get events -n projecthub-backend --sort-by='.lastTimestamp'
```

### Eliminar recursos

```bash
# Eliminar un recurso específico
kubectl delete -f mysql-deployment.yaml

# Eliminar todo en un namespace
kubectl delete all --all -n projecthub-backend

# ⚠️ CUIDADO: Eliminar un namespace elimina TODO dentro
kubectl delete namespace projecthub-database
```

---

## 🚨 Troubleshooting

### Backend no puede conectarse a MySQL

**Problema:** `Connection refused` o `Unknown host`

**Solución:**
1. Verifica que MySQL esté corriendo:
   ```bash
   kubectl get pods -n projecthub-database
   ```

2. Verifica el Service de MySQL:
   ```bash
   kubectl get svc -n projecthub-database
   ```

3. Prueba conectividad desde el backend:
   ```bash
   kubectl exec -it <app-pod> -n projecthub-backend -- nc -zv mysql.projecthub-database.svc.cluster.local 3306
   ```

4. Verifica que la URL en `app-configmap.yaml` sea correcta:
   ```
   jdbc:mysql://mysql.projecthub-database.svc.cluster.local:3306/project_db
   ```

### Pods en estado Pending

**Problema:** Pods no arrancan

**Solución:**
```bash
kubectl describe pod <pod-name> -n <namespace>
```

Busca en la sección `Events` el motivo (falta de recursos, PVC no disponible, etc.)

### Imagen no encontrada

**Problema:** `ImagePullBackOff` o `ErrImagePull`

**Solución:**
1. Verifica que la imagen existe:
   ```bash
   docker images | grep projecthub
   ```

2. Si usas Minikube, asegúrate de usar el daemon de Docker de Minikube:
   ```bash
   eval $(minikube docker-env)
   docker build -t projecthub:latest .
   ```

### Secret no se aplica

**Problema:** Variables de entorno vacías

**Solución:**
1. Verifica que el Secret existe:
   ```bash
   kubectl get secret app-secret -n projecthub-backend
   ```

2. Verifica el contenido (decodificado):
   ```bash
   kubectl get secret app-secret -n projecthub-backend -o jsonpath='{.data.JWT_SECRET}' | base64 -d
   ```

---

## 📚 Recursos Adicionales

- [Documentación oficial de Kubernetes](https://kubernetes.io/docs/)
- [Kubernetes Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Spring Boot on Kubernetes](https://spring.io/guides/gs/spring-boot-kubernetes/)
- [MySQL on Kubernetes](https://kubernetes.io/docs/tasks/run-application/run-single-instance-stateful-application/)

---

## ✅ Checklist de Producción

Antes de llevar a producción, asegúrate de:

- [ ] Cambiar todos los secretos por valores seguros
- [ ] Usar un sistema de gestión de secretos (Sealed Secrets, Vault, etc.)
- [ ] Configurar TLS/HTTPS en el Ingress
- [ ] Configurar backups automáticos de MySQL
- [ ] Configurar límites de recursos apropiados
- [ ] Configurar monitoreo y alertas
- [ ] Configurar políticas de red (NetworkPolicies)
- [ ] Configurar RBAC (Role-Based Access Control)
- [ ] Usar un dominio real en el Ingress
- [ ] Configurar autoscaling (HPA) si es necesario

---

**¡Listo!** Ahora tienes una comprensión completa de todos los archivos de Kubernetes en tu proyecto. 🚀
