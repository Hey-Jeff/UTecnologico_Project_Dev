using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SGC.ApiWeb.Modelos;
using SGC.ApiWeb.Servicios;

namespace SGC.ApiWeb.Controladores;

[Route("acceso")]
public sealed class AccesoController(AutenticacionServicio servicio) : Controller
{
    [HttpGet("ingresar")]
    [AllowAnonymous]
    public IActionResult Ingresar() => View(new IngresoModelo());

    [HttpPost("ingresar")]
    [AllowAnonymous]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Ingresar(IngresoModelo modelo)
    {
        if (!ModelState.IsValid) return View(modelo);
        var principal = await servicio.IngresarAsync(modelo.Usuario.Trim(), modelo.Contrasena);
        if (principal is null)
        {
            ModelState.AddModelError(string.Empty, "Usuario o contraseña incorrectos, o cuenta sin roles activos.");
            return View(modelo);
        }
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme,
            principal, new AuthenticationProperties { IsPersistent = false });
        return RedirectToAction("Index", "Inicio");
    }

    [HttpPost("salir")]
    [Authorize]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Salir()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction(nameof(Ingresar));
    }

    [HttpGet("prohibido")]
    [AllowAnonymous]
    public IActionResult Prohibido() => View();
}
