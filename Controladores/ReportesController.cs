using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SGC.ApiWeb.Servicios;

namespace SGC.ApiWeb.Controladores;

[Authorize]
public sealed class ReportesController : Controller
{
    public IActionResult Index()
    {
        if (!AccesoModulos.PuedeReporte(User)) return Forbid();
        return View();
    }
}
