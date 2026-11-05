# Ejemplo de Dapper que llama al procedimiento real

```csharp
using Dapper;
using Microsoft.Data.SqlClient;
using System.Data;

var cadena = builder.Configuration.GetConnectionString("Principal");
await using var conexion = new SqlConnection(cadena);

var clientes = await conexion.QueryAsync(
    "catalogos.pa_Cliente_Listar",
    new { Pagina = 1, TamanoPagina = 25 },
    commandType: CommandType.StoredProcedure);

var cliente = await conexion.QuerySingleOrDefaultAsync(
    "catalogos.pa_Cliente_ObtenerPorId",
    new { IdCliente = 1 },
    commandType: CommandType.StoredProcedure);
```

La aplicación real concentra esta lógica en `Servicios/RepositorioSql.cs`.
Para operaciones de escritura usa `DynamicParameters`, con tipos convertidos según
`Datos/catalogo-entidades.json`. Así evita crear a mano 36 repositorios repetidos.
