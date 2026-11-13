# Validaciones realizadas

- Compilación del código Java con JDK 21: correcta.
- Cinco pruebas JUnit del proyecto ejecutadas con JUnit Platform Console: cinco correctas, cero fallos.
- Verificación HTTP adicional: `/`, `/api/hello`, `/health`, dos rutas inexistentes y POST no permitido: correcta.
- `actionlint 1.7.7` sobre ambos workflows: sin errores.
- `terraform fmt -check -recursive`: correcto.
- `terraform init -backend=false` en ambos stacks: correcto, proveedor AWS descargado y locks incluidos.
- Sintaxis Bash de los cuatro scripts y sintaxis Python del generador IAM: correctas.
- Bootstrap de OIDC y backend probados con AWS CLI simulado, incluyendo validez JSON y salida a GITHUB_ENV. No se crearon recursos reales.

## Pendiente de ejecución en GitHub / AWS

- `terraform validate` no pudo completar en el entorno de preparación: el proveedor intenta abrir un socket Unix bloqueado por el entorno. El workflow ejecuta la validación real antes de desplegar.
- Maven no pudo resolver dependencias por la configuración de red de este entorno; se verificaron compilación y las cinco pruebas mediante JDK/JUnit directamente. Maven clean verify está incluido dentro del Dockerfile.
- Docker no está disponible en el entorno de preparación. La construcción multietapa y prueba del runtime se ejecutan en GitHub Actions.
- Plan/apply real, publicación ECR y endpoint AWS requieren cuenta y credenciales del sandbox. No se ha creado una URL pública ni se afirma un despliegue realizado.

La entrega solo está completa después de un workflow verde y una validación pública exitosa en la cuenta sandbox.
