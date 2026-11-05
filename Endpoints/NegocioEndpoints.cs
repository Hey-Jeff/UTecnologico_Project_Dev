using Dapper;
using SGC.ApiWeb.Servicios;

namespace SGC.ApiWeb.Endpoints;

public static class NegocioEndpoints
{
    public sealed record Movimiento(int IdArticulo, int IdMotivoMovimiento, int Cantidad,
        string? Observaciones = null);
    public sealed record CambioEstado(int IdEstadoDestino, string? Comentario = null);
    public sealed record CierreOrden(string? Observaciones = null);

    public static void Mapear(WebApplication app)
    {
        var grupo = app.MapGroup("/api/negocio").RequireAuthorization().WithTags("Procesos de negocio");

        grupo.MapPost("/inventario/movimiento", async (Movimiento solicitud, HttpContext ctx, RepositorioSql repo) =>
        {
            if (!EsOperativo(ctx)) return Results.Forbid();
            try
            {
                var fila = await repo.UnaFilaAsync("inventario.pa_RegistrarMovimientoInventario", new
                {
                    solicitud.IdArticulo, solicitud.IdMotivoMovimiento, solicitud.Cantidad,
                    IdUsuario = AccesoModulos.IdUsuario(ctx.User), solicitud.Observaciones
                }, ctx.RequestAborted);
                return Results.Ok(fila);
            }
            catch (Exception ex) { return Error(ex, ctx); }
        });

        grupo.MapPost("/ordenes/{id:int}/cerrar", async (int id, CierreOrden solicitud,
            HttpContext ctx, RepositorioSql repo) =>
        {
            if (!EsOperativo(ctx)) return Results.Forbid();
            try
            {
                var fila = await repo.UnaFilaAsync("servicio_tecnico.pa_CerrarOrdenTrabajo", new
                {
                    IdOrdenTrabajo = id, IdUsuarioCierre = AccesoModulos.IdUsuario(ctx.User),
                    ObservacionesCierre = solicitud.Observaciones
                }, ctx.RequestAborted);
                return Results.Ok(fila);
            }
            catch (Exception ex) { return Error(ex, ctx); }
        });

        grupo.MapPost("/ventas/{id:int}/completar", async (int id, HttpContext ctx, RepositorioSql repo) =>
        {
            if (!EsComercial(ctx)) return Results.Forbid();
            try
            {
                var fila = await repo.UnaFilaAsync("comercial.pa_CompletarVenta", new
                {
                    IdOperacion = id, IdUsuarioResponsable = AccesoModulos.IdUsuario(ctx.User)
                }, ctx.RequestAborted);
                return Results.Ok(fila);
            }
            catch (Exception ex) { return Error(ex, ctx); }
        });

        grupo.MapPost("/cotizaciones/{id:int}/cambiar-estado", async (int id,
            CambioEstado solicitud, HttpContext ctx, RepositorioSql repo) =>
        {
            if (!EsComercial(ctx)) return Results.Forbid();
            try
            {
                var fila = await repo.UnaFilaAsync("comercial.pa_CambiarEstadoCotizacion", new
                {
                    IdCotizacion = id, solicitud.IdEstadoDestino,
                    IdUsuarioResponsable = AccesoModulos.IdUsuario(ctx.User), solicitud.Comentario
                }, ctx.RequestAborted);
                return Results.Ok(fila);
            }
            catch (Exception ex) { return Error(ex, ctx); }
        });
    }

    private static IResult Error(Exception ex, HttpContext ctx) => RespuestasApi.ManejarError(ex,
        ctx.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("Negocio"));
    private static bool EsOperativo(HttpContext c) => c.User.IsInRole("Administrador") || c.User.IsInRole("Gestor/Operativo");
    private static bool EsComercial(HttpContext c) => c.User.IsInRole("Administrador") || c.User.IsInRole("Servicio al Cliente");
}
