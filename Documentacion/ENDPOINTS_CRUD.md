# Endpoints CRUD extraídos de SCG_db.sql

Se registran en **un mismo servidor ASP.NET Core**. Requieren cookie de sesión y token antifalsificación para escrituras. Las acciones de auditoría o movimientos inmutables pueden devolver 403/400 por políticas de negocio.

| Módulo | Tabla | GET listar / POST crear | GET por clave / PUT / DELETE |
|---|---|---|---|
| Seguridad | `seguridad.Rol` | `/api/seguridad/rol` | `/api/seguridad/rol/{clave}` |
| Seguridad | `seguridad.Permiso` | `/api/seguridad/permiso` | `/api/seguridad/permiso/{clave}` |
| Seguridad | `seguridad.RolPermiso` | `/api/seguridad/rol-permiso` | `/api/seguridad/rol-permiso/{clave}` |
| Seguridad | `seguridad.Usuario` | `/api/seguridad/usuario` | `/api/seguridad/usuario/{clave}` |
| Seguridad | `seguridad.UsuarioRol` | `/api/seguridad/usuario-rol` | `/api/seguridad/usuario-rol/{clave}` |
| Seguridad | `seguridad.BitacoraEvento` | `/api/seguridad/bitacora-evento` | `/api/seguridad/bitacora-evento/{clave}` |
| Clientes y catálogos | `catalogos.Cliente` | `/api/catalogos/cliente` | `/api/catalogos/cliente/{clave}` |
| Clientes y catálogos | `catalogos.Prospecto` | `/api/catalogos/prospecto` | `/api/catalogos/prospecto/{clave}` |
| Clientes y catálogos | `catalogos.Marca` | `/api/catalogos/marca` | `/api/catalogos/marca/{clave}` |
| Clientes y catálogos | `catalogos.EstadoEquipo` | `/api/catalogos/estado-equipo` | `/api/catalogos/estado-equipo/{clave}` |
| Clientes y catálogos | `catalogos.ModeloEquipo` | `/api/catalogos/modelo-equipo` | `/api/catalogos/modelo-equipo/{clave}` |
| Clientes y catálogos | `catalogos.Equipo` | `/api/catalogos/equipo` | `/api/catalogos/equipo/{clave}` |
| Clientes y catálogos | `catalogos.UnidadMedida` | `/api/catalogos/unidad-medida` | `/api/catalogos/unidad-medida/{clave}` |
| Clientes y catálogos | `catalogos.TipoArticulo` | `/api/catalogos/tipo-articulo` | `/api/catalogos/tipo-articulo/{clave}` |
| Clientes y catálogos | `catalogos.Articulo` | `/api/catalogos/articulo` | `/api/catalogos/articulo/{clave}` |
| Clientes y catálogos | `catalogos.CompatibilidadRepuesto` | `/api/catalogos/compatibilidad-repuesto` | `/api/catalogos/compatibilidad-repuesto/{clave}` |
| Inventario | `inventario.TipoMovimiento` | `/api/inventario/tipo-movimiento` | `/api/inventario/tipo-movimiento/{clave}` |
| Inventario | `inventario.MotivoMovimiento` | `/api/inventario/motivo-movimiento` | `/api/inventario/motivo-movimiento/{clave}` |
| Inventario | `inventario.MovimientoInventario` | `/api/inventario/movimiento-inventario` | `/api/inventario/movimiento-inventario/{clave}` |
| Comercial | `comercial.EstadoCotizacion` | `/api/comercial/estado-cotizacion` | `/api/comercial/estado-cotizacion/{clave}` |
| Comercial | `comercial.Cotizacion` | `/api/comercial/cotizacion` | `/api/comercial/cotizacion/{clave}` |
| Comercial | `comercial.DetalleCotizacion` | `/api/comercial/detalle-cotizacion` | `/api/comercial/detalle-cotizacion/{clave}` |
| Comercial | `comercial.TipoOperacion` | `/api/comercial/tipo-operacion` | `/api/comercial/tipo-operacion/{clave}` |
| Comercial | `comercial.EstadoOperacion` | `/api/comercial/estado-operacion` | `/api/comercial/estado-operacion/{clave}` |
| Comercial | `comercial.OperacionComercial` | `/api/comercial/operacion-comercial` | `/api/comercial/operacion-comercial/{clave}` |
| Comercial | `comercial.DetalleOperacion` | `/api/comercial/detalle-operacion` | `/api/comercial/detalle-operacion/{clave}` |
| Comercial | `comercial.Garantia` | `/api/comercial/garantia` | `/api/comercial/garantia/{clave}` |
| Comercial | `comercial.ContratoAlquiler` | `/api/comercial/contrato-alquiler` | `/api/comercial/contrato-alquiler/{clave}` |
| Comercial | `comercial.EquipoContratoAlquiler` | `/api/comercial/equipo-contrato-alquiler` | `/api/comercial/equipo-contrato-alquiler/{clave}` |
| Servicio técnico | `servicio_tecnico.EstadoSolicitudServicio` | `/api/servicio-tecnico/estado-solicitud-servicio` | `/api/servicio-tecnico/estado-solicitud-servicio/{clave}` |
| Servicio técnico | `servicio_tecnico.SolicitudServicio` | `/api/servicio-tecnico/solicitud-servicio` | `/api/servicio-tecnico/solicitud-servicio/{clave}` |
| Servicio técnico | `servicio_tecnico.EstadoOrdenTrabajo` | `/api/servicio-tecnico/estado-orden-trabajo` | `/api/servicio-tecnico/estado-orden-trabajo/{clave}` |
| Servicio técnico | `servicio_tecnico.OrdenTrabajo` | `/api/servicio-tecnico/orden-trabajo` | `/api/servicio-tecnico/orden-trabajo/{clave}` |
| Servicio técnico | `servicio_tecnico.AvanceOrdenTrabajo` | `/api/servicio-tecnico/avance-orden-trabajo` | `/api/servicio-tecnico/avance-orden-trabajo/{clave}` |
| Servicio técnico | `servicio_tecnico.RepuestoOrdenTrabajo` | `/api/servicio-tecnico/repuesto-orden-trabajo` | `/api/servicio-tecnico/repuesto-orden-trabajo/{clave}` |
| Lecturas | `operaciones.LecturaMensual` | `/api/operaciones/lectura-mensual` | `/api/operaciones/lectura-mensual/{clave}` |

## Endpoints de negocio

- `POST /api/negocio/inventario/movimiento`
- `POST /api/negocio/ordenes/{id}/cerrar`
- `POST /api/negocio/ventas/{id}/completar`
- `POST /api/negocio/cotizaciones/{id}/cambiar-estado`

## Reportes

- `GET /api/reportes/existencias`
- `GET /api/reportes/cotizaciones`
- `GET /api/reportes/ventas`
- `GET /api/reportes/historial-equipos/{id}`
