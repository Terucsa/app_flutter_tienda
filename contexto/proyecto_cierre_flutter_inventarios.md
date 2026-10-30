PROGRAMACIÓN DE DISPOSITIVOS MÓVILES II
INVENTARIO INTELIGENTE
UMES UNIVERSIDAD MESOAMERICANA

Proyecto de cierre con Flutter
Desarrollar una aplicación móvil en Flutter que permita administrar productos, generar y leer códigos de barras y códigos QR, y registrar entradas y salidas de inventario.
La aplicación estará dirigida a una pequeña tienda o bodega que necesita consultar sus existencias y mantener un historial de movimientos.

Objetivo general
Construir una aplicación funcional que permita identificar productos mediante la cámara del dispositivo y actualizar el inventario de forma organizada, validando las operaciones y conservando la información.

1. Gestión de productos
Permitir registrar, consultar, editar y desactivar productos. Cada registro deberá incluir: código único, nombre, descripción, categoría, precio de compra, precio de venta y stock mínimo. La fotografía será opcional.
Las existencias iniciales deberán registrarse como un movimiento de entrada para conservar su trazabilidad.

2. Generación de códigos de barras y QR
Cada producto deberá contar con una etiqueta que incluya su nombre, código y representación escaneable. La aplicación deberá generar un código de barras Code 128 a partir del código único y un código QR que identifique el mismo producto.
Las etiquetas deberán poder mostrarse y compartirse o exportarse para impresión. Se deberán evitar códigos duplicados.
El código identifica al producto; las existencias se consultan en la base de datos. La cantidad disponible no debe guardarse dentro del QR, porque cambia con cada movimiento.

UMES | Segundo semestre 2026 | Proyecto de cierre
1

---

PROGRAMACIÓN DE DISPOSITIVOS MÓVILES II
CONTROL DE INVENTARIO
UMES UNIVERSIDAD MESOAMERICANA

3. Lectura con la cámara
El usuario podrá escanear códigos de barras o QR para buscar un producto, consultar sus datos y existencias, y registrar una entrada o salida. Cuando el código no esté registrado, la aplicación deberá mostrar un mensaje.
También deberá existir una búsqueda manual por código o nombre para los casos en que no sea posible utilizar la cámara.

4. Movimientos de inventario
Entrada: aumenta las existencias. Se deberá registrar la cantidad y el motivo, por ejemplo, compra o devolución.
Salida: disminuye las existencias. Se deberá registrar la cantidad y el motivo, por ejemplo, venta o daño.
Ajuste: corrige las existencias después de un conteo físico. Se deberá registrar la cantidad contada y una justificación obligatoria.
Cada movimiento deberá guardar el producto, la fecha y hora, el responsable, la cantidad anterior y la cantidad resultante.

Reglas de negocio
• Las cantidades de entrada y salida deben ser mayores que cero.
• No se permitirán salidas superiores al stock disponible.
• Un producto con movimientos no podrá eliminarse definitivamente; podrá desactivarse.
• Los movimientos confirmados no se editarán ni eliminarán. Los errores deberán corregirse mediante un nuevo movimiento.
• El registro del movimiento y la actualización de existencias deberán realizarse como una sola operación.

5. Consultas y reportes
Incluir un listado de productos con sus existencias, alertas de stock igual o inferior al mínimo e historial de movimientos filtrado por producto, tipo y fechas. Permitir exportar el inventario a CSV.
Calcular el valor del inventario como existencias x precio de compra registrado. Será una estimación basada en el precio registrado, sin implementar métodos contables de valoración.

UMES | Segundo semestre 2026 | Proyecto de cierre
2

---

PROGRAMACIÓN DE DISPOSITIVOS MÓVILES II
DISEÑO Y REQUISITOS
UMES UNIVERSIDAD MESOAMERICANA

Pantallas mínimas
1. Inicio: resumen de productos, alertas y accesos rápidos.
2. Productos: listado, búsqueda y filtros.
3. Formulario de producto: creación y edición.
4. Detalle del producto: datos, existencias y etiquetas.
5. Escáner: lectura de códigos de barras y QR.
6. Movimiento: registro de entradas, salidas y ajustes.
7. Historial y reportes: consultas y exportación.

Requisitos técnicos
• Desarrollar la aplicación en Flutter y Dart.
• Utilizar obligatoriamente la arquitectura feature + domain: organizar por funcionalidades y separar presentación, dominio y acceso a datos.
• Utilizar una estrategia consistente de gestión de estado.
• Guardar los datos de forma persistente. Para el alcance mínimo, se recomienda una base de datos local.
• Permitir las operaciones principales sin conexión a internet.
• Validar formularios y manejar errores de cámara, permisos y almacenamiento.
• Incluir estados de carga, mensajes de confirmación y estados vacíos.
• Probar el escaneo en un dispositivo físico.

