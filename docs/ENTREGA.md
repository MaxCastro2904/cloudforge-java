# Entrega de prueba técnica

Completar después de un despliegue exitoso. No enviar con campos pendientes.

- Postulante: [nombre completo]
- Repositorio: [URL real GitHub]
- Endpoint público: [output hello_url]
- Health: [output public_url]/health
- Ejecución exitosa: [URL real del workflow]
- Commit: [SHA desplegado]
- Región AWS: [región utilizada]
- Fecha de validación: [fecha y hora]

## Evidencias que debes adjuntar

1. Workflow completo en verde, con etapas de validación y despliegue visibles.
2. Respuesta pública de `/api/hello` mostrando `Hola Mundo`.
3. ECR mostrando la imagen publicada y su digest.
4. ECS mostrando servicio estable y tarea en ejecución.
5. Artifact `deployment-evidence` con outputs y smoke test.

No incluyas credenciales, tokens, archivos de estado ni planes binarios en la entrega.

## Sustentación breve

Elegí ECS Fargate porque el reto requiere ejecutar una aplicación en contenedores y no necesita la complejidad de Kubernetes. Maven compila y prueba dentro de Docker, y la imagen final solo contiene Java runtime y el JAR. Terraform administra ECR, red, balanceador, cluster y servicio. GitHub Actions publica una imagen identificada por digest y despliega esa versión. El estado se conserva en S3 con versionamiento y bloqueo nativo. El endpoint se valida automáticamente después del despliegue.

La configuración prioriza un sandbox económico: una tarea, sin NAT Gateway y HTTP público para evaluación. En producción añadiría HTTPS, al menos dos tareas, subredes privadas y controles de seguridad adicionales.
