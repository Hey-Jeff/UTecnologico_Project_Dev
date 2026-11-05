using SGC.ApiWeb.Servicios;

namespace SGC.ApiWeb.Endpoints;

public static class ReportesEndpoints
{
    public static void Mapear(WebApplication app)
    {
        var grupo = app.MapGroup("/api/reportes").RequireAuthorization().WithTags("Reportes");

        grupo.MapGet("/existencias", async (HttpContext ctx, RepositorioSql repo) =>
        {
            if (!AccesoModulos.PuedeReporte(ctx.User)) return Results.Forbid();
            try
            {
                var filas = await repo.ConsultarAsync("""
                  SELECT * FROM inventario.Vista_ExistenciasArticulos
                  ORDER BY ExistenciaBaja DESC, NombreArticulo
                  """, cancelacion: ctx.RequestAborted);
                return Results.Ok(filas);
            }
            catch (Exception ex) { return Error(ex, ctx); }
        });

        grupo.MapGet("/cotizaciones", async (HttpContext ctx, RepositorioSql repo) =>
        {
            if (!AccesoModulos.PuedeReporte(ctx.User)) return Results.Forbid();
            try
            {
                var filas = await repo.ConsultarAsync(
                    "SELECT * FROM comercial.Vista_TotalesCotizaciones ORDER BY FechaCotizacion DESC",
                    cancelacion: ctx.RequestAborted);
                return Results.Ok(filas);
            }
            catch (Exception ex) { return Error(ex, ctx); }
        });

        grupo.MapGet("/ventas", async (DateTime? desde, DateTime? hasta,
            HttpContext ctx, RepositorioSql repo) =>
        {
            if (!AccesoModulos.PuedeReporte(ctx.User)) return Results.Forbid();
            if (desde.HasValue && hasta.HasValue && desde > hasta)
                return Results.BadRequest(new { mensaje = "El inicio no puede ser posterior al fin." });
            try
            {
                var filas = await repo.ConsultarAsync("""
                  SELECT * FROM comercial.Vista_TotalesOperaciones
                  WHERE (@Desde IS NULL OR FechaOperacion >= @Desde)
                    AND (@Hasta IS NULL OR FechaOperacion <= @Hasta)
                  ORDER BY FechaOperacion DESC
                  """, new { Desde = desde, Hasta = hasta }, ctx.RequestAborted);
                return Results.Ok(filas);
            }
            catch (Exception ex) { return Error(ex, ctx); }
        });

        grupo.MapGet("/historial-equipos/{id:int}", async (int id,
            HttpContext ctx, RepositorioSql repo) =>
        {
            if (!AccesoModulos.PuedeReporte(ctx.User)) return Results.Forbid();
            try
            {
                var filas = await repo.ConsultarAsync("""
                  SELECT * FROM catalogos.Vista_HistorialTecnicoEquipos WHERE IdEquipo=@Id
                  ORDER BY FechaApertura DESC
                  """, new { Id = id }, ctx.RequestAborted);
                return Results.Ok(filas);
            }
            catch (Exception ex) { return Error(ex, ctx); }
        });
    }

    private static IResult Error(Exception ex, HttpContext ctx) => RespuestasApi.ManejarError(ex,
        ctx.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("Reportes"));
}
