using System.Globalization;
using System.Text.Json;
using Dapper;
using SGC.ApiWeb.Modelos;

namespace SGC.ApiWeb.Servicios;

public static class ParametrosSql
{
    public static async Task<Dictionary<string, JsonElement>> LeerCuerpoAsync(HttpContext ctx)
    {
        if (ctx.Request.ContentLength > 64 * 1024)
            throw new ArgumentException("El contenido es demasiado grande.");
        using var documento = await JsonDocument.ParseAsync(ctx.Request.Body,
            new JsonDocumentOptions { MaxDepth = 8 }, ctx.RequestAborted);
        if (documento.RootElement.ValueKind != JsonValueKind.Object)
            throw new ArgumentException("Debe enviar un objeto JSON.");
        return documento.RootElement.EnumerateObject()
            .ToDictionary(x => x.Name, x => x.Value.Clone(), StringComparer.OrdinalIgnoreCase);
    }

    public static DynamicParameters Construir(
        EntidadDefinicion entidad,
        string accion,
        IReadOnlyDictionary<string, JsonElement>? cuerpo,
        string? clave,
        int idSesion,
        AutenticacionServicio seguridad)
    {
        var parametros = new DynamicParameters();
        var esperados = entidad.Parametros[accion];
        string[] elementosClave = clave is null ? Array.Empty<string>() : clave.Split(',', StringSplitOptions.TrimEntries);
        if (clave is not null && elementosClave.Length != entidad.Claves.Length)
            throw new ArgumentException($"La clave del registro contiene {entidad.Claves.Length} valores separados por comas.");

        var llaves = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        for (int i = 0; i < elementosClave.Length; i++)
            llaves[entidad.Claves[i]] = elementosClave[i];

        foreach (var parametro in esperados)
        {
            var nombre = parametro.Nombre;
            if (llaves.TryGetValue(nombre, out var valorClave))
            {
                parametros.Add(nombre, ConvertirCadena(valorClave, parametro.TipoSql));
                continue;
            }
            if (accion == "Crear" && EsIdDeAutor(entidad, nombre))
            {
                parametros.Add(nombre, idSesion);
                continue;
            }
            if (accion == "Eliminar" && nombre == "IdUsuarioResponsable")
            {
                parametros.Add(nombre, idSesion);
                continue;
            }
            if (entidad.Tabla == "Usuario" && nombre == "ResumenCriptograficoContrasena")
            {
                string campoClave = accion == "Crear" ? "Contrasena" : "ContrasenaNueva";
                if (cuerpo is null || !cuerpo.TryGetValue(campoClave, out var valorClaveUsuario)
                    || valorClaveUsuario.ValueKind != JsonValueKind.String)
                    throw new ArgumentException($"El campo {campoClave} es obligatorio al {accion.ToLowerInvariant()} un usuario.");
                parametros.Add(nombre, seguridad.CrearResumenSeguro(valorClaveUsuario.GetString() ?? ""));
                continue;
            }
            if (cuerpo is not null && cuerpo.TryGetValue(nombre, out var valor))
            {
                parametros.Add(nombre, ConvertirValor(valor, parametro.TipoSql));
                continue;
            }
            if (parametro.Opcional) continue; // permite que SQL utilice su valor predeterminado
            throw new ArgumentException($"Falta el campo obligatorio: {nombre}.");
        }
        if (cuerpo is not null)
        {
            var permitidos = new HashSet<string>(esperados.Select(x => x.Nombre), StringComparer.OrdinalIgnoreCase);
            if (entidad.Tabla == "Usuario")
                permitidos.Add(accion == "Crear" ? "Contrasena" : "ContrasenaNueva");
            permitidos.Remove("ResumenCriptograficoContrasena");
            foreach (var campo in cuerpo.Keys)
                if (!permitidos.Contains(campo))
                    throw new ArgumentException($"Campo no permitido: {campo}.");
        }
        return parametros;
    }

    private static bool EsIdDeAutor(EntidadDefinicion e, string nombre)
    {
        string tablaCompleta = $"{e.Esquema}.{e.Tabla}";
        return (tablaCompleta == "inventario.MovimientoInventario" && nombre == "IdUsuario")
            || (tablaCompleta == "operaciones.LecturaMensual" && nombre == "IdUsuarioLectura")
            || ((tablaCompleta == "comercial.Cotizacion"
                || tablaCompleta == "comercial.OperacionComercial"
                || tablaCompleta == "servicio_tecnico.SolicitudServicio") && nombre == "IdUsuarioCreador")
            || (tablaCompleta == "servicio_tecnico.AvanceOrdenTrabajo" && nombre == "IdUsuarioRegistro");
    }

    private static object? ConvertirValor(JsonElement valor, string tipo)
    {
        if (valor.ValueKind is JsonValueKind.Null or JsonValueKind.Undefined) return null;
        string texto = valor.ValueKind == JsonValueKind.String ? valor.GetString() ?? "" : valor.GetRawText();
        return ConvertirCadena(texto, tipo);
    }

    private static object? ConvertirCadena(string texto, string tipo)
    {
        if (tipo.StartsWith("NVARCHAR", StringComparison.OrdinalIgnoreCase)
            || tipo.StartsWith("VARCHAR", StringComparison.OrdinalIgnoreCase))
        {
            if (tipo.Contains('('))
            {
                var maximoTexto = tipo.Split('(', ')')[1];
                if (int.TryParse(maximoTexto, out int maximo) && texto.Length > maximo)
                    throw new ArgumentException($"Texto demasiado largo (máximo {maximo}).");
            }
            return texto;
        }
        if (string.IsNullOrWhiteSpace(texto)) return null;
        if (tipo.StartsWith("BIGINT")) return long.Parse(texto, CultureInfo.InvariantCulture);
        if (tipo.StartsWith("SMALLINT")) return short.Parse(texto, CultureInfo.InvariantCulture);
        if (tipo.StartsWith("TINYINT")) return byte.Parse(texto, CultureInfo.InvariantCulture);
        if (tipo.StartsWith("INT")) return int.Parse(texto, CultureInfo.InvariantCulture);
        if (tipo.StartsWith("DECIMAL") || tipo.StartsWith("NUMERIC"))
            return decimal.Parse(texto, CultureInfo.InvariantCulture);
        if (tipo.StartsWith("BIT"))
        {
            if (texto == "1") return true;
            if (texto == "0") return false;
            return bool.Parse(texto);
        }
        if (tipo.StartsWith("DATE") || tipo.StartsWith("DATETIME"))
            return DateTime.Parse(texto, CultureInfo.InvariantCulture, DateTimeStyles.None);
        throw new ArgumentException($"Tipo SQL sin conversor: {tipo}.");
    }
}
