# Sistema de Gestión para Universo Tecnológico (SGC)

Proyecto en **C# / ASP.NET Core MVC (.NET 10)**, **Dapper**, **SQL Server** y vistas **Razor (.cshtml)**. Basado en el archivo `SCG_db.sql` y su catálogo de 36 tablas, con nombres en español. El proyecto contiene API REST + interfaz HTML en una misma aplicación.

> **Estado**: generación y revisión estática. No se ha compilado con el SDK de .NET ni se ha ejecutado contra una instancia real de SQL Server en este entorno. Debes hacer `dotnet restore`, `dotnet build` y las pruebas de integración en tu equipo.

## Requisitos

- SDK .NET 10 y SQL Server (SQL Server Express, Developer o Standard).
- Visual Studio 2022 actualizado con soporte para .NET 10 o VS Code con extensión C#.
- Base de datos `SGC_UniversoTecnologico` creada mediante `BaseDatos/SCG_db.sql` sobre **base nueva y vacía**; no ejecutes ese SQL sobre una base con tablas existentes.
- Usuario SQL con permisos adecuados. En producción, limita permisos al mínimo necesario, incluidos los SELECT específicos para login y reportes.

## Comenzar (PowerShell)

```powershell
cd SGC.ApiWeb
dotnet restore
# Configura la cadena de conexión
dotnet user-secrets set "ConnectionStrings:Principal" "Server=localhost;Database=SGC_UniversoTecnologico;Trusted_Connection=True;Encrypt=True;TrustServerCertificate=True;"
dotnet build
```

> `TrustServerCertificate=True` es únicamente una facilidad para **desarrollo local**. En producción instala un certificado válido y usa `Encrypt=True` con confianza de certificados normal.

### Inicializar el primer administrador para la pagina

El script SQL crea los **roles**, pero **no** crea una contraseña por defecto. Crea el primer usuario con variables de entorno temporales para que no se guarde un password en el repositorio:

```powershell
$env:SGC_ADMIN_USUARIO = "admin"
$env:SGC_ADMIN_CORREO = "admin@dominio.test"
$env:SGC_ADMIN_CLAVE = Read-Host "Contraseña segura inicial (mínimo 12 caracteres)"
dotnet run -- --crear-admin
Remove-Item Env:\SGC_ADMIN_USUARIO
Remove-Item Env:\SGC_ADMIN_CORREO
Remove-Item Env:\SGC_ADMIN_CLAVE
```

Este comando solo funciona si **seguridad.Usuario** está vacía. En instalaciones con usuarios preexistentes, utiliza una migración controlada o el panel de administración.

### Levantar aplicación

```powershell
dotnet run
```

- Página principal: `https://localhost:7240/`
- Acceso: `https://localhost:7240/acceso/ingresar`
- Swagger (solo desarrollo): `https://localhost:7240/swagger`
- Vista de endpoints: `https://localhost:7240/Inicio/Endpoints`
- Reportes: `https://localhost:7240/Reportes`

Si cambia el puerto, revisa `Properties/launchSettings.json` o la URL mostrada por `dotnet run`.

## Arquitectura

```
SGC.ApiWeb/
├─ Program.cs                          Configuración del sitio y de endpoints
├─ Controladores/                      Controladores MVC para las vistas
├─ Endpoints/                          REST (CRUD, negocio, reportes)
├─ Servicios/                           Autenticación, Dapper, SQL, validación
├─ Modelos/                             Metadatos y modelos del ingreso
├─ Datos/catalogo-entidades.json       36 tablas y firmas de SP (extraídas del SQL)
├─ Views/                               Razor HTML de los módulos
├─ wwwroot/js/                          AJAX de los formularios / reportes
├─ wwwroot/css/                         Estilos responsivos
└─ BaseDatos/SCG_db.sql                 SQL ORIGINAL de referencia
```

`catalogo-entidades.json` se extrajo del **SQL entregado por el usuario**, no de nombres adivinados. Contiene las firmas de los 180 procedimientos CRUD, tipos SQL, claves simples/compuestas y referencias entre tablas. La capa de endpoints utiliza únicamente ese **catálogo de nombres permitidos**, evitando recibir nombres de procedimientos/tabla arbitrarios desde solicitudes HTTP.

## Convención de API

Por cada tabla de las 36 se registran 5 rutas:

| Método | Ruta ejemplo | Procedimiento |
|---|---|---|
| GET | `/api/catalogos/cliente?pagina=1&tamanoPagina=25` | `catalogos.pa_Cliente_Listar` |
| GET | `/api/catalogos/cliente/1` | `catalogos.pa_Cliente_ObtenerPorId` |
| POST | `/api/catalogos/cliente` | `catalogos.pa_Cliente_Crear` |
| PUT | `/api/catalogos/cliente/1` | `catalogos.pa_Cliente_Actualizar` |
| DELETE | `/api/catalogos/cliente/1` | `catalogos.pa_Cliente_Eliminar` |

Para claves compuestas se usa una coma en la URL, por ejemplo `GET /api/seguridad/usuario-rol/1,2`.

### JSON para crear un cliente

```json
{
  "Identificacion": "1-1111-1111",
  "NombreORazonSocial": "Cliente de prueba",
  "Telefono": "8888-1111",
  "CorreoElectronico": "cliente@example.test",
  "Direccion": "San José, Costa Rica"
}
```

`PUT` es reemplazo completo: incluye los parámetros del procedimiento `Actualizar` (excepto la clave de la URL) y envía `null` para valores nullable. La vista construye los formularios con los parámetros exactos y usa la sesión activa.

### Operaciones especiales

- `POST /api/negocio/inventario/movimiento` — registra entrada o salida validada.
- `POST /api/negocio/ordenes/{id}/cerrar` — cierra orden y descuenta piezas una sola vez.
- `POST /api/negocio/ventas/{id}/completar` — completa venta y aplica stock.
- `POST /api/negocio/cotizaciones/{id}/cambiar-estado` — valida cambio de estado.
- `GET /api/reportes/existencias`
- `GET /api/reportes/cotizaciones`
- `GET /api/reportes/ventas?desde=2026-01-01&hasta=2026-12-31`
- `GET /api/reportes/historial-equipos/1`

El CRUD de auditoría y la modificación/eliminación de movimientos de inventario se restringen en la API. El CRUD de lecturas utiliza procedimientos que validan secuencia y trazabilidad. Las operaciones de negocio usan la identidad del usuario autenticado, no un `IdUsuario` arbitrario del navegador.

## Seguridad

- Autenticación por cookies, contraseña protegida con ASP.NET Core `PasswordHasher<T>`.
- Validación de roles en el servidor y comprobación de vigencia de sesión contra SQL Server.
- Las solicitudes de escritura `/api/*` desde HTML requieren un token antifalsificación de ASP.NET Core.
- Sin CORS abierto. Swagger solo en entorno Development.
- La API **no expone el hash** de contraseñas; al crear/editar un `Usuario` la interfaz solicita `Contrasena` o `ContrasenaNueva` y el servidor genera el hash.
- Restricción por roles a nivel de módulos. La autorización fina por permiso individual sigue pendiente de definirse con la empresa, según el documento funcional.
