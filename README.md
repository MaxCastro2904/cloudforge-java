# CloudForge Java

Aplicación Java con despliegue automatizado en AWS mediante Docker,
Terraform y GitHub Actions.

## Tecnologías

- Java 21 y Maven.
- Docker con compilación multietapa.
- Amazon ECR para almacenar imágenes.
- Amazon ECS Fargate para ejecutar la aplicación.
- Application Load Balancer para acceso público.
- Terraform con estado remoto en S3.
- GitHub Actions para integración y despliegue.

## Endpoints

| Método | Ruta | Función |
|--------|------|---------|
| GET | /api/hello | Devuelve el mensaje Hola Mundo |
| GET | /health | Comprueba la disponibilidad |

## Automatización

El pipeline valida Terraform, compila y prueba la aplicación dentro
de Docker, publica la imagen en ECR y despliega el servicio en ECS.
Finalmente comprueba el endpoint público.

## Estructura

- app/: código Java, configuración Maven y pruebas.
- infra/: infraestructura Terraform.
- scripts/: configuración y verificación.
- .github/workflows/: pipelines de despliegue y limpieza.

## Configuración

El despliegue utiliza las variables AWS_REGION, PROJECT_NAME y
AWS_ROLE_ARN, con autenticación OIDC entre GitHub y AWS.

La URL pública se obtiene en el resumen de GitHub Actions
cuando termina correctamente el despliegue.
