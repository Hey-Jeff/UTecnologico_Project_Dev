using Microsoft.Data.SqlClient;
using System.Globalization;

namespace SGC.ApiWeb.Endpoints;

public static class RespuestasApi
{
    public static IResult ManejarError(Exception error, ILogger logger)
    {
        switch (error)
        {
            case ArgumentException:
            case FormatException:
            case OverflowException:
            case System.Text.Json.JsonException:
                return Results.BadRequest(new { mensaje = "Datos inválidos: " + error.Message });
            case UnauthorizedAccessException:
                return Results.Unauthorized();
            case SqlException sql:
                if (sql.Number is 2627 or 2601 or 547)
                    return Results.Conflict(new { mensaje = "La operación viola una restricción de unicidad o relación." });
                if (sql.Number is 52001 or 52002 or 52008 or 52009 or 51110 or 51114 or 51202)
                    return Results.NotFound(new { mensaje = "El registro solicitado no existe." });
                if (sql.Number >= 50000 && sql.Number <= 52999)
                    return Results.BadRequest(new { mensaje = sql.Message });
                logger.LogError(sql, "Error de SQL Server: {Codigo}", sql.Number);
                return Results.Problem("Error al acceder a la base de datos.", statusCode: 500);
            default:
                logger.LogError(error, "Error no controlado en la API.");
                return Results.Problem("Error inesperado del servidor.", statusCode: 500);
        }
    }
}