Alcance mínimo: una tienda, una bodega y un dispositivo. La sincronización entre varios dispositivos puede desarrollarse como mejora adicional.

Modelo de datos sugerido
Producto: ID, código único, nombre, descripción, categoría, precios, stock actual, stock mínimo, fotografía y estado activo.
Categoría: ID y nombre.
Movimiento: ID, producto, tipo, cantidad, stock anterior, stock resultante, motivo, responsable, fecha y hora.
Para el alcance mínimo, el responsable puede definirse en un perfil local. Si se implementa inicio de sesión, deberá asociarse al usuario autenticado.

UMES | Segundo semestre 2026 | Proyecto de cierre
3

---

PROGRAMACIÓN DE DISPOSITIVOS MÓVILES II
DEMOSTRACIÓN Y ENTREGA
UMES UNIVERSIDAD MESOAMERICANA

Prueba de aceptación
Durante la presentación, el equipo deberá demostrar el siguiente flujo:
1. Registrar un producto con stock mínimo de 5 unidades.
2. Generar y mostrar su código de barras y su QR.
3. Registrar una entrada de 20 unidades.
4. Escanear uno de los códigos y registrar una salida de 16 unidades.
5. Verificar que quedan 4 unidades y aparece la alerta de stock bajo.
6. Intentar retirar 5 unidades y comprobar que la aplicación lo impide.
7. Realizar un conteo físico de 3 unidades y registrar el ajuste con su justificación.
8. Revisar el historial y exportar el inventario.
9. Cerrar y abrir la aplicación para comprobar que los datos permanecen guardados.

Ambos tipos de código deberán probarse durante la demostración.

Entregables
• Código fuente en un repositorio.
• APK funcional para Android.
• README.md con instrucciones de instalación y ejecución.
• Documentación técnica completa en archivos.md, con modelo de datos y arquitectura feature + domain.
• Manual de usuario en PDF, con instrucciones y capturas de pantalla.
• Datos de demostración con al menos 15 productos y 3 categorías.
• Evidencia de pruebas de las reglas de inventario.
• Presentación y demostración del sistema.

Ampliaciones opcionales
Se pueden incorporar usuarios con roles, múltiples bodegas, proveedores, respaldo de datos o sincronización en la nube. Estas mejoras deben desarrollarse después de completar el flujo obligatorio.

UMES | Segundo semestre 2026 | Proyecto de cierre
4

---

PROGRAMACIÓN DE DISPOSITIVOS MÓVILES II
DOCUMENTACIÓN OBLIGATORIA
UMES UNIVERSIDAD MESOAMERICANA

Arquitectura feature + domain
El proyecto deberá utilizar obligatoriamente la arquitectura feature + domain. Organizar el código por funcionalidades, como productos, inventario, escáner y reportes. Dentro de cada funcionalidad, separar las responsabilidades de presentación, dominio y datos.
El dominio deberá contener las entidades, los casos de uso y los contratos de repositorio. La capa de datos implementará los repositorios y el acceso al almacenamiento; la presentación contendrá las pantallas y la gestión de estado. Las reglas de inventario deberán implementarse en el dominio y no depender de los widgets ni de la base de datos.

Documentación técnica en Markdown (.md)
Se deberá documentar técnicamente todo el sistema mediante archivos .md incluidos en el repositorio. El README.md deberá funcionar como punto de entrada y enlazar los documentos técnicos. Los comentarios del código complementan esta documentación, pero no la sustituyen.
La documentación deberá incluir:
• Objetivo, alcance, requisitos y reglas de negocio.
• Instalación, configuración, dependencias y ejecución del proyecto.
• Arquitectura feature + domain, estructura de carpetas, responsabilidades y flujo de dependencias.
• Modelo de datos, diccionario de campos, relaciones y persistencia.
• Funcionalidades, casos de uso, gestión de estado y flujo de información.
• Generación y lectura de códigos de barras y QR, contenido codificado y permisos de cámara.
• Validaciones, manejo de errores y consistencia de los movimientos.
• Pruebas realizadas, pasos de reproducción, resultados y evidencias.
• Compilación del APK, limitaciones conocidas y mantenimiento.

Manual de usuario en PDF
Entregar un manual de usuario en formato PDF, separado de la documentación técnica. Deberá explicar, con instrucciones claras y capturas de pantalla, la instalación y los permisos, la gestión de productos, la generación y lectura de etiquetas, las entradas, salidas y ajustes, las alertas, el historial y la exportación del inventario.
Incluir los mensajes de error más comunes y cómo resolverlos. La documentación técnica y el manual deberán corresponder a la versión final entregada de la aplicación.

UMES | Segundo semestre 2026 | Proyecto de cierre
5