using System.Text.Json;
using SGC.ApiWeb.Modelos;

namespace SGC.ApiWeb.Servicios;

public sealed class CatalogoEntidades
{
    private readonly IReadOnlyList<EntidadDefinicion> _entidades;
    private readonly Dictionary<string, EntidadDefinicion> _porRuta;

    public CatalogoEntidades(IHostEnvironment host)
    {
        string archivo = Path.Combine(host.ContentRootPath, "Datos", "catalogo-entidades.json");
        var json = File.ReadAllText(archivo);
        _entidades = JsonSerializer.Deserialize<List<EntidadDefinicion>>(json)
                    ?? throw new InvalidOperationException("No se puede cargar el catálogo de entidades.");
        _porRuta = _entidades.ToDictionary(x => x.Ruta, StringComparer.OrdinalIgnoreCase);
    }

    public IReadOnlyList<EntidadDefinicion> Todas => _entidades;
    public EntidadDefinicion? Buscar(string ruta) => _porRuta.GetValueOrDefault(ruta);
    public EntidadDefinicion? BuscarTabla(string nombreCompleto) =>
        _entidades.FirstOrDefault(x => string.Equals($"{x.Esquema}.{x.Tabla}", nombreCompleto, StringComparison.OrdinalIgnoreCase));
}
