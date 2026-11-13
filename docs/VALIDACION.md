# Validación del despliegue

Fecha de verificación: 13 de noviembre de 2026.

## Ejecución de referencia

https://github.com/MaxCastro2904/cloudforge-java/actions/runs/43515719918

La ejecución terminó en estado `Success`, con los trabajos `validate` y `deploy` correctos.

## Comprobaciones del pipeline

| Comprobación | Resultado |
|---|---|
| Formato y validación de Terraform | Correcto |
| Compilación y pruebas Maven dentro de Docker | Correcto |
| Construcción y comprobación del contenedor local | Correcto |
| Autenticación AWS mediante OIDC | Correcto |
| Preparación del backend remoto en S3 | Correcto |
| Aprovisionamiento de ECR con Terraform | Correcto |
| Publicación de la imagen Docker | Correcto |
| Aplicación de la infraestructura del servicio | Correcto |
| Incorporación de CloudFront a Terraform | Correcto |
| Verificación pública del servicio desde el pipeline | Correcto |
| Generación del artefacto de evidencias | Correcto |

La ejecución de referencia verificó la dirección HTTP del balanceador. La comprobación HTTPS siguiente se realizó de forma independiente.

## Verificación HTTPS

Se realizaron solicitudes con validación normal del certificado TLS, sin omitir la comprobación de confianza.

| Endpoint | Código HTTP | Respuesta |
|---|---|---|
| `/api/hello` | 200 | `{"message":"Hola Mundo","service":"java-ecs-api"}` |
| `/health` | 200 | `{"status":"UP"}` |

Dirección base:

```text
https://d3c3gmuspygx6j.cloudfront.net
```

## Repetir las comprobaciones

```bash
curl --fail --show-error https://d3c3gmuspygx6j.cloudfront.net/api/hello
curl --fail --show-error https://d3c3gmuspygx6j.cloudfront.net/health
```

También se puede utilizar el script del repositorio:

```bash
bash scripts/smoke-test.sh https://d3c3gmuspygx6j.cloudfront.net
```

## Evidencias del pipeline

El artefacto `deployment-evidence` contiene:

- `terraform-outputs.json`: outputs de la infraestructura desplegada.
- `smoke-test.txt`: resultado de la comprobación pública.

Los registros de GitHub Actions permiten revisar la compilación, las pruebas, la publicación de la imagen y la aplicación de Terraform.

## Alcance de la validación

Estas comprobaciones verifican la construcción, el despliegue y la respuesta funcional de la aplicación. No incluyen pruebas de carga, recuperación ante desastres ni una auditoría de seguridad.

El certificado protege la conexión entre el cliente y CloudFront. La conexión entre CloudFront y el balanceador utiliza HTTP.
