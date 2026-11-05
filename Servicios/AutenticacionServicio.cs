using Dapper;
using Microsoft.AspNetCore.Identity;
using System.Data;
using System.Security.Claims;
using SGC.ApiWeb.Modelos;

namespace SGC.ApiWeb.Servicios;

public sealed class AutenticacionServicio(ConexionSql conexiones)
{
    private readonly PasswordHasher<CredencialSql> _hasher = new();

    public async Task<ClaimsPrincipal?> IngresarAsync(string usuario, string contrasena)
    {
        await using var conexion = conexiones.Crear();
        var credencial = await conexion.QuerySingleOrDefaultAsync<CredencialSql>(
            "seguridad.pa_Usuario_ObtenerCredenciales",
            new { NombreUsuario = usuario }, commandType: CommandType.StoredProcedure);
        if (credencial is null || !credencial.Activo) return null;
        var verificacion = _hasher.VerifyHashedPassword(
            credencial, credencial.ResumenCriptograficoContrasena, contrasena);
        if (verificacion == PasswordVerificationResult.Failed) return null;
        var roles = (await ObtenerRolesAsync(conexion, credencial.IdUsuario)).ToArray();
        if (roles.Length == 0) return null;
        return ConstruirPrincipal(credencial.IdUsuario, credencial.NombreUsuario, roles);
    }

    private static ClaimsPrincipal ConstruirPrincipal(int id, string usuario, string[] roles)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, id.ToString()),
            new(ClaimTypes.Name, usuario)
        };
        claims.AddRange(roles.Select(x => new Claim(ClaimTypes.Role, x)));
        return new ClaimsPrincipal(new ClaimsIdentity(claims,
            Microsoft.AspNetCore.Authentication.Cookies.CookieAuthenticationDefaults.AuthenticationScheme));
    }

    private static async Task<IEnumerable<string>> ObtenerRolesAsync(System.Data.IDbConnection db, int id)
    {
        return await db.QueryAsync<string>("""
          SELECT r.NombreRol FROM seguridad.UsuarioRol ur
          JOIN seguridad.Rol r ON r.IdRol = ur.IdRol
          WHERE ur.IdUsuario = @IdUsuario AND r.Activo=1
          """, new { IdUsuario = id });
    }

    public async Task<bool> EsSesionVigenteAsync(ClaimsPrincipal usuario)
    {
        if (!int.TryParse(usuario.FindFirstValue(ClaimTypes.NameIdentifier), out var id)) return false;
        await using var conexion = conexiones.Crear();
        var existente = await conexion.QuerySingleOrDefaultAsync<int?>(
            "SELECT IdUsuario FROM seguridad.Usuario WHERE IdUsuario=@Id AND Activo=1", new { Id = id });
        if (existente is null) return false;
        var roles = (await ObtenerRolesAsync(conexion, id)).OrderBy(x => x).ToArray();
        var guardados = usuario.FindAll(ClaimTypes.Role).Select(x => x.Value).OrderBy(x => x).ToArray();
        return roles.SequenceEqual(guardados);
    }

    public string CrearResumenSeguro(string contrasena)
    {
        if (contrasena.Length < 12 || contrasena.Length > 128)
            throw new ArgumentException("La contraseña debe tener entre 12 y 128 caracteres.");
        return _hasher.HashPassword(new CredencialSql(), contrasena);
    }

    public async Task CrearAdministradorInicialAsync()
    {
        var nombre = Environment.GetEnvironmentVariable("SGC_ADMIN_USUARIO");
        var correo = Environment.GetEnvironmentVariable("SGC_ADMIN_CORREO");
        var clave = Environment.GetEnvironmentVariable("SGC_ADMIN_CLAVE");
        if (string.IsNullOrWhiteSpace(nombre) || string.IsNullOrWhiteSpace(correo) || string.IsNullOrWhiteSpace(clave))
            throw new InvalidOperationException("Configure SGC_ADMIN_USUARIO, SGC_ADMIN_CORREO y SGC_ADMIN_CLAVE para crear el administrador inicial.");
        string resumen = CrearResumenSeguro(clave);
        await using var db = conexiones.Crear();
        await db.OpenAsync();
        await using var transaccion = await db.BeginTransactionAsync();
        try
        {
            int cuenta = await db.QuerySingleAsync<int>(
                "SELECT COUNT(*) FROM seguridad.Usuario", transaction: transaccion);
            if (cuenta != 0)
                throw new InvalidOperationException("La creación inicial solo funciona si no hay usuarios. Administre los usuarios desde el panel después de iniciar sesión.");
            int id = await db.QuerySingleAsync<int>("""
              INSERT INTO seguridad.Usuario
              (NombreUsuario, ResumenCriptograficoContrasena, NombreCompleto, CorreoElectronico, Activo)
              VALUES (@Nombre, @Resumen, @Nombre, @Correo, 1);
              SELECT CAST(SCOPE_IDENTITY() AS INT);
              """, new { Nombre = nombre, Resumen = resumen, Correo = correo }, transaccion);
            int rol = await db.QuerySingleAsync<int>(
                "SELECT IdRol FROM seguridad.Rol WHERE NombreRol=N'Administrador'", transaction: transaccion);
            await db.ExecuteAsync(
                "INSERT INTO seguridad.UsuarioRol (IdUsuario,IdRol) VALUES(@Id,@Rol)",
                new { Id = id, Rol = rol }, transaccion);
            await transaccion.CommitAsync();
        }
        catch
        {
            await transaccion.RollbackAsync();
            throw;
        }
    }
}
