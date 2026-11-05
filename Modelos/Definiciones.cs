namespace SGC.ApiWeb.Modelos;

public sealed class ReferenciaCampo
{
    public string TablaDestino { get; set; } = "";
    public string CampoDestino { get; set; } = "";
}

public sealed class CampoEntidad
{
    public string Nombre { get; set; } = "";
    public string Titulo { get; set; } = "";
    public string TipoSql { get; set; } = "";
    public bool Nullable { get; set; }
    public bool EsClave { get; set; }
    public bool Autoincremental { get; set; }
    public ReferenciaCampo? Referencia { get; set; }
}

public sealed class ParametroProcedimiento
{
    public string Nombre { get; set; } = "";
    public string TipoSql { get; set; } = "";
    public bool Opcional { get; set; }
}

public sealed class EntidadDefinicion
{
    public string Esquema { get; set; } = "";
    public string Tabla { get; set; } = "";
    public string Nombre { get; set; } = "";
    public string Ruta { get; set; } = "";
    public string RutaApi { get; set; } = "";
    public string Titulo { get; set; } = "";
    public string Grupo { get; set; } = "";
    public string[] Claves { get; set; } = [];
    public List<CampoEntidad> Campos { get; set; } = [];
    public Dictionary<string,List<ParametroProcedimiento>> Parametros { get; set; } = [];
    public bool SoloLectura { get; set; }
    public string NombreProcedimiento(string accion) => $"{Esquema}.pa_{Tabla}_{accion}";
}

public sealed class ModeloModulo
{
    public required EntidadDefinicion Entidad { get; init; }
}

public sealed class CredencialSql
{
    public int IdUsuario { get; set; }
    public string NombreUsuario { get; set; } = "";
    public string ResumenCriptograficoContrasena { get; set; } = "";
    public bool Activo { get; set; }
}
