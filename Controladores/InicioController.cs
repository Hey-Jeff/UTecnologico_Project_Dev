using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SGC.ApiWeb.Modelos;
using SGC.ApiWeb.Servicios;

namespace SGC.ApiWeb.Controladores;

[Authorize]
public sealed class InicioController(CatalogoEntidades catalogo) : Controller
{
    public IActionResult Index()
    {
        var visibles = catalogo.Todas.Where(e => AccesoModulos.Puede(User, e, "Listar")).ToArray();
        return View(visibles);
    }

    public IActionResult Endpoints()
    {
        var visibles = catalogo.Todas.Where(e => AccesoModulos.Puede(User, e, "Listar")).ToArray();
        return View(visibles);
    }

    [AllowAnonymous]
    public IActionResult Error() => View();
}
