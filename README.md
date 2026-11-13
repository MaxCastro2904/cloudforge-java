# CloudForge Java

API Java desplegada en AWS mediante Docker, Terraform y GitHub Actions. El proyecto incluye compilación, pruebas, publicación de imágenes en Amazon ECR y despliegue en Amazon ECS Fargate.

## Aplicación

**Endpoint HTTPS:**  
https://d3c3gmuspygx6j.cloudfront.net/api/hello

**Estado del servicio:**  
https://d3c3gmuspygx6j.cloudfront.net/health

Respuesta de `/api/hello`:

```json
{
  "message": "Hola Mundo",
  "service": "java-ecs-api"
}
```

## Arquitectura

CloudFront recibe las solicitudes HTTPS y las envía a un Application Load Balancer. El balanceador distribuye las solicitudes hacia la aplicación en ECS Fargate, que utiliza imágenes almacenadas en ECR.

| Componente | Función |
|---|---|
| Amazon CloudFront | Acceso HTTPS con el certificado del dominio asignado por AWS |
| Application Load Balancer | Enrutamiento hacia la aplicación y comprobación de salud |
| Amazon ECS Fargate | Ejecución del contenedor Java |
| Amazon ECR | Almacenamiento de imágenes Docker |
| Amazon CloudWatch Logs | Registro de eventos de la aplicación |
| Amazon S3 | Estado remoto de Terraform con versionamiento y bloqueo |
| GitHub Actions | Validación, compilación, publicación y despliegue |
| IAM y OIDC | Autenticación del pipeline mediante credenciales temporales |

La conexión entre el cliente y CloudFront utiliza HTTPS. La conexión entre CloudFront y el balanceador utiliza HTTP.

La infraestructura regional está desplegada en `us-east-2`. Los recursos utilizan el prefijo `banbif-demo`, mientras que el repositorio conserva el nombre `cloudforge-java`.

## Tecnologías

- Java 21 y Maven.
- JUnit para pruebas.
- Docker con compilación multietapa.
- Terraform y proveedor AWS.
- GitHub Actions.

La aplicación utiliza el servidor HTTP incluido en el JDK y escucha en el puerto `8080`.

## Endpoints

| Método | Ruta | Respuesta |
|---|---|---|
| GET | `/` | Mensaje de bienvenida en JSON |
| GET | `/api/hello` | Mensaje `Hola Mundo` |
| GET | `/health` | Estado `UP` |

Las rutas inexistentes responden con `404`. Los métodos distintos de GET responden con `405`.

## Organización del repositorio

| Ruta | Contenido |
|---|---|
| `app/` | Código Java, configuración Maven y pruebas |
| `Dockerfile` | Compilación y empaquetado del contenedor |
| `infra/registry/` | Repositorio ECR |
| `infra/service/` | Red, balanceador, ECS, logs y CloudFront |
| `scripts/` | Preparación del entorno y comprobaciones HTTP |
| `.github/workflows/deploy.yml` | Pipeline de validación y despliegue |
| `.github/workflows/destroy.yml` | Eliminación de recursos |
| `docs/` | Documentación complementaria |

## Ejecución local

Se requiere Docker.

```bash
docker build -t cloudforge-java .
docker run --rm -p 8080:8080 cloudforge-java
```

Desde otra terminal:

```bash
curl http://localhost:8080/api/hello
curl http://localhost:8080/health
```

Para ejecutar la compilación y las pruebas dentro de Docker:

```bash
docker build --target build -t cloudforge-java-tests .
```

## Configuración del despliegue

El pipeline requiere una cuenta AWS, un proveedor OIDC para GitHub y un rol IAM autorizado para administrar los recursos del proyecto.

El rol debe confiar en el repositorio y en el entorno `production` de GitHub Actions. La condición de confianza debe coincidir con el formato de identidad OIDC utilizado por el repositorio.

Configurar estas variables en **Settings → Secrets and variables → Actions → Variables**:

| Variable | Valor del despliegue |
|---|---|
| `AWS_REGION` | `us-east-2` |
| `PROJECT_NAME` | `banbif-demo` |
| `AWS_ROLE_ARN` | ARN del rol IAM utilizado por GitHub Actions |

