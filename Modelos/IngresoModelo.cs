using System.ComponentModel.DataAnnotations;

namespace SGC.ApiWeb.Modelos;

public sealed class IngresoModelo
{
    [Required(ErrorMessage = "Ingrese su usuario.")]
    [Display(Name = "Nombre de usuario")]
    public string Usuario { get; set; } = "";

    [Required(ErrorMessage = "Ingrese su contraseña.")]
    [DataType(DataType.Password)]
    [Display(Name = "Contraseña")]
    public string Contrasena { get; set; } = "";
}
