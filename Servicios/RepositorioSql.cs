using System.Data;
using Dapper;

namespace SGC.ApiWeb.Servicios;

public sealed class RepositorioSql(ConexionSql conexiones)
{
    private static Dictionary<string, object?> ConvertirFila(object fila)
    {
        var diccionario = (IDictionary<string, object>)fila;
        return diccionario.ToDictionary(x => x.Key, x => x.Value is DBNull ? null : x.Value,
            StringComparer.OrdinalIgnoreCase);
    }

    public async Task<IReadOnlyList<Dictionary<string, object?>>> FilasAsync(
        string procedimiento, object? parametros = null, CancellationToken cancelacion = default)
    {
        await using var conexion = conexiones.Crear();
        var respuesta = await conexion.QueryAsync(new CommandDefinition(
            procedimiento, parametros, commandType: CommandType.StoredProcedure,
            cancellationToken: cancelacion));
        return respuesta.Select(ConvertirFila).ToArray();
    }

    public async Task<Dictionary<string, object?>?> UnaFilaAsync(
        string procedimiento, object? parametros = null, CancellationToken cancelacion = default)
        => (await FilasAsync(procedimiento, parametros, cancelacion)).FirstOrDefault();

    public async Task<IReadOnlyList<Dictionary<string, object?>>> ConsultarAsync(
        string consultaConstante, object? parametros = null, CancellationToken cancelacion = default)
    {
        await using var conexion = conexiones.Crear();
        var respuesta = await conexion.QueryAsync(new CommandDefinition(
            consultaConstante, parametros, cancellationToken: cancelacion));
        return respuesta.Select(ConvertirFila).ToArray();
    }
}