La autenticación del despliegue utiliza OIDC y no requiere almacenar claves permanentes de AWS en GitHub.

El stack `infra/bootstrap` administra el proveedor OIDC, el rol del pipeline, sus políticas y el bucket de estado. Los stacks `registry` y `service` administran ECR y la infraestructura de la aplicación, incluida CloudFront. La configuración inicial se ejecuta desde una sesión administrativa; las ejecuciones normales utilizan OIDC.

```bash
bash scripts/setup-oidc.sh MaxCastro2904/cloudforge-java us-east-2 banbif-demo
```

El script importa recursos existentes antes de aplicar el plan y conserva el estado inicial en `bootstrap/terraform.tfstate`.

## Pipeline CI/CD

Los cambios en `main` ejecutan la validación y el despliegue. Los pull requests ejecutan únicamente la validación. También se puede iniciar una ejecución manual desde **Actions → Build, publish and deploy → Run workflow**.

El flujo realiza estas operaciones:

1. Comprueba el formato y la configuración de Terraform.
2. Compila la aplicación y ejecuta las pruebas dentro de Docker.
3. Inicia un contenedor local y verifica las respuestas HTTP.
4. Obtiene credenciales temporales de AWS mediante OIDC.
5. Prepara el backend remoto y administra ECR con Terraform.
6. Construye y publica la imagen de la aplicación.
7. Obtiene el digest de la imagen publicada.
8. Genera y aplica el plan de infraestructura.
9. Comprueba los endpoints públicos y guarda las evidencias.

ECS utiliza la imagen por digest para identificar exactamente la versión desplegada. Terraform aplica el mismo plan guardado durante la etapa de planificación.

## Estado de Terraform

El estado se almacena en S3 y se separa entre las configuraciones `bootstrap`, `registry` y `service`.

El backend utiliza versionamiento, cifrado, bloqueo de acceso público y bloqueo nativo del estado en S3. Las ejecuciones de despliegue y limpieza comparten un grupo de concurrencia para evitar modificaciones simultáneas desde GitHub Actions.

La distribución CloudFront existente se incorporó al estado mediante una importación de Terraform, conservando su dirección HTTPS.

## Red y operación

- La VPC dispone de dos subredes públicas en distintas zonas de disponibilidad.
- El balanceador recibe las solicitudes HTTP del origen de CloudFront.
- El puerto `8080` de las tareas acepta tráfico únicamente desde el grupo de seguridad del balanceador.
- Las tareas tienen IP pública para acceder a ECR y otros servicios AWS sin utilizar un NAT Gateway.
- El balanceador verifica la disponibilidad mediante `/health`.
- La aplicación envía sus registros a CloudWatch Logs.
- ECS tiene habilitado el mecanismo de detección de fallos de despliegue con rollback.

La configuración inicial ejecuta una tarea de Fargate. Las dos subredes permiten distribuir tareas adicionales entre zonas, pero una sola tarea no proporciona redundancia de la aplicación.

## Verificación

```bash
curl --fail --show-error https://d3c3gmuspygx6j.cloudfront.net/api/hello
curl --fail --show-error https://d3c3gmuspygx6j.cloudfront.net/health
```

También se puede ejecutar el script de comprobación:

```bash
bash scripts/smoke-test.sh https://d3c3gmuspygx6j.cloudfront.net
```

Las ejecuciones de despliegue generan un artefacto `deployment-evidence` con los outputs de Terraform y el resultado de las comprobaciones HTTP cuando están disponibles.

## Eliminación de recursos

Desde GitHub Actions:

1. Abrir **Destroy sandbox resources**.
2. Seleccionar **Run workflow**.
3. Escribir `DESTROY` en el campo de confirmación.
4. Ejecutar el workflow y comprobar que termine correctamente.

Terraform elimina la infraestructura administrada por la configuración de servicio, incluida CloudFront, y después el repositorio ECR.

El bucket de estado y la configuración previa de autenticación se conservan. La eliminación de CloudFront puede tardar varios minutos.

Los recursos activos pueden generar consumo de AWS. Al finalizar la evaluación, se debe ejecutar la limpieza y comprobar los recursos restantes.
