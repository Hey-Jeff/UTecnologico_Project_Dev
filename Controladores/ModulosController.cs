using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SGC.ApiWeb.Modelos;
using SGC.ApiWeb.Servicios;

namespace SGC.ApiWeb.Controladores;

[Authorize]
public sealed class ModulosController(CatalogoEntidades catalogo) : Controller
{
    [HttpGet("modulos/{ruta}")]
    public IActionResult Index(string ruta)
    {
        var entidad = catalogo.Buscar(ruta);
        if (entidad is null) return NotFound();
        if (!AccesoModulos.Puede(User, entidad, "Listar")) return Forbid();
        var modelo = new ModeloModulo { Entidad = entidad };
        var especial = entidad.Tabla switch
        {
            "Cliente" => "Clientes",
            "Equipo" => "Equipos",
            "Articulo" => "Articulos",
            "Cotizacion" => "Cotizaciones",
            "OrdenTrabajo" => "OrdenesTrabajo",
            "MovimientoInventario" => "Inventario",
            "OperacionComercial" => "VentasAlquileres",
            "LecturaMensual" => "LecturasMensuales",
            "SolicitudServicio" => "ServiciosTecnicos",
            "Usuario" => "Usuarios",
            _ => "Modulos"
        };
        return View($"~/Views/{especial}/Index.cshtml", modelo);
    }
}
