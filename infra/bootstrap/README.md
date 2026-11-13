# Configuración inicial de AWS

Este stack administra el proveedor OIDC de GitHub, el rol del pipeline, sus
políticas y el bucket del estado con versionamiento, cifrado y acceso público
bloqueado. El bucket rechaza conexiones sin TLS y está protegido contra la
eliminación mediante Terraform.

## Ejecutar

Desde una sesión administrativa de AWS CloudShell, en la raíz del proyecto:

```bash
bash scripts/setup-oidc.sh MaxCastro2904/cloudforge-java us-east-2 banbif-demo
```

El script instala Terraform 1.13.5 si no está disponible y verifica la descarga
con el archivo de sumas SHA256 del proveedor. Consulta los IDs públicos del
repositorio para configurar la confianza OIDC del entorno `production`.

Los recursos existentes se importan antes de generar y aplicar un plan. El
estado de este stack se conserva en `bootstrap/terraform.tfstate`, dentro del
mismo bucket que los estados `registry` y `service`.

En una cuenta nueva, primero se crea el bucket con estado local y después se
migra ese estado al backend S3. El archivo `backend.tf` se genera localmente y
no debe añadirse a Git. El archivo `.terraform.lock.hcl` sí debe versionarse.

Los workflows de la aplicación solo comprueban que el backend esté disponible;
no modifican su configuración. La identidad del pipeline puede crear nuevas
distribuciones CloudFront etiquetadas con el proyecto y administrar las que
conserven esa etiqueta.

## Separación de responsabilidades

La configuración inicial requiere permisos administrativos y se ejecuta antes
del pipeline. Las ejecuciones normales usan el rol creado por este stack.
El workflow de limpieza elimina los recursos de `service` y `registry`, pero
conserva IAM y el backend para mantener acceso al estado y a sus versiones.

No ejecutar este stack a la vez que un despliegue de la aplicación.
