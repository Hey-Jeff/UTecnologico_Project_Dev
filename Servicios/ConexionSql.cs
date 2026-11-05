using Microsoft.Data.SqlClient;

namespace SGC.ApiWeb.Servicios;

public sealed class ConexionSql(IConfiguration config)
{
    public SqlConnection Crear()
    {
        var cadena = config.GetConnectionString("Principal");
        if (string.IsNullOrWhiteSpace(cadena))
            throw new InvalidOperationException("Configure ConnectionStrings:Principal mediante secretos de usuario o variables de entorno.");
        return new SqlConnection(cadena);
    }
}
