# Contribuir a Zorah

Gracias por ayudar a mejorar Zorah. El proyecto acepta correcciones, pruebas,
documentación y nuevas integraciones para macOS.

## Requisitos

- Una Mac con Apple Silicon.
- macOS 15 o posterior.
- Swift y las Command Line Tools de Apple.
- Python 3 para las pruebas del detector legado.

## Preparar el proyecto

1. Crea un fork y clona tu copia.
2. Crea una rama descriptiva desde la rama principal.
3. Realiza cambios pequeños y enfocados.
4. Ejecuta las verificaciones antes de enviar un pull request.

```bash
./script/check.sh
```

Para abrir la aplicación durante el desarrollo:

```bash
./script/build_and_run.sh
```

Para comprobar el empaquetado local:

```bash
./script/package_release.sh
```

## Organización del código

- `Sources/Zorah/App`: ciclo de vida y escenas de la aplicación.
- `Sources/Zorah/Models`: modelos de datos.
- `Sources/Zorah/Services`: audio, voz, clima, Music y servicios del sistema.
- `Sources/Zorah/Stores`: estado compartido y persistencia.
- `Sources/Zorah/Views`: interfaz SwiftUI.
- `script`: construcción, validación y empaquetado.
- `tests`: pruebas del detector Python legado.

## Pull requests

- Explica el problema y el comportamiento que cambia.
- Incluye pasos de prueba reproducibles.
- Añade pruebas cuando cambies lógica compartida.
- No incluyas `.build/`, `dist/`, modelos pesados ni datos personales.
- Mantén la interfaz accesible mediante teclado y VoiceOver.
- Evita refactorizaciones ajenas al objetivo del pull request.

## Recursos y propiedad intelectual

Solo envía imágenes, sonidos o modelos que hayas creado o que tengan una
licencia compatible con su distribución. Los recursos de terceros deben
incluir atribución y condiciones de uso claras.

El icono actual de Zorah Magdaros está excluido de la licencia MIT. Consulta
`THIRD_PARTY_NOTICES.md` antes de reutilizarlo o modificarlo.

## Seguridad y privacidad

No incluyas grabaciones, transcripciones privadas, credenciales, certificados
de firma ni tokens de Apple o GitHub. Cualquier función que almacene o envíe
datos de voz debe ser opcional y estar documentada con claridad.
