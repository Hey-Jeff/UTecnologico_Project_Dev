using SGC.ApiWeb.Modelos;
using SGC.ApiWeb.Servicios;

namespace SGC.ApiWeb.Endpoints;

public static class CrudEndpoints
{
    public static void Mapear(WebApplication app)
    {
        var catalogo = app.Services.GetRequiredService<CatalogoEntidades>();
        foreach (var entidad in catalogo.Todas)
        {
            var actual = entidad; // se captura una definición inmutable por grupo
            var grupo = app.MapGroup(actual.RutaApi).RequireAuthorization().WithTags(actual.Titulo);

            grupo.MapGet("", async (HttpContext contexto, RepositorioSql repo, int pagina = 1, int tamanoPagina = 25) =>
            {
                if (!AccesoModulos.Puede(contexto.User, actual, "Listar")) return Results.Forbid();
                if (pagina < 1 || tamanoPagina is < 1 or > 200)
                    return Results.BadRequest(new { mensaje = "Paginación inválida: máximo 200 por página." });
                try
                {
                    var datos = await repo.FilasAsync(actual.NombreProcedimiento("Listar"),
                        new { Pagina = pagina, TamanoPagina = tamanoPagina }, contexto.RequestAborted);
                    return Results.Ok(datos);
                }
                catch (Exception ex) { return RespuestasApi.ManejarError(ex, contexto.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("Crud")); }
            }).WithName($"Listar{actual.Esquema}_{actual.Tabla}");

            grupo.MapGet("/{clave}", async (string clave, HttpContext contexto,
                RepositorioSql repo, AutenticacionServicio seguridad) =>
            {
                if (!AccesoModulos.Puede(contexto.User, actual, "ObtenerPorId")) return Results.Forbid();
                try
                {
                    var parametros = ParametrosSql.Construir(actual, "ObtenerPorId", null,
                        clave, AccesoModulos.IdUsuario(contexto.User), seguridad);
                    var fila = await repo.UnaFilaAsync(actual.NombreProcedimiento("ObtenerPorId"),
                        parametros, contexto.RequestAborted);
                    return fila is null ? Results.NotFound() : Results.Ok(fila);
                }
                catch (Exception ex) { return RespuestasApi.ManejarError(ex, contexto.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("Crud")); }
            }).WithName($"Obtener{actual.Esquema}_{actual.Tabla}");

            grupo.MapPost("", async (HttpContext contexto, RepositorioSql repo, AutenticacionServicio seguridad) =>
                await Escribir(actual, "Crear", null, contexto, repo, seguridad))
                .WithName($"Crear{actual.Esquema}_{actual.Tabla}");

            grupo.MapPut("/{clave}", async (string clave, HttpContext contexto,
                RepositorioSql repo, AutenticacionServicio seguridad) =>
                await Escribir(actual, "Actualizar", clave, contexto, repo, seguridad))
                .WithName($"Actualizar{actual.Esquema}_{actual.Tabla}");

            grupo.MapDelete("/{clave}", async (string clave, HttpContext contexto,
                RepositorioSql repo, AutenticacionServicio seguridad) =>
                await Escribir(actual, "Eliminar", clave, contexto, repo, seguridad))
                .WithName($"Eliminar{actual.Esquema}_{actual.Tabla}");
        }
    }

    private static async Task<IResult> Escribir(EntidadDefinicion entidad, string accion, string? clave,
        HttpContext contexto, RepositorioSql repositorio, AutenticacionServicio seguridad)
    {
        if (!AccesoModulos.Puede(contexto.User, entidad, accion)) return Results.Forbid();
        // Inmutabilidad explícita de los movimientos y de la auditoría.
        if (entidad.Esquema == "seguridad" && entidad.Tabla == "BitacoraEvento") return Results.Forbid();
        if (entidad.Esquema == "inventario" && entidad.Tabla == "MovimientoInventario"
            && accion is "Actualizar" or "Eliminar") return Results.BadRequest(new { mensaje = "Los movimientos son inmutables." });
        try
        {
            var cuerpo = accion == "Eliminar" ? null : await ParametrosSql.LeerCuerpoAsync(contexto);
            var parametros = ParametrosSql.Construir(entidad, accion, cuerpo, clave,
                AccesoModulos.IdUsuario(contexto.User), seguridad);
            var fila = await repositorio.UnaFilaAsync(entidad.NombreProcedimiento(accion),
                parametros, contexto.RequestAborted);
            return fila is not null
                ? Results.Ok(fila)
                : Results.Ok(new { mensaje = "Operación completada." });
        }
        catch (Exception ex)
        {
            return RespuestasApi.ManejarError(ex,
                contexto.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("Crud"));
        }
    }
}
