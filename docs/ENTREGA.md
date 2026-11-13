# Entrega técnica — CloudForge Java

Aplicación Java desplegada en AWS con compilación y pruebas dentro de Docker, publicación en Amazon ECR y aprovisionamiento mediante Terraform desde GitHub Actions.

## Enlaces

| Recurso | Dirección |
|---|---|
| Repositorio | https://github.com/MaxCastro2904/cloudforge-java |
| API HTTPS | https://d3c3gmuspygx6j.cloudfront.net/api/hello |
| Salud del servicio | https://d3c3gmuspygx6j.cloudfront.net/health |
| Ejecución de incorporación de CloudFront | https://github.com/MaxCastro2904/cloudforge-java/actions/runs/43515719918 |

Región de la infraestructura: `us-east-2`.

Fecha de verificación: 13 de noviembre de 2026.

## Solución implementada

La aplicación utiliza Java 21 y Maven. El Dockerfile compila el código y ejecuta las pruebas en una primera etapa; la imagen final contiene el runtime y el archivo JAR.

GitHub Actions obtiene credenciales temporales mediante OIDC, publica la imagen en ECR y despliega una referencia por digest en ECS Fargate.

Terraform administra el repositorio ECR, la red, los grupos de seguridad, el balanceador, el servicio ECS, el rol de ejecución de las tareas, el grupo de logs y la distribución CloudFront. Su estado se almacena en S3 con versionamiento y bloqueo nativo.

El proveedor OIDC, el rol del pipeline y la preparación inicial del backend se configuran previamente mediante los scripts de soporte y las políticas IAM correspondientes.

CloudFront proporciona el acceso HTTPS con el certificado de su dominio asignado por AWS. Las solicitudes se envían por HTTP al balanceador y desde allí al contenedor.

## Comprobación funcional

Solicitud:

```bash
curl --fail --show-error https://d3c3gmuspygx6j.cloudfront.net/api/hello
```

Respuesta:

```json
{
  "message": "Hola Mundo",
  "service": "java-ecs-api"
}
```

El endpoint `/health` responde:

```json
{
  "status": "UP"
}
```

Ambos endpoints devolvieron HTTP `200` durante la verificación.

## Evidencias

La ejecución enlazada terminó con los trabajos `validate` y `deploy` correctos y generó un artefacto de evidencias.

El pipeline conserva los outputs de Terraform y el resultado de las comprobaciones HTTP cuando están disponibles. El código fuente, el Dockerfile y las configuraciones de infraestructura se encuentran en el repositorio.

## Decisiones técnicas

Se utiliza ECS Fargate para ejecutar el contenedor sin administrar servidores ni un clúster Kubernetes.

La compilación dentro de Docker mantiene el mismo entorno de construcción entre las ejecuciones. El despliegue por digest permite identificar la imagen exacta utilizada por ECS.

La configuración del sandbox utiliza una tarea y evita un NAT Gateway. El grupo de seguridad de la tarea permite tráfico hacia el puerto de la aplicación únicamente desde el balanceador.

CloudFront se incorporó a Terraform mediante la importación de la distribución existente, conservando su dirección HTTPS.

## Alcance

La configuración corresponde a un entorno de evaluación. Una sola tarea no proporciona redundancia de la aplicación.

HTTPS termina en CloudFront. La conexión desde CloudFront al balanceador utiliza HTTP y el balanceador conserva su dirección pública.

## Limpieza

El workflow `Destroy sandbox resources` elimina la infraestructura de la aplicación y el repositorio ECR mediante Terraform. También incluye CloudFront una vez incorporado al estado.

El bucket de estado y la configuración previa de autenticación se conservan.
