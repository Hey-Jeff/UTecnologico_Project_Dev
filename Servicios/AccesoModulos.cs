using System.Security.Claims;
using SGC.ApiWeb.Modelos;

namespace SGC.ApiWeb.Servicios;

public static class AccesoModulos
{
    public static bool Puede(ClaimsPrincipal usuario, EntidadDefinicion entidad, string accion)
    {
        if (usuario.Identity?.IsAuthenticated != true) return false;
        var administrador = usuario.IsInRole("Administrador");
        var soporte = usuario.IsInRole("Gestor/Operativo");
        var cliente = usuario.IsInRole("Servicio al Cliente");
        var analista = usuario.IsInRole("Analista");
        if (administrador) return entidad.SoloLectura ? accion is "Listar" or "ObtenerPorId" : true;
        if (entidad.Esquema == "seguridad") return false;
        if (entidad.Esquema == "catalogos")
        {
            if (entidad.Tabla is "Cliente" or "Prospecto") return cliente || soporte;
            if (entidad.Tabla is "Equipo" or "ModeloEquipo" or "Marca" or "EstadoEquipo") return soporte || (cliente && EsConsulta(accion));
            return soporte;
        }
        if (entidad.Esquema == "inventario") return soporte;
        if (entidad.Esquema == "comercial") return cliente;
        if (entidad.Esquema == "servicio_tecnico" || entidad.Esquema == "operaciones") return soporte;
        return false;
    }

    private static bool EsConsulta(string accion) => accion == "Listar" || accion == "ObtenerPorId";

    public static bool PuedeReporte(ClaimsPrincipal usuario) =>
        usuario.IsInRole("Administrador") || usuario.IsInRole("Analista") || usuario.IsInRole("Servicio al Cliente");

    public static int IdUsuario(ClaimsPrincipal usuario)
    {
        string? valor = usuario.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(valor, out var id) || id < 1)
            throw new UnauthorizedAccessException("Sesión no válida.");
        return id;
    }
}
