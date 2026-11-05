using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Antiforgery;
using SGC.ApiWeb.Endpoints;
using SGC.ApiWeb.Servicios;

var constructor = WebApplication.CreateBuilder(args);

constructor.Services.AddControllersWithViews();
constructor.Services.AddAntiforgery(configuracion => configuracion.HeaderName = "RequestVerificationToken");
constructor.Services.AddSwaggerGen();
constructor.Services.AddSingleton<CatalogoEntidades>();
constructor.Services.AddSingleton<ConexionSql>();
constructor.Services.AddScoped<RepositorioSql>();
constructor.Services.AddScoped<AutenticacionServicio>();
constructor.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(opciones =>
    {
        opciones.LoginPath = "/acceso/ingresar";
        opciones.AccessDeniedPath = "/acceso/prohibido";
        opciones.ExpireTimeSpan = TimeSpan.FromHours(8);
        opciones.SlidingExpiration = true;
        opciones.Cookie.HttpOnly = true;
        opciones.Cookie.SameSite = SameSiteMode.Lax;
        opciones.Cookie.SecurePolicy = constructor.Environment.IsDevelopment()
            ? CookieSecurePolicy.SameAsRequest : CookieSecurePolicy.Always;
        opciones.Events.OnValidatePrincipal = async contexto =>
        {
            var servicio = contexto.HttpContext.RequestServices.GetRequiredService<AutenticacionServicio>();
            bool valida;
            try { valida = await servicio.EsSesionVigenteAsync(contexto.Principal!); }
            catch { valida = false; }
            if (!valida)
            {
                contexto.RejectPrincipal();
                await contexto.HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            }
        };
        opciones.Events.OnRedirectToLogin = contexto =>
        {
            if (contexto.Request.Path.StartsWithSegments("/api"))
            {
                contexto.Response.StatusCode = StatusCodes.Status401Unauthorized;
                return Task.CompletedTask;
            }
            contexto.Response.Redirect(contexto.RedirectUri);
            return Task.CompletedTask;
        };
        opciones.Events.OnRedirectToAccessDenied = contexto =>
        {
            if (contexto.Request.Path.StartsWithSegments("/api"))
            {
                contexto.Response.StatusCode = StatusCodes.Status403Forbidden;
                return Task.CompletedTask;
            }
            contexto.Response.Redirect(contexto.RedirectUri);
            return Task.CompletedTask;
        };
    });
constructor.Services.AddAuthorization();

var aplicacion = constructor.Build();

if (args.Contains("--crear-admin"))
{
    using var alcance = aplicacion.Services.CreateScope();
    await alcance.ServiceProvider.GetRequiredService<AutenticacionServicio>()
        .CrearAdministradorInicialAsync();
    Console.WriteLine("Administrador inicial creado. Quite las variables SGC_ADMIN_* del entorno.");
    return;
}

if (!aplicacion.Environment.IsDevelopment())
{
    aplicacion.UseExceptionHandler("/inicio/error");
    aplicacion.UseHsts();
}
else
{
    aplicacion.UseSwagger();
    aplicacion.UseSwaggerUI();
}

aplicacion.UseHttpsRedirection();
aplicacion.UseStaticFiles();
aplicacion.UseRouting();
aplicacion.UseAuthentication();

// Protege las peticiones AJAX de la misma sesión contra falsificación de solicitudes.
aplicacion.Use(async (contexto, siguiente) =>
{
    if (contexto.Request.Path.StartsWithSegments("/api") &&
        !HttpMethods.IsGet(contexto.Request.Method) &&
        !HttpMethods.IsHead(contexto.Request.Method) &&
        !HttpMethods.IsOptions(contexto.Request.Method))
    {
        var antifalsificacion = contexto.RequestServices.GetRequiredService<IAntiforgery>();
        try { await antifalsificacion.ValidateRequestAsync(contexto); }
        catch (AntiforgeryValidationException)
        {
            contexto.Response.StatusCode = 400;
            await contexto.Response.WriteAsJsonAsync(new { mensaje = "Falta el token de protección de la solicitud." });
            return;
        }
    }
    await siguiente();
});

aplicacion.UseAuthorization();

CrudEndpoints.Mapear(aplicacion);
NegocioEndpoints.Mapear(aplicacion);
ReportesEndpoints.Mapear(aplicacion);

aplicacion.MapControllerRoute("predeterminada", "{controller=Inicio}/{action=Index}/{id?}");
aplicacion.Run();
