/*
 SGC Universo Tecnológico - SQL Server + ASP.NET Core / Dapper
 Compatible con SQL Server 2012 o posterior; no utiliza CREATE OR ALTER
 Fuente: "Proyecto Final - SGC - GP#3.pdf"
 ATENCIÓN: ejecutar únicamente sobre una base de datos NUEVA y vacía.
 No ejecutar sobre una BD con datos preexistentes sin plan de migración y respaldo.
*/

/*==============================================================
  Proyecto   : Sistema de Gestión para Universo Tecnológico (SGC)
  Motor      : Microsoft SQL Server
  Objetivo   : Script de creación de base de datos en Tercera Forma Normal (3FN)
  Referencia : Proyecto Final - SGC - GP#3.pdf
  Notas      :
    - Se conserva historial; por eso varios procesos usan inactivación/cierre
      en vez de eliminación física.
    - Las existencias se calculan mediante los movimientos de inventario.
    - La garantía de ventas de equipos se genera automáticamente mediante un desencadenador.
    - El cierre de órdenes descuenta inventario mediante procedimiento.
==============================================================*/

SET NOCOUNT ON;
GO

IF DB_ID(N'SGC_UniversoTecnologico') IS NULL
    CREATE DATABASE SGC_UniversoTecnologico;
GO

USE SGC_UniversoTecnologico;
GO

/*========================
  ESQUEMAS
========================*/
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'seguridad') EXEC('CREATE SCHEMA seguridad');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'catalogos') EXEC('CREATE SCHEMA catalogos');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'inventario') EXEC('CREATE SCHEMA inventario');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'comercial') EXEC('CREATE SCHEMA comercial');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'servicio_tecnico') EXEC('CREATE SCHEMA servicio_tecnico');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'operaciones') EXEC('CREATE SCHEMA operaciones');
GO

/*========================
  SEGURIDAD Y AUDITORÍA
========================*/
CREATE TABLE seguridad.Rol (
    IdRol               INT IDENTITY(1,1) PRIMARY KEY,
    NombreRol             NVARCHAR(80) NOT NULL,
    DescripcionRol      NVARCHAR(250) NULL,
    Activo             BIT NOT NULL CONSTRAINT PREDET_Rol_Activo DEFAULT (1),
    CONSTRAINT UNICO_Rol_NombreRol UNIQUE (NombreRol)
);
GO

CREATE TABLE seguridad.Permiso (
    IdPermiso         INT IDENTITY(1,1) PRIMARY KEY,
    CodigoPermiso       NVARCHAR(50) NOT NULL,
    NombrePermiso       NVARCHAR(120) NOT NULL,
    DescripcionPermiso NVARCHAR(250) NULL,
    CONSTRAINT UNICO_Permiso_Codigo UNIQUE (CodigoPermiso),
    CONSTRAINT UNICO_Permiso_Nombre UNIQUE (NombrePermiso)
);
GO

CREATE TABLE seguridad.RolPermiso (
    IdRol               INT NOT NULL,
    IdPermiso         INT NOT NULL,
    PRIMARY KEY (IdRol, IdPermiso),
    CONSTRAINT REFERENCIA_RolPermiso_Rol FOREIGN KEY (IdRol) REFERENCES seguridad.Rol(IdRol),
    CONSTRAINT REFERENCIA_RolPermiso_Permiso FOREIGN KEY (IdPermiso) REFERENCES seguridad.Permiso(IdPermiso)
);
GO

CREATE TABLE seguridad.Usuario (
    IdUsuario               INT IDENTITY(1,1) PRIMARY KEY,
    NombreUsuario             NVARCHAR(50) NOT NULL,
    ResumenCriptograficoContrasena         NVARCHAR(255) NOT NULL,
    NombreCompleto             NVARCHAR(150) NOT NULL,
    CorreoElectronico                NVARCHAR(150) NOT NULL,
    Telefono                NVARCHAR(30) NULL,
    Activo             BIT NOT NULL CONSTRAINT PREDET_Usuario_Activo DEFAULT (1),
    FechaCreacion            DATETIME2(0) NOT NULL CONSTRAINT PREDET_Usuario_FechaCreacion DEFAULT (SYSDATETIME()),
    FechaActualizacion            DATETIME2(0) NOT NULL CONSTRAINT PREDET_Usuario_FechaActualizacion DEFAULT (SYSDATETIME()),
    CONSTRAINT UNICO_Usuario_NombreUsuario UNIQUE (NombreUsuario),
    CONSTRAINT UNICO_Usuario_CorreoElectronico UNIQUE (CorreoElectronico)
);
GO

CREATE TABLE seguridad.UsuarioRol (
    IdUsuario               INT NOT NULL,
    IdRol               INT NOT NULL,
    PRIMARY KEY (IdUsuario, IdRol),
    CONSTRAINT REFERENCIA_UsuarioRol_Usuario FOREIGN KEY (IdUsuario) REFERENCES seguridad.Usuario(IdUsuario),
    CONSTRAINT REFERENCIA_UsuarioRol_Rol FOREIGN KEY (IdRol) REFERENCES seguridad.Rol(IdRol)
);
GO

CREATE TABLE seguridad.BitacoraEvento (
    IdBitacoraEvento           BIGINT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario               INT NULL,
    NombreEntidad           NVARCHAR(128) NOT NULL,
    ClaveRegistro            NVARCHAR(128) NULL,
    TipoAccion           NVARCHAR(50) NOT NULL,
    FechaAccion           DATETIME2(0) NOT NULL CONSTRAINT PREDET_BitacoraEvento_FechaAccion DEFAULT (SYSDATETIME()),
    Comentario             NVARCHAR(400) NULL,
    CONSTRAINT REFERENCIA_BitacoraEvento_Usuario FOREIGN KEY (IdUsuario) REFERENCES seguridad.Usuario(IdUsuario)
);
GO

/*========================
  CATÁLOGOS Y MAESTROS
========================*/
CREATE TABLE catalogos.Cliente (
    IdCliente           INT IDENTITY(1,1) PRIMARY KEY,
    Identificacion       NVARCHAR(50) NOT NULL,
    NombreORazonSocial            NVARCHAR(150) NOT NULL,
    NombreContacto          NVARCHAR(150) NULL,
    Telefono                NVARCHAR(30) NOT NULL,
    CorreoElectronico                NVARCHAR(150) NOT NULL,
    Direccion          NVARCHAR(250) NOT NULL,
    Activo             BIT NOT NULL CONSTRAINT PREDET_Cliente_Activo DEFAULT (1),
    FechaCreacion            DATETIME2(0) NOT NULL CONSTRAINT PREDET_Cliente_FechaCreacion DEFAULT (SYSDATETIME()),
    FechaActualizacion            DATETIME2(0) NOT NULL CONSTRAINT PREDET_Cliente_FechaActualizacion DEFAULT (SYSDATETIME()),
    CONSTRAINT UNICO_Cliente_Identificacion UNIQUE (Identificacion)
);
GO

CREATE TABLE catalogos.Prospecto (
    IdProspecto           INT IDENTITY(1,1) PRIMARY KEY,
    NombreProspecto         NVARCHAR(150) NOT NULL,
    Identificacion       NVARCHAR(50) NULL,
    Telefono                NVARCHAR(30) NULL,
    CorreoElectronico                NVARCHAR(150) NULL,
    Direccion          NVARCHAR(250) NULL,
    Activo             BIT NOT NULL CONSTRAINT PREDET_Prospecto_Activo DEFAULT (1),
    FechaCreacion            DATETIME2(0) NOT NULL CONSTRAINT PREDET_Prospecto_FechaCreacion DEFAULT (SYSDATETIME()),
    FechaActualizacion            DATETIME2(0) NOT NULL CONSTRAINT PREDET_Prospecto_FechaActualizacion DEFAULT (SYSDATETIME())
);
GO

CREATE TABLE catalogos.Marca (
    IdMarca              INT IDENTITY(1,1) PRIMARY KEY,
    NombreMarca            NVARCHAR(80) NOT NULL,
    Activo             BIT NOT NULL CONSTRAINT PREDET_Marca_Activo DEFAULT (1),
    CONSTRAINT UNICO_Marca_NombreMarca UNIQUE (NombreMarca)
);
GO

CREATE TABLE catalogos.EstadoEquipo (
    IdEstadoEquipo    INT IDENTITY(1,1) PRIMARY KEY,
    NombreEstado           NVARCHAR(60) NOT NULL,
    CONSTRAINT UNICO_EstadoEquipo_NombreEstado UNIQUE (NombreEstado)
);
GO

CREATE TABLE catalogos.ModeloEquipo (
    IdModeloEquipo     INT IDENTITY(1,1) PRIMARY KEY,
    IdMarca              INT NOT NULL,
    NombreModelo            NVARCHAR(100) NOT NULL,
    DescripcionModelo     NVARCHAR(250) NULL,
    Activo             BIT NOT NULL CONSTRAINT PREDET_ModeloEquipo_Activo DEFAULT (1),
    CONSTRAINT REFERENCIA_ModeloEquipo_Marca FOREIGN KEY (IdMarca) REFERENCES catalogos.Marca(IdMarca),
    CONSTRAINT UNICO_ModeloEquipo_Marca_Modelo UNIQUE (IdMarca, NombreModelo)
);
GO

CREATE TABLE catalogos.Equipo (
    IdEquipo          INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente           INT NOT NULL,
    IdModeloEquipo     INT NOT NULL,
    NumeroSerie         NVARCHAR(100) NULL,
    UbicacionFisica     NVARCHAR(200) NOT NULL,
    IdEstadoEquipo    INT NOT NULL,
    Activo             BIT NOT NULL CONSTRAINT PREDET_Equipo_Activo DEFAULT (1),
    FechaCreacion            DATETIME2(0) NOT NULL CONSTRAINT PREDET_Equipo_FechaCreacion DEFAULT (SYSDATETIME()),
    FechaActualizacion            DATETIME2(0) NOT NULL CONSTRAINT PREDET_Equipo_FechaActualizacion DEFAULT (SYSDATETIME()),
    CONSTRAINT REFERENCIA_Equipo_Cliente FOREIGN KEY (IdCliente) REFERENCES catalogos.Cliente(IdCliente),
    CONSTRAINT REFERENCIA_Equipo_ModeloEquipo FOREIGN KEY (IdModeloEquipo) REFERENCES catalogos.ModeloEquipo(IdModeloEquipo),
    CONSTRAINT REFERENCIA_Equipo_EstadoEquipo FOREIGN KEY (IdEstadoEquipo) REFERENCES catalogos.EstadoEquipo(IdEstadoEquipo)
);
GO
CREATE UNIQUE INDEX INDICE_UNICO_Equipo_NumeroSerie ON catalogos.Equipo(NumeroSerie) WHERE NumeroSerie IS NOT NULL;
GO

CREATE TABLE catalogos.UnidadMedida (
    IdUnidadMedida        INT IDENTITY(1,1) PRIMARY KEY,
    CodigoUnidad             NVARCHAR(20) NOT NULL,
    NombreUnidad             NVARCHAR(60) NOT NULL,
    CONSTRAINT UNICO_UnidadMedida_CodigoUnidad UNIQUE (CodigoUnidad),
    CONSTRAINT UNICO_UnidadMedida_NombreUnidad UNIQUE (NombreUnidad)
);
GO

CREATE TABLE catalogos.TipoArticulo (
    IdTipoArticulo        INT IDENTITY(1,1) PRIMARY KEY,
    NombreTipo             NVARCHAR(60) NOT NULL,
    CONSTRAINT UNICO_TipoArticulo_NombreTipo UNIQUE (NombreTipo)
);
GO

CREATE TABLE catalogos.Articulo (
    IdArticulo            INT IDENTITY(1,1) PRIMARY KEY,
    CodigoArticulo          NVARCHAR(50) NOT NULL,
    NombreArticulo          NVARCHAR(150) NOT NULL,
    DescripcionArticulo   NVARCHAR(250) NULL,
    IdTipoArticulo        INT NOT NULL,
    IdUnidadMedida        INT NOT NULL,
    CostoUnitario             DECIMAL(18,2) NOT NULL,
    ExistenciaMinima         INT NOT NULL CONSTRAINT PREDET_Articulo_ExistenciaMinima DEFAULT (0),
    Activo             BIT NOT NULL CONSTRAINT PREDET_Articulo_Activo DEFAULT (1),
    FechaCreacion            DATETIME2(0) NOT NULL CONSTRAINT PREDET_Articulo_FechaCreacion DEFAULT (SYSDATETIME()),
    FechaActualizacion            DATETIME2(0) NOT NULL CONSTRAINT PREDET_Articulo_FechaActualizacion DEFAULT (SYSDATETIME()),
    CONSTRAINT REFERENCIA_Articulo_TipoArticulo FOREIGN KEY (IdTipoArticulo) REFERENCES catalogos.TipoArticulo(IdTipoArticulo),
    CONSTRAINT REFERENCIA_Articulo_UnidadMedida FOREIGN KEY (IdUnidadMedida) REFERENCES catalogos.UnidadMedida(IdUnidadMedida),
    CONSTRAINT UNICO_Articulo_CodigoArticulo UNIQUE (CodigoArticulo),
    CONSTRAINT VALIDA_Articulo_CostoUnitario CHECK (CostoUnitario >= 0),
    CONSTRAINT VALIDA_Articulo_ExistenciaMinima CHECK (ExistenciaMinima >= 0)
);
GO

CREATE TABLE catalogos.CompatibilidadRepuesto (
    IdArticulo            INT NOT NULL,
    IdModeloEquipo     INT NOT NULL,
    PRIMARY KEY (IdArticulo, IdModeloEquipo),
    CONSTRAINT REFERENCIA_CompatibilidadRepuesto_Articulo FOREIGN KEY (IdArticulo) REFERENCES catalogos.Articulo(IdArticulo),
    CONSTRAINT REFERENCIA_CompatibilidadRepuesto_ModeloEquipo FOREIGN KEY (IdModeloEquipo) REFERENCES catalogos.ModeloEquipo(IdModeloEquipo)
);
GO

/*========================
  INVENTARIO
========================*/
CREATE TABLE inventario.TipoMovimiento (
    IdTipoMovimiento       INT IDENTITY(1,1) PRIMARY KEY,
    NombreTipo             NVARCHAR(30) NOT NULL,
    CONSTRAINT UNICO_TipoMovimiento_NombreTipo UNIQUE (NombreTipo)
);
GO

CREATE TABLE inventario.MotivoMovimiento (
    IdMotivoMovimiento     INT IDENTITY(1,1) PRIMARY KEY,
    IdTipoMovimiento       INT NOT NULL,
    NombreMotivo           NVARCHAR(80) NOT NULL,
    DescripcionMotivo    NVARCHAR(250) NULL,
    CONSTRAINT REFERENCIA_MotivoMovimiento_TipoMovimiento FOREIGN KEY (IdTipoMovimiento) REFERENCES inventario.TipoMovimiento(IdTipoMovimiento),
    CONSTRAINT UNICO_MotivoMovimiento_Tipo_Motivo UNIQUE (IdTipoMovimiento, NombreMotivo)
);
GO

CREATE TABLE inventario.MovimientoInventario (
    IdMovimientoInventario  BIGINT IDENTITY(1,1) PRIMARY KEY,
    IdArticulo            INT NOT NULL,
    IdMotivoMovimiento     INT NOT NULL,
    Cantidad             INT NOT NULL,
    FechaMovimiento         DATETIME2(0) NOT NULL CONSTRAINT PREDET_MovimientoInventario_FechaMovimiento DEFAULT (SYSDATETIME()),
    IdUsuario               INT NOT NULL,
    EntidadReferencia      NVARCHAR(60) NULL,
    IdReferencia          INT NULL,
    Observaciones                NVARCHAR(250) NULL,
    CONSTRAINT REFERENCIA_MovimientoInventario_Articulo FOREIGN KEY (IdArticulo) REFERENCES catalogos.Articulo(IdArticulo),
    CONSTRAINT REFERENCIA_MovimientoInventario_MotivoMovimiento FOREIGN KEY (IdMotivoMovimiento) REFERENCES inventario.MotivoMovimiento(IdMotivoMovimiento),
    CONSTRAINT REFERENCIA_MovimientoInventario_Usuario FOREIGN KEY (IdUsuario) REFERENCES seguridad.Usuario(IdUsuario),
    CONSTRAINT VALIDA_MovimientoInventario_Cantidad CHECK (Cantidad > 0)
);
GO

/*========================
  COMERCIAL
========================*/
CREATE TABLE comercial.EstadoCotizacion (
    IdEstadoCotizacion    INT IDENTITY(1,1) PRIMARY KEY,
    NombreEstado           NVARCHAR(40) NOT NULL,
    CONSTRAINT UNICO_EstadoCotizacion_NombreEstado UNIQUE (NombreEstado)
);
GO

CREATE TABLE comercial.Cotizacion (
    IdCotizacion          INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente           INT NULL,
    IdProspecto           INT NULL,
    FechaCotizacion            DATE NOT NULL CONSTRAINT PREDET_Cotizacion_FechaCotizacion DEFAULT (CAST(GETDATE() AS DATE)),
    FechaVencimiento       DATE NULL,
    IdEstadoCotizacion    INT NOT NULL,
    Observaciones                NVARCHAR(400) NULL,
    IdUsuarioCreador      INT NOT NULL,
    FechaCreacion            DATETIME2(0) NOT NULL CONSTRAINT PREDET_Cotizacion_FechaCreacion DEFAULT (SYSDATETIME()),
    CONSTRAINT REFERENCIA_Cotizacion_Cliente FOREIGN KEY (IdCliente) REFERENCES catalogos.Cliente(IdCliente),
    CONSTRAINT REFERENCIA_Cotizacion_Prospecto FOREIGN KEY (IdProspecto) REFERENCES catalogos.Prospecto(IdProspecto),
    CONSTRAINT REFERENCIA_Cotizacion_EstadoCotizacion FOREIGN KEY (IdEstadoCotizacion) REFERENCES comercial.EstadoCotizacion(IdEstadoCotizacion),
    CONSTRAINT REFERENCIA_Cotizacion_Usuario FOREIGN KEY (IdUsuarioCreador) REFERENCES seguridad.Usuario(IdUsuario),
    CONSTRAINT VALIDA_Cotizacion_Destinatario CHECK (
        (CASE WHEN IdCliente IS NULL THEN 0 ELSE 1 END +
         CASE WHEN IdProspecto IS NULL THEN 0 ELSE 1 END) = 1
    )
);
GO

CREATE TABLE comercial.DetalleCotizacion (
    IdDetalleCotizacion      INT IDENTITY(1,1) PRIMARY KEY,
    IdCotizacion          INT NOT NULL,
    NumeroLinea           SMALLINT NOT NULL,
    IdArticulo            INT NULL,
    DescripcionLinea      NVARCHAR(250) NOT NULL,
    Cantidad             DECIMAL(18,2) NOT NULL,
    PrecioUnitario            DECIMAL(18,2) NOT NULL,
    PorcentajeImpuesto              DECIMAL(5,2) NOT NULL CONSTRAINT PREDET_DetalleCotizacion_PorcentajeImpuesto DEFAULT (0),
    CONSTRAINT REFERENCIA_DetalleCotizacion_Cotizacion FOREIGN KEY (IdCotizacion) REFERENCES comercial.Cotizacion(IdCotizacion),
    CONSTRAINT REFERENCIA_DetalleCotizacion_Articulo FOREIGN KEY (IdArticulo) REFERENCES catalogos.Articulo(IdArticulo),
    CONSTRAINT UNICO_DetalleCotizacion_Cotizacion_Linea UNIQUE (IdCotizacion, NumeroLinea),
    CONSTRAINT VALIDA_DetalleCotizacion_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT VALIDA_DetalleCotizacion_PrecioUnitario CHECK (PrecioUnitario >= 0),
    CONSTRAINT VALIDA_DetalleCotizacion_PorcentajeImpuesto CHECK (PorcentajeImpuesto BETWEEN 0 AND 100)
);
GO

CREATE TABLE comercial.TipoOperacion (
    IdTipoOperacion      INT IDENTITY(1,1) PRIMARY KEY,
    NombreTipo             NVARCHAR(40) NOT NULL,
    CONSTRAINT UNICO_TipoOperacion_NombreTipo UNIQUE (NombreTipo)
);
GO

CREATE TABLE comercial.EstadoOperacion (
    IdEstadoOperacion    INT IDENTITY(1,1) PRIMARY KEY,
    NombreEstado           NVARCHAR(40) NOT NULL,
    CONSTRAINT UNICO_EstadoOperacion_NombreEstado UNIQUE (NombreEstado)
);
GO

CREATE TABLE comercial.OperacionComercial (
    IdOperacion          INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente           INT NOT NULL,
    IdTipoOperacion      INT NOT NULL,
    IdEstadoOperacion    INT NOT NULL,
    IdCotizacionOrigen    INT NULL,
    FechaOperacion        DATE NOT NULL CONSTRAINT PREDET_OperacionComercial_FechaOperacion DEFAULT (CAST(GETDATE() AS DATE)),
    Observaciones                NVARCHAR(400) NULL,
    IdUsuarioCreador      INT NOT NULL,
    FechaCreacion            DATETIME2(0) NOT NULL CONSTRAINT PREDET_OperacionComercial_FechaCreacion DEFAULT (SYSDATETIME()),
    CONSTRAINT REFERENCIA_OperacionComercial_Cliente FOREIGN KEY (IdCliente) REFERENCES catalogos.Cliente(IdCliente),
    CONSTRAINT REFERENCIA_OperacionComercial_TipoOperacion FOREIGN KEY (IdTipoOperacion) REFERENCES comercial.TipoOperacion(IdTipoOperacion),
    CONSTRAINT REFERENCIA_OperacionComercial_EstadoOperacion FOREIGN KEY (IdEstadoOperacion) REFERENCES comercial.EstadoOperacion(IdEstadoOperacion),
    CONSTRAINT REFERENCIA_OperacionComercial_CotizacionOrigen FOREIGN KEY (IdCotizacionOrigen) REFERENCES comercial.Cotizacion(IdCotizacion),
    CONSTRAINT REFERENCIA_OperacionComercial_Usuario FOREIGN KEY (IdUsuarioCreador) REFERENCES seguridad.Usuario(IdUsuario)
);
GO

CREATE TABLE comercial.DetalleOperacion (
    IdDetalleOperacion      INT IDENTITY(1,1) PRIMARY KEY,
    IdOperacion          INT NOT NULL,
    NumeroLinea           SMALLINT NOT NULL,
    IdArticulo            INT NULL,
    IdEquipo          INT NULL,
    DescripcionLinea      NVARCHAR(250) NOT NULL,
    Cantidad             DECIMAL(18,2) NOT NULL,
    PrecioUnitario            DECIMAL(18,2) NOT NULL,
    PorcentajeImpuesto              DECIMAL(5,2) NOT NULL CONSTRAINT PREDET_DetalleOperacion_PorcentajeImpuesto DEFAULT (0),
    CONSTRAINT REFERENCIA_DetalleOperacion_OperacionComercial FOREIGN KEY (IdOperacion) REFERENCES comercial.OperacionComercial(IdOperacion),
    CONSTRAINT REFERENCIA_DetalleOperacion_Articulo FOREIGN KEY (IdArticulo) REFERENCES catalogos.Articulo(IdArticulo),
    CONSTRAINT REFERENCIA_DetalleOperacion_Equipo FOREIGN KEY (IdEquipo) REFERENCES catalogos.Equipo(IdEquipo),
    CONSTRAINT UNICO_DetalleOperacion_Operacion_Linea UNIQUE (IdOperacion, NumeroLinea),
    CONSTRAINT VALIDA_DetalleOperacion_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT VALIDA_DetalleOperacion_PrecioUnitario CHECK (PrecioUnitario >= 0),
    CONSTRAINT VALIDA_DetalleOperacion_PorcentajeImpuesto CHECK (PorcentajeImpuesto BETWEEN 0 AND 100),
    CONSTRAINT VALIDA_DetalleOperacion_Destinatario CHECK (
        CASE WHEN IdArticulo IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN IdEquipo IS NOT NULL THEN 1 ELSE 0 END <= 1
    )
);
GO

CREATE TABLE comercial.Garantia (
    IdGarantia           INT IDENTITY(1,1) PRIMARY KEY,
    IdDetalleOperacion      INT NOT NULL,
    FechaInicio            DATE NOT NULL,
    MesesCobertura       TINYINT NOT NULL CONSTRAINT PREDET_Garantia_MesesCobertura DEFAULT (4),
    FechaFin AS DATEADD(MONTH, MesesCobertura, FechaInicio),
    DescripcionCobertura  NVARCHAR(250) NOT NULL,
    Activo             BIT NOT NULL CONSTRAINT PREDET_Garantia_Activo DEFAULT (1),
    CONSTRAINT REFERENCIA_Garantia_DetalleOperacion FOREIGN KEY (IdDetalleOperacion) REFERENCES comercial.DetalleOperacion(IdDetalleOperacion),
    CONSTRAINT UNICO_Garantia_DetalleOperacion UNIQUE (IdDetalleOperacion),
    CONSTRAINT VALIDA_Garantia_MesesCobertura CHECK (MesesCobertura > 0)
);
GO

CREATE TABLE comercial.ContratoAlquiler (
    IdContratoAlquiler     INT IDENTITY(1,1) PRIMARY KEY,
    IdOperacion          INT NOT NULL,
    FechaInicio            DATE NOT NULL,
    FechaFin              DATE NULL,
    ObservacionesContrato        NVARCHAR(400) NULL,
    CONSTRAINT REFERENCIA_ContratoAlquiler_OperacionComercial FOREIGN KEY (IdOperacion) REFERENCES comercial.OperacionComercial(IdOperacion),
    CONSTRAINT UNICO_ContratoAlquiler_Operacion UNIQUE (IdOperacion),
    CONSTRAINT VALIDA_ContratoAlquiler_RangoFechas CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio)
);
GO

CREATE TABLE comercial.EquipoContratoAlquiler (
    IdEquipoContratoAlquiler INT IDENTITY(1,1) PRIMARY KEY,
    IdContratoAlquiler      INT NOT NULL,
    IdEquipo           INT NOT NULL,
    CuotaMensual            DECIMAL(18,2) NULL,
    Activo              BIT NOT NULL CONSTRAINT PREDET_EquipoContratoAlquiler_Activo DEFAULT (1),
    CONSTRAINT REFERENCIA_EquipoContratoAlquiler_ContratoAlquiler FOREIGN KEY (IdContratoAlquiler) REFERENCES comercial.ContratoAlquiler(IdContratoAlquiler),
    CONSTRAINT REFERENCIA_EquipoContratoAlquiler_Equipo FOREIGN KEY (IdEquipo) REFERENCES catalogos.Equipo(IdEquipo),
    CONSTRAINT UNICO_EquipoContratoAlquiler_Contrato_Equipo UNIQUE (IdContratoAlquiler, IdEquipo),
    CONSTRAINT VALIDA_EquipoContratoAlquiler_CuotaMensual CHECK (CuotaMensual IS NULL OR CuotaMensual >= 0)
);
GO

/*========================
  SERVICIO TÉCNICO
========================*/
CREATE TABLE servicio_tecnico.EstadoSolicitudServicio (
    IdEstadoSolicitudServicio INT IDENTITY(1,1) PRIMARY KEY,
    NombreEstado           NVARCHAR(40) NOT NULL,
    CONSTRAINT UNICO_EstadoSolicitudServicio_NombreEstado UNIQUE (NombreEstado)
);
GO

CREATE TABLE servicio_tecnico.SolicitudServicio (
    IdSolicitudServicio     INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente           INT NOT NULL,
    IdEquipo          INT NOT NULL,
    FechaSolicitud          DATE NOT NULL CONSTRAINT PREDET_SolicitudServicio_FechaSolicitud DEFAULT (CAST(GETDATE() AS DATE)),
    DescripcionProblema   NVARCHAR(400) NULL,
    Diagnostico            NVARCHAR(400) NULL,
    IdUsuarioTecnicoAsignado INT NULL,
    FechaAtencionProgramada DATE NULL,
    IdEstadoSolicitudServicio INT NOT NULL,
    IdUsuarioCreador      INT NOT NULL,
    FechaCreacion            DATETIME2(0) NOT NULL CONSTRAINT PREDET_SolicitudServicio_FechaCreacion DEFAULT (SYSDATETIME()),
    CONSTRAINT REFERENCIA_SolicitudServicio_Cliente FOREIGN KEY (IdCliente) REFERENCES catalogos.Cliente(IdCliente),
    CONSTRAINT REFERENCIA_SolicitudServicio_Equipo FOREIGN KEY (IdEquipo) REFERENCES catalogos.Equipo(IdEquipo),
    CONSTRAINT REFERENCIA_SolicitudServicio_TecnicoAsignado FOREIGN KEY (IdUsuarioTecnicoAsignado) REFERENCES seguridad.Usuario(IdUsuario),
    CONSTRAINT REFERENCIA_SolicitudServicio_EstadoSolicitudServicio FOREIGN KEY (IdEstadoSolicitudServicio) REFERENCES servicio_tecnico.EstadoSolicitudServicio(IdEstadoSolicitudServicio),
    CONSTRAINT REFERENCIA_SolicitudServicio_UsuarioCreador FOREIGN KEY (IdUsuarioCreador) REFERENCES seguridad.Usuario(IdUsuario)
);
GO

CREATE TABLE servicio_tecnico.EstadoOrdenTrabajo (
    IdEstadoOrdenTrabajo    INT IDENTITY(1,1) PRIMARY KEY,
    NombreEstado           NVARCHAR(40) NOT NULL,
    CONSTRAINT UNICO_EstadoOrdenTrabajo_NombreEstado UNIQUE (NombreEstado)
);
GO

CREATE TABLE servicio_tecnico.OrdenTrabajo (
    IdOrdenTrabajo          INT IDENTITY(1,1) PRIMARY KEY,
    IdSolicitudServicio     INT NOT NULL,
    IdEstadoOrdenTrabajo    INT NOT NULL,
    IdUsuarioResponsable    INT NULL,
    FechaApertura             DATETIME2(0) NOT NULL CONSTRAINT PREDET_OrdenTrabajo_FechaApertura DEFAULT (SYSDATETIME()),
    FechaAtencion           DATETIME2(0) NULL,
    FechaCierre             DATETIME2(0) NULL,
    FechaAplicacionInventario   DATETIME2(0) NULL,
    Observaciones         NVARCHAR(400) NULL,
    CONSTRAINT REFERENCIA_OrdenTrabajo_SolicitudServicio FOREIGN KEY (IdSolicitudServicio) REFERENCES servicio_tecnico.SolicitudServicio(IdSolicitudServicio),
    CONSTRAINT REFERENCIA_OrdenTrabajo_EstadoOrdenTrabajo FOREIGN KEY (IdEstadoOrdenTrabajo) REFERENCES servicio_tecnico.EstadoOrdenTrabajo(IdEstadoOrdenTrabajo),
    CONSTRAINT REFERENCIA_OrdenTrabajo_UsuarioResponsable FOREIGN KEY (IdUsuarioResponsable) REFERENCES seguridad.Usuario(IdUsuario)
);
GO

CREATE TABLE servicio_tecnico.AvanceOrdenTrabajo (
    IdAvanceOrdenTrabajo  INT IDENTITY(1,1) PRIMARY KEY,
    IdOrdenTrabajo          INT NOT NULL,
    FechaAvance           DATETIME2(0) NOT NULL CONSTRAINT PREDET_AvanceOrdenTrabajo_FechaAvance DEFAULT (SYSDATETIME()),
    Observaciones                NVARCHAR(400) NOT NULL,
    MinutosTrabajados        INT NULL,
    IdUsuarioRegistro   INT NOT NULL,
    CONSTRAINT REFERENCIA_AvanceOrdenTrabajo_OrdenTrabajo FOREIGN KEY (IdOrdenTrabajo) REFERENCES servicio_tecnico.OrdenTrabajo(IdOrdenTrabajo),
    CONSTRAINT REFERENCIA_AvanceOrdenTrabajo_Usuario FOREIGN KEY (IdUsuarioRegistro) REFERENCES seguridad.Usuario(IdUsuario),
    CONSTRAINT VALIDA_AvanceOrdenTrabajo_MinutosTrabajados CHECK (MinutosTrabajados IS NULL OR MinutosTrabajados >= 0)
);
GO

CREATE TABLE servicio_tecnico.RepuestoOrdenTrabajo (
    IdRepuestoOrdenTrabajo      INT IDENTITY(1,1) PRIMARY KEY,
    IdOrdenTrabajo          INT NOT NULL,
    IdArticulo            INT NOT NULL,
    Cantidad             INT NOT NULL,
    CostoUnitarioAlUso        DECIMAL(18,2) NOT NULL,
    Observaciones                NVARCHAR(250) NULL,
    CONSTRAINT REFERENCIA_RepuestoOrdenTrabajo_OrdenTrabajo FOREIGN KEY (IdOrdenTrabajo) REFERENCES servicio_tecnico.OrdenTrabajo(IdOrdenTrabajo),
    CONSTRAINT REFERENCIA_RepuestoOrdenTrabajo_Articulo FOREIGN KEY (IdArticulo) REFERENCES catalogos.Articulo(IdArticulo),
    CONSTRAINT UNICO_RepuestoOrdenTrabajo_OrdenTrabajo_Articulo UNIQUE (IdOrdenTrabajo, IdArticulo),
    CONSTRAINT VALIDA_RepuestoOrdenTrabajo_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT VALIDA_RepuestoOrdenTrabajo_CostoUnitarioAlUso CHECK (CostoUnitarioAlUso >= 0)
);
GO

/*========================
  OPERACIÓN / LECTURAS
========================*/
CREATE TABLE operaciones.LecturaMensual (
    IdLecturaMensual     INT IDENTITY(1,1) PRIMARY KEY,
    IdEquipoContratoAlquiler INT NOT NULL,
    AnioLectura          SMALLINT NOT NULL,
    MesLectura         TINYINT NOT NULL,
    ValorLectura         BIGINT NOT NULL,
    FechaRegistro           DATETIME2(0) NOT NULL CONSTRAINT PREDET_LecturaMensual_FechaRegistro DEFAULT (SYSDATETIME()),
    IdUsuarioLectura     INT NOT NULL,
    Observaciones                NVARCHAR(250) NULL,
    CONSTRAINT REFERENCIA_LecturaMensual_EquipoContratoAlquiler FOREIGN KEY (IdEquipoContratoAlquiler) REFERENCES comercial.EquipoContratoAlquiler(IdEquipoContratoAlquiler),
    CONSTRAINT REFERENCIA_LecturaMensual_Usuario FOREIGN KEY (IdUsuarioLectura) REFERENCES seguridad.Usuario(IdUsuario),
    CONSTRAINT UNICO_LecturaMensual_Periodo UNIQUE (IdEquipoContratoAlquiler, AnioLectura, MesLectura),
    CONSTRAINT VALIDA_LecturaMensual_AnioLectura CHECK (AnioLectura BETWEEN 2000 AND 2100),
    CONSTRAINT VALIDA_LecturaMensual_MesLectura CHECK (MesLectura BETWEEN 1 AND 12),
    CONSTRAINT VALIDA_LecturaMensual_ValorLectura CHECK (ValorLectura >= 0)
);
GO

/*========================
  ÍNDICES ADICIONALES
========================*/
CREATE INDEX INDICE_Equipo_IdCliente ON catalogos.Equipo(IdCliente);
CREATE INDEX INDICE_MovimientoInventario_IdArticulo_FechaMovimiento ON inventario.MovimientoInventario(IdArticulo, FechaMovimiento);
CREATE INDEX INDICE_Cotizacion_IdCliente ON comercial.Cotizacion(IdCliente);
CREATE INDEX INDICE_OperacionComercial_IdCliente ON comercial.OperacionComercial(IdCliente);
CREATE INDEX INDICE_SolicitudServicio_IdEquipo ON servicio_tecnico.SolicitudServicio(IdEquipo);
CREATE INDEX INDICE_OrdenTrabajo_IdSolicitudServicio ON servicio_tecnico.OrdenTrabajo(IdSolicitudServicio);
CREATE INDEX INDICE_LecturaMensual_IdEquipoContratoAlquiler ON operaciones.LecturaMensual(IdEquipoContratoAlquiler);
GO

/*========================
  DATOS SEMILLA
========================*/
INSERT INTO seguridad.Rol (NombreRol, DescripcionRol) VALUES
(N'Administrador', N'Administra usuarios, roles y permisos.'),
(N'Servicio al Cliente', N'Gestiona clientes, cotizaciones y operaciones comerciales.'),
(N'Analista', N'Consulta reportes, historiales y bitácoras.'),
(N'Gestor/Operativo', N'Gestiona equipos, inventario y órdenes técnicas.');
GO

INSERT INTO seguridad.Permiso (CodigoPermiso, NombrePermiso, DescripcionPermiso) VALUES
(N'CLI_CRUD', N'Administrar clientes', N'Crear, consultar, editar e inactivar clientes.'),
(N'EQP_CRUD', N'Administrar equipos', N'Registrar, consultar y actualizar equipos.'),
(N'ART_CRUD', N'Administrar artículos', N'Crear y mantener productos y repuestos.'),
(N'INV_MOV', N'Registrar inventario', N'Registrar entradas y salidas de inventario.'),
(N'COT_CRUD', N'Administrar cotizaciones', N'Crear y actualizar cotizaciones.'),
(N'OPE_CRUD', N'Administrar operaciones', N'Registrar ventas y alquileres.'),
(N'SVC_CRUD', N'Administrar servicio técnico', N'Registrar solicitudes y órdenes de trabajo.'),
(N'REP_VIEW', N'Consultar reportes', N'Consultar reportes, dashboard y bitácora.');
GO

INSERT INTO catalogos.Marca (NombreMarca) VALUES (N'Canon');
GO

INSERT INTO catalogos.EstadoEquipo (NombreEstado) VALUES
(N'Activo'), (N'En mantenimiento'), (N'Alquilado'), (N'Fuera de servicio'), (N'Inactivo');
GO

INSERT INTO catalogos.UnidadMedida (CodigoUnidad, NombreUnidad) VALUES
(N'UND', N'Unidad'),
(N'KIT', N'Kit'),
(N'BOT', N'Botella'),
(N'CAJ', N'Caja');
GO

INSERT INTO catalogos.TipoArticulo (NombreTipo) VALUES
(N'Producto'),
(N'Consumible'),
(N'Repuesto'),
(N'Servicio');
GO

INSERT INTO inventario.TipoMovimiento (NombreTipo) VALUES
(N'ENTRADA'),
(N'SALIDA');
GO

INSERT INTO inventario.MotivoMovimiento (IdTipoMovimiento, NombreMotivo, DescripcionMotivo)
SELECT mt.IdTipoMovimiento, v.NombreMotivo, v.DescripcionMotivo
FROM inventario.TipoMovimiento mt
JOIN (VALUES
    (N'ENTRADA', N'Compra', N'Ingreso por compra a proveedor'),
    (N'ENTRADA', N'Devolución de cliente', N'Retorno de artículos al inventario'),
    (N'ENTRADA', N'Ajuste positivo', N'Corrección por diferencia de inventario'),
    (N'SALIDA', N'Venta', N'Salida por venta'),
    (N'SALIDA', N'Consumo por orden de trabajo', N'Consumo de repuestos en servicio técnico'),
    (N'SALIDA', N'Ajuste negativo', N'Corrección por diferencia de inventario')
) v(NombreTipoMovimiento, NombreMotivo, DescripcionMotivo)
    ON mt.NombreTipo = v.NombreTipoMovimiento;
GO

INSERT INTO comercial.EstadoCotizacion (NombreEstado) VALUES
(N'Borrador'), (N'Pendiente'), (N'Aprobada'), (N'Rechazada');
GO

INSERT INTO comercial.TipoOperacion (NombreTipo) VALUES
(N'Venta'), (N'Alquiler');
GO

INSERT INTO comercial.EstadoOperacion (NombreEstado) VALUES
(N'Registrada'), (N'Completada'), (N'Anulada');
GO

INSERT INTO servicio_tecnico.EstadoSolicitudServicio (NombreEstado) VALUES
(N'Registrada'), (N'Asignada'), (N'En atención'), (N'Cerrada'), (N'Cancelada');
GO

INSERT INTO servicio_tecnico.EstadoOrdenTrabajo (NombreEstado) VALUES
(N'Abierta'), (N'En proceso'), (N'Cerrada'), (N'Cancelada');
GO

/*========================
  VISTAS
========================*/
CREATE VIEW inventario.Vista_ExistenciasArticulos
AS
SELECT
    a.IdArticulo,
    a.CodigoArticulo,
    a.NombreArticulo,
    a.ExistenciaMinima,
    CAST(COALESCE(SUM(CASE mt.NombreTipo
        WHEN N'ENTRADA' THEN im.Cantidad
        WHEN N'SALIDA' THEN -im.Cantidad
        ELSE 0 END), 0) AS INT) AS ExistenciaActual,
    CASE WHEN COALESCE(SUM(CASE mt.NombreTipo
        WHEN N'ENTRADA' THEN im.Cantidad
        WHEN N'SALIDA' THEN -im.Cantidad
        ELSE 0 END), 0) < a.ExistenciaMinima THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS ExistenciaBaja
FROM catalogos.Articulo a
LEFT JOIN inventario.MovimientoInventario im ON im.IdArticulo = a.IdArticulo
LEFT JOIN inventario.MotivoMovimiento mm ON mm.IdMotivoMovimiento = im.IdMotivoMovimiento
LEFT JOIN inventario.TipoMovimiento mt ON mt.IdTipoMovimiento = mm.IdTipoMovimiento
GROUP BY a.IdArticulo, a.CodigoArticulo, a.NombreArticulo, a.ExistenciaMinima;
GO

CREATE VIEW comercial.Vista_TotalesCotizaciones
AS
SELECT
    q.IdCotizacion,
    q.FechaCotizacion,
    qs.NombreEstado AS EstadoCotizacion,
    COALESCE(c.NombreORazonSocial, p.NombreProspecto) AS NombreDestinatario,
    SUM(ql.Cantidad * ql.PrecioUnitario) AS Subtotal,
    SUM((ql.Cantidad * ql.PrecioUnitario) * (ql.PorcentajeImpuesto / 100.0)) AS MontoImpuesto,
    SUM((ql.Cantidad * ql.PrecioUnitario) * (1 + ql.PorcentajeImpuesto / 100.0)) AS MontoTotal
FROM comercial.Cotizacion q
JOIN comercial.EstadoCotizacion qs ON qs.IdEstadoCotizacion = q.IdEstadoCotizacion
LEFT JOIN catalogos.Cliente c ON c.IdCliente = q.IdCliente
LEFT JOIN catalogos.Prospecto p ON p.IdProspecto = q.IdProspecto
LEFT JOIN comercial.DetalleCotizacion ql ON ql.IdCotizacion = q.IdCotizacion
GROUP BY q.IdCotizacion, q.FechaCotizacion, qs.NombreEstado, COALESCE(c.NombreORazonSocial, p.NombreProspecto);
GO

CREATE VIEW comercial.Vista_TotalesOperaciones
AS
SELECT
    o.IdOperacion,
    o.FechaOperacion,
    ot.NombreTipo AS TipoOperacion,
    os.NombreEstado AS EstadoOperacion,
    c.NombreORazonSocial AS NombreCliente,
    SUM(ol.Cantidad * ol.PrecioUnitario) AS Subtotal,
    SUM((ol.Cantidad * ol.PrecioUnitario) * (ol.PorcentajeImpuesto / 100.0)) AS MontoImpuesto,
    SUM((ol.Cantidad * ol.PrecioUnitario) * (1 + ol.PorcentajeImpuesto / 100.0)) AS MontoTotal
FROM comercial.OperacionComercial o
JOIN comercial.TipoOperacion ot ON ot.IdTipoOperacion = o.IdTipoOperacion
JOIN comercial.EstadoOperacion os ON os.IdEstadoOperacion = o.IdEstadoOperacion
JOIN catalogos.Cliente c ON c.IdCliente = o.IdCliente
LEFT JOIN comercial.DetalleOperacion ol ON ol.IdOperacion = o.IdOperacion
GROUP BY o.IdOperacion, o.FechaOperacion, ot.NombreTipo, os.NombreEstado, c.NombreORazonSocial;
GO

CREATE VIEW catalogos.Vista_HistorialTecnicoEquipos
AS
SELECT
    e.IdEquipo,
    e.NumeroSerie,
    c.NombreORazonSocial AS NombreCliente,
    b.NombreMarca,
    em.NombreModelo,
    sr.IdSolicitudServicio,
    srs.NombreEstado AS EstadoServicio,
    wo.IdOrdenTrabajo,
    wos.NombreEstado AS EstadoOrdenTrabajo,
    wo.FechaApertura,
    wo.FechaCierre
FROM catalogos.Equipo e
JOIN catalogos.Cliente c ON c.IdCliente = e.IdCliente
JOIN catalogos.ModeloEquipo em ON em.IdModeloEquipo = e.IdModeloEquipo
JOIN catalogos.Marca b ON b.IdMarca = em.IdMarca
LEFT JOIN servicio_tecnico.SolicitudServicio sr ON sr.IdEquipo = e.IdEquipo
LEFT JOIN servicio_tecnico.EstadoSolicitudServicio srs ON srs.IdEstadoSolicitudServicio = sr.IdEstadoSolicitudServicio
LEFT JOIN servicio_tecnico.OrdenTrabajo wo ON wo.IdSolicitudServicio = sr.IdSolicitudServicio
LEFT JOIN servicio_tecnico.EstadoOrdenTrabajo wos ON wos.IdEstadoOrdenTrabajo = wo.IdEstadoOrdenTrabajo;
GO




USE [SGC_UniversoTecnologico];
GO

/* Registro de inventario. Todas las entradas y salidas desde la API usan este proceso.
   Las salidas se serializan por artículo para impedir saldos negativos concurrentes. */
CREATE PROCEDURE inventario.pa_RegistrarMovimientoInventario
    @IdArticulo INT,
    @IdMotivoMovimiento INT,
    @Cantidad INT,
    @IdUsuario INT,
    @EntidadReferencia NVARCHAR(60) = NULL,
    @IdReferencia INT = NULL,
    @Observaciones NVARCHAR(250) = NULL,
    @DevolverRegistro BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @NombreTipo NVARCHAR(30), @Saldo BIGINT, @IdNuevo BIGINT, @CodigoBloqueo INT, @Recurso NVARCHAR(255);
    BEGIN TRY
        BEGIN TRANSACTION;
        SET @Recurso=CONCAT(N'SGC-Inventario-',@IdArticulo);
        EXEC @CodigoBloqueo = sys.sp_getapplock
            @Resource = @Recurso,
            @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 15000;
        IF @CodigoBloqueo < 0 THROW 51001, N'No se pudo bloquear el inventario del artículo.', 1;
        IF @Cantidad IS NULL OR @Cantidad <= 0 THROW 51002, N'La cantidad debe ser positiva.', 1;
        IF NOT EXISTS(SELECT 1 FROM catalogos.Articulo WHERE IdArticulo = @IdArticulo AND Activo = 1)
            THROW 51003, N'El artículo no existe o está inactivo.', 1;
        IF EXISTS(SELECT 1 FROM catalogos.Articulo a JOIN catalogos.TipoArticulo t ON t.IdTipoArticulo=a.IdTipoArticulo
                  WHERE a.IdArticulo=@IdArticulo AND t.NombreTipo=N'Servicio')
            THROW 51004, N'Los servicios no tienen existencias físicas.', 1;
        IF NOT EXISTS(SELECT 1 FROM seguridad.Usuario WHERE IdUsuario=@IdUsuario AND Activo=1)
            THROW 51005, N'El usuario responsable no existe o está inactivo.', 1;
        SELECT @NombreTipo = tm.NombreTipo
          FROM inventario.MotivoMovimiento mm
          JOIN inventario.TipoMovimiento tm ON tm.IdTipoMovimiento=mm.IdTipoMovimiento
          WHERE mm.IdMotivoMovimiento=@IdMotivoMovimiento;
        IF @NombreTipo IS NULL THROW 51006, N'Motivo de movimiento inválido.', 1;
        IF @NombreTipo=N'SALIDA'
        BEGIN
            SELECT @Saldo=ExistenciaActual FROM inventario.Vista_ExistenciasArticulos WHERE IdArticulo=@IdArticulo;
            IF ISNULL(@Saldo,0)<@Cantidad THROW 51007, N'Existencias insuficientes.', 1;
        END;
        INSERT INTO inventario.MovimientoInventario
          (IdArticulo,IdMotivoMovimiento,Cantidad,IdUsuario,EntidadReferencia,IdReferencia,Observaciones)
        VALUES (@IdArticulo,@IdMotivoMovimiento,@Cantidad,@IdUsuario,@EntidadReferencia,@IdReferencia,@Observaciones);
        SET @IdNuevo=CONVERT(BIGINT,SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        IF @DevolverRegistro=1
            SELECT * FROM inventario.MovimientoInventario WHERE IdMovimientoInventario=@IdNuevo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* Lecturas mensuales: validación en ambos sentidos del contador, no duplicados.
   El contrato debe estar activo y el período pertenecer a su vigencia. */
CREATE PROCEDURE operaciones.pa_RegistrarLecturaMensual
    @IdEquipoContratoAlquiler INT,
    @AnioLectura SMALLINT,
    @MesLectura TINYINT,
    @ValorLectura BIGINT,
    @IdUsuarioLectura INT,
    @Observaciones NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Anterior BIGINT,@Posterior BIGINT,@NuevoID INT,@Bloqueo INT,@Inicio DATE,@Fin DATE,@Periodo DATE,@Recurso NVARCHAR(255);
    IF @AnioLectura NOT BETWEEN 2000 AND 2100 OR @MesLectura NOT BETWEEN 1 AND 12
        THROW 51101, N'Período de lectura inválido.', 1;
    IF @ValorLectura < 0 THROW 51102, N'La lectura no puede ser negativa.', 1;
    SET @Periodo=DATEFROMPARTS(@AnioLectura,@MesLectura,1);
    BEGIN TRY
        BEGIN TRANSACTION;
        SET @Recurso=CONCAT(N'SGC-Lecturas-',@IdEquipoContratoAlquiler);
        EXEC @Bloqueo=sys.sp_getapplock @Resource=@Recurso,
             @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
        IF @Bloqueo<0 THROW 51103, N'No se pudo bloquear la secuencia de lecturas.', 1;
        SELECT @Inicio=c.FechaInicio,@Fin=c.FechaFin
        FROM comercial.EquipoContratoAlquiler ec
        JOIN comercial.ContratoAlquiler c ON c.IdContratoAlquiler=ec.IdContratoAlquiler
        JOIN comercial.OperacionComercial op ON op.IdOperacion=c.IdOperacion
        JOIN comercial.TipoOperacion tp ON tp.IdTipoOperacion=op.IdTipoOperacion
        JOIN comercial.EstadoOperacion eo ON eo.IdEstadoOperacion=op.IdEstadoOperacion
        WHERE ec.IdEquipoContratoAlquiler=@IdEquipoContratoAlquiler AND ec.Activo=1
          AND tp.NombreTipo=N'Alquiler' AND eo.NombreEstado<>N'Anulada';
        IF @Inicio IS NULL THROW 51104, N'No hay contrato de alquiler activo para el equipo.', 1;
        IF EOMONTH(@Periodo)<@Inicio OR (@Fin IS NOT NULL AND @Periodo>@Fin)
            THROW 51105, N'El mes de lectura está fuera de la vigencia del contrato.', 1;
        IF EXISTS(SELECT 1 FROM operaciones.LecturaMensual WHERE IdEquipoContratoAlquiler=@IdEquipoContratoAlquiler
                  AND AnioLectura=@AnioLectura AND MesLectura=@MesLectura)
            THROW 51106, N'Ya existe una lectura para ese período.', 1;
        SELECT TOP 1 @Anterior=ValorLectura FROM operaciones.LecturaMensual
        WHERE IdEquipoContratoAlquiler=@IdEquipoContratoAlquiler AND
             (AnioLectura<@AnioLectura OR (AnioLectura=@AnioLectura AND MesLectura<@MesLectura))
        ORDER BY AnioLectura DESC,MesLectura DESC;
        SELECT TOP 1 @Posterior=ValorLectura FROM operaciones.LecturaMensual
        WHERE IdEquipoContratoAlquiler=@IdEquipoContratoAlquiler AND
             (AnioLectura>@AnioLectura OR (AnioLectura=@AnioLectura AND MesLectura>@MesLectura))
        ORDER BY AnioLectura,MesLectura;
        IF @Anterior IS NOT NULL AND @ValorLectura<@Anterior THROW 51107, N'Lectura inferior a la del mes anterior.', 1;
        IF @Posterior IS NOT NULL AND @ValorLectura>@Posterior THROW 51108, N'Lectura superior a la de un mes posterior.', 1;
        INSERT INTO operaciones.LecturaMensual
        (IdEquipoContratoAlquiler,AnioLectura,MesLectura,ValorLectura,IdUsuarioLectura,Observaciones)
        VALUES(@IdEquipoContratoAlquiler,@AnioLectura,@MesLectura,@ValorLectura,@IdUsuarioLectura,@Observaciones);
        SET @NuevoID=CONVERT(INT,SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT * FROM operaciones.LecturaMensual WHERE IdLecturaMensual=@NuevoID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* Corrección controlada: no se permite cambiar el contrato/mes ni romper lecturas vecinas. */
CREATE PROCEDURE operaciones.pa_CorregirLecturaMensual
    @IdLecturaMensual INT,
    @ValorLectura BIGINT,
    @Observaciones NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Contrato INT, @Anio SMALLINT, @Mes TINYINT, @Anterior BIGINT, @Posterior BIGINT, @Bloqueo INT, @Recurso NVARCHAR(255);
    IF @ValorLectura<0 THROW 51109,N'La lectura no puede ser negativa.',1;
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT @Contrato=IdEquipoContratoAlquiler,@Anio=AnioLectura,@Mes=MesLectura
          FROM operaciones.LecturaMensual WHERE IdLecturaMensual=@IdLecturaMensual;
        IF @Contrato IS NULL THROW 51110,N'No existe la lectura solicitada.',1;
        SET @Recurso=CONCAT(N'SGC-Lecturas-',@Contrato);
        EXEC @Bloqueo=sys.sp_getapplock @Resource=@Recurso,
             @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
        IF @Bloqueo<0 THROW 51111,N'No se pudo bloquear la lectura.',1;
        SELECT TOP 1 @Anterior=ValorLectura FROM operaciones.LecturaMensual
        WHERE IdEquipoContratoAlquiler=@Contrato AND
          (AnioLectura<@Anio OR (AnioLectura=@Anio AND MesLectura<@Mes))
        ORDER BY AnioLectura DESC,MesLectura DESC;
        SELECT TOP 1 @Posterior=ValorLectura FROM operaciones.LecturaMensual
        WHERE IdEquipoContratoAlquiler=@Contrato AND
          (AnioLectura>@Anio OR (AnioLectura=@Anio AND MesLectura>@Mes))
        ORDER BY AnioLectura,MesLectura;
        IF @Anterior IS NOT NULL AND @ValorLectura<@Anterior THROW 51112,N'El valor es menor que el anterior.',1;
        IF @Posterior IS NOT NULL AND @ValorLectura>@Posterior THROW 51113,N'El valor supera al siguiente.',1;
        UPDATE operaciones.LecturaMensual SET ValorLectura=@ValorLectura,Observaciones=@Observaciones
        WHERE IdLecturaMensual=@IdLecturaMensual;
        COMMIT TRANSACTION;
        SELECT * FROM operaciones.LecturaMensual WHERE IdLecturaMensual=@IdLecturaMensual;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* El borrado de lectura solo está permitido para el último período y se audita. */
CREATE PROCEDURE operaciones.pa_EliminarUltimaLecturaMensual
    @IdLecturaMensual INT,
    @IdUsuarioResponsable INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Contrato INT,@Anio SMALLINT,@Mes TINYINT,@Bloqueo INT,@Recurso NVARCHAR(255);
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT @Contrato=IdEquipoContratoAlquiler,@Anio=AnioLectura,@Mes=MesLectura
        FROM operaciones.LecturaMensual WHERE IdLecturaMensual=@IdLecturaMensual;
        IF @Contrato IS NULL THROW 51114,N'No existe la lectura.',1;
        SET @Recurso=CONCAT(N'SGC-Lecturas-',@Contrato);
        EXEC @Bloqueo=sys.sp_getapplock @Resource=@Recurso,
             @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
        IF @Bloqueo<0 THROW 51115,N'No se pudo bloquear la secuencia.',1;
        IF EXISTS(SELECT 1 FROM operaciones.LecturaMensual WHERE IdEquipoContratoAlquiler=@Contrato AND
                   (AnioLectura>@Anio OR (AnioLectura=@Anio AND MesLectura>@Mes)))
            THROW 51116,N'Solo se puede eliminar la última lectura del equipo.',1;
        DELETE FROM operaciones.LecturaMensual WHERE IdLecturaMensual=@IdLecturaMensual;
        INSERT INTO seguridad.BitacoraEvento(IdUsuario,NombreEntidad,ClaveRegistro,TipoAccion,Comentario)
        VALUES(@IdUsuarioResponsable,N'operaciones.LecturaMensual',CONVERT(NVARCHAR(128),@IdLecturaMensual),
               N'ELIMINAR',N'Se eliminó la última lectura del contrato para corregir su captura.');
        COMMIT TRANSACTION;
        SELECT CAST(1 AS BIT) AS Eliminado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* Cierre de orden: una sola aplicación de piezas, con bloqueo por orden y por artículo.
   Las llamadas anidadas a inventario participan de la misma transacción. */
CREATE PROCEDURE servicio_tecnico.pa_CerrarOrdenTrabajo
    @IdOrdenTrabajo INT,
    @IdUsuarioCierre INT,
    @ObservacionesCierre NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @EstadoCerrada INT,@MotivoConsumo INT,@EstadoActual NVARCHAR(40),@FechaAplicacion DATETIME2(0),
            @Bloqueo INT,@IdArticulo INT,@Cantidad INT,@Recurso NVARCHAR(255);
    BEGIN TRY
        BEGIN TRANSACTION;
        SET @Recurso=CONCAT(N'SGC-Orden-',@IdOrdenTrabajo);
        EXEC @Bloqueo=sys.sp_getapplock @Resource=@Recurso,
             @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
        IF @Bloqueo<0 THROW 51201,N'No se pudo bloquear la orden de trabajo.',1;
        SELECT @EstadoActual=eo.NombreEstado,@FechaAplicacion=ot.FechaAplicacionInventario
        FROM servicio_tecnico.OrdenTrabajo ot
        JOIN servicio_tecnico.EstadoOrdenTrabajo eo ON eo.IdEstadoOrdenTrabajo=ot.IdEstadoOrdenTrabajo
        WHERE ot.IdOrdenTrabajo=@IdOrdenTrabajo;
        IF @EstadoActual IS NULL THROW 51202,N'La orden no existe.',1;
        IF @EstadoActual IN (N'Cerrada',N'Cancelada') OR @FechaAplicacion IS NOT NULL
            THROW 51203,N'La orden ya fue cerrada/cancelada o consumió su inventario.',1;
        SELECT @EstadoCerrada=IdEstadoOrdenTrabajo FROM servicio_tecnico.EstadoOrdenTrabajo WHERE NombreEstado=N'Cerrada';
        SELECT @MotivoConsumo=mm.IdMotivoMovimiento FROM inventario.MotivoMovimiento mm
        JOIN inventario.TipoMovimiento tm ON tm.IdTipoMovimiento=mm.IdTipoMovimiento
        WHERE tm.NombreTipo=N'SALIDA' AND mm.NombreMotivo=N'Consumo por orden de trabajo';
        IF @EstadoCerrada IS NULL OR @MotivoConsumo IS NULL
            THROW 51204,N'Faltan catálogos de estados o movimientos.',1;
        DECLARE piezas CURSOR LOCAL FAST_FORWARD FOR
          SELECT IdArticulo, SUM(Cantidad) FROM servicio_tecnico.RepuestoOrdenTrabajo
          WHERE IdOrdenTrabajo=@IdOrdenTrabajo GROUP BY IdArticulo ORDER BY IdArticulo;
        OPEN piezas;
        FETCH NEXT FROM piezas INTO @IdArticulo,@Cantidad;
        WHILE @@FETCH_STATUS=0
        BEGIN
            EXEC inventario.pa_RegistrarMovimientoInventario
              @IdArticulo=@IdArticulo,@IdMotivoMovimiento=@MotivoConsumo,@Cantidad=@Cantidad,
              @IdUsuario=@IdUsuarioCierre,@EntidadReferencia=N'OrdenTrabajo',
              @IdReferencia=@IdOrdenTrabajo,@Observaciones=N'Consumo técnico en cierre',@DevolverRegistro=0;
            FETCH NEXT FROM piezas INTO @IdArticulo,@Cantidad;
        END;
        CLOSE piezas; DEALLOCATE piezas;
        UPDATE servicio_tecnico.OrdenTrabajo
        SET IdEstadoOrdenTrabajo=@EstadoCerrada,FechaCierre=SYSDATETIME(),FechaAplicacionInventario=SYSDATETIME(),
            Observaciones=COALESCE(@ObservacionesCierre,Observaciones)
        WHERE IdOrdenTrabajo=@IdOrdenTrabajo;
        INSERT INTO seguridad.BitacoraEvento(IdUsuario,NombreEntidad,ClaveRegistro,TipoAccion,Comentario)
        VALUES(@IdUsuarioCierre,N'servicio_tecnico.OrdenTrabajo',CONVERT(NVARCHAR(128),@IdOrdenTrabajo),
               N'CIERRE',@ObservacionesCierre);
        COMMIT TRANSACTION;
        SELECT * FROM servicio_tecnico.OrdenTrabajo WHERE IdOrdenTrabajo=@IdOrdenTrabajo;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local','piezas')>=0 CLOSE piezas;
        IF CURSOR_STATUS('local','piezas')>-3 DEALLOCATE piezas;
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* Venta de equipo: garantía automática de cuatro meses. */
CREATE TRIGGER comercial.Disparador_GenerarGarantiaVentaEquipo
ON comercial.DetalleOperacion
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO comercial.Garantia(IdDetalleOperacion,FechaInicio,MesesCobertura,DescripcionCobertura)
    SELECT i.IdDetalleOperacion,o.FechaOperacion,4,N'Mantenimiento incluido durante cuatro meses'
    FROM inserted i
    JOIN comercial.OperacionComercial o ON o.IdOperacion=i.IdOperacion
    JOIN comercial.TipoOperacion t ON t.IdTipoOperacion=o.IdTipoOperacion
    WHERE t.NombreTipo=N'Venta' AND i.IdEquipo IS NOT NULL
      AND NOT EXISTS(SELECT 1 FROM comercial.Garantia g WHERE g.IdDetalleOperacion=i.IdDetalleOperacion);
END;
GO

/* Cambios de estado definidos para el primer prototipo (validar con empresa). */
CREATE PROCEDURE comercial.pa_CambiarEstadoCotizacion
    @IdCotizacion INT,
    @IdEstadoDestino INT,
    @IdUsuarioResponsable INT,
    @Comentario NVARCHAR(400)=NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Anterior NVARCHAR(40),@Destino NVARCHAR(40);
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT @Anterior=e.NombreEstado FROM comercial.Cotizacion q WITH(UPDLOCK,HOLDLOCK)
        JOIN comercial.EstadoCotizacion e ON e.IdEstadoCotizacion=q.IdEstadoCotizacion
        WHERE q.IdCotizacion=@IdCotizacion;
        SELECT @Destino=NombreEstado FROM comercial.EstadoCotizacion WHERE IdEstadoCotizacion=@IdEstadoDestino;
        IF @Anterior IS NULL OR @Destino IS NULL THROW 51301,N'Cotización o estado inexistente.',1;
        IF NOT ((@Anterior=N'Borrador' AND @Destino=N'Pendiente') OR
                (@Anterior=N'Pendiente' AND @Destino IN (N'Aprobada',N'Rechazada')))
             THROW 51302,N'Transición de estado no permitida (propuesta pendiente de confirmación).',1;
        UPDATE comercial.Cotizacion SET IdEstadoCotizacion=@IdEstadoDestino
        WHERE IdCotizacion=@IdCotizacion;
        INSERT INTO seguridad.BitacoraEvento(IdUsuario,NombreEntidad,ClaveRegistro,TipoAccion,Comentario)
        VALUES(@IdUsuarioResponsable,N'comercial.Cotizacion',CONVERT(NVARCHAR(128),@IdCotizacion),
               N'ESTADO',CONCAT(@Anterior,N' -> ',@Destino,N'. ',ISNULL(@Comentario,N'')));
        COMMIT TRANSACTION;
        SELECT * FROM comercial.Cotizacion WHERE IdCotizacion=@IdCotizacion;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* Completar venta descuenta automáticamente el inventario físico, una sola vez. */
CREATE PROCEDURE comercial.pa_CompletarVenta
    @IdOperacion INT,
    @IdUsuarioResponsable INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Tipo NVARCHAR(40),@Estado NVARCHAR(40),@IdCompletada INT,
            @IdMotivoVenta INT,@IdArticulo INT,@Cantidad DECIMAL(18,2),@Bloqueo INT,@Recurso NVARCHAR(255);
    BEGIN TRY
        BEGIN TRANSACTION;
        SET @Recurso=CONCAT(N'SGC-Venta-',@IdOperacion);
        EXEC @Bloqueo=sys.sp_getapplock @Resource=@Recurso,@LockMode='Exclusive',
             @LockOwner='Transaction',@LockTimeout=15000;
        IF @Bloqueo<0 THROW 51310,N'No se pudo bloquear la operación.',1;
        SELECT @Tipo=tp.NombreTipo,@Estado=eo.NombreEstado
        FROM comercial.OperacionComercial op WITH(UPDLOCK,HOLDLOCK)
        JOIN comercial.TipoOperacion tp ON tp.IdTipoOperacion=op.IdTipoOperacion
        JOIN comercial.EstadoOperacion eo ON eo.IdEstadoOperacion=op.IdEstadoOperacion
        WHERE op.IdOperacion=@IdOperacion;
        IF @Tipo<>N'Venta' OR @Estado<>N'Registrada' OR @Tipo IS NULL
            THROW 51311,N'Únicamente una venta registrada puede completarse.',1;
        IF NOT EXISTS(SELECT 1 FROM comercial.DetalleOperacion WHERE IdOperacion=@IdOperacion)
            THROW 51312,N'No es posible completar una venta sin detalle.',1;
        SELECT @IdCompletada=IdEstadoOperacion FROM comercial.EstadoOperacion WHERE NombreEstado=N'Completada';
        SELECT @IdMotivoVenta=mm.IdMotivoMovimiento FROM inventario.MotivoMovimiento mm
        JOIN inventario.TipoMovimiento tm ON tm.IdTipoMovimiento=mm.IdTipoMovimiento
        WHERE mm.NombreMotivo=N'Venta' AND tm.NombreTipo=N'SALIDA';
        IF @IdMotivoVenta IS NULL OR @IdCompletada IS NULL THROW 51313,N'Faltan catálogos de venta.',1;
        DECLARE lineas CURSOR LOCAL FAST_FORWARD FOR
        SELECT d.IdArticulo, SUM(d.Cantidad)
        FROM comercial.DetalleOperacion d
        JOIN catalogos.Articulo a ON a.IdArticulo=d.IdArticulo
        JOIN catalogos.TipoArticulo t ON t.IdTipoArticulo=a.IdTipoArticulo
        WHERE d.IdOperacion=@IdOperacion AND t.NombreTipo<>N'Servicio'
        GROUP BY d.IdArticulo ORDER BY d.IdArticulo;
        OPEN lineas;
        FETCH NEXT FROM lineas INTO @IdArticulo,@Cantidad;
        WHILE @@FETCH_STATUS=0
        BEGIN
            IF @Cantidad<>FLOOR(@Cantidad) OR @Cantidad>2147483647
                THROW 51314,N'Para inventario físico la cantidad debe ser un entero dentro del rango permitido.',1;
            EXEC inventario.pa_RegistrarMovimientoInventario
                 @IdArticulo=@IdArticulo,@IdMotivoMovimiento=@IdMotivoVenta,
                 @Cantidad=@Cantidad,@IdUsuario=@IdUsuarioResponsable,
                 @EntidadReferencia=N'OperacionComercial',@IdReferencia=@IdOperacion,
                 @Observaciones=N'Salida por venta completada',@DevolverRegistro=0;
            FETCH NEXT FROM lineas INTO @IdArticulo,@Cantidad;
        END;
        CLOSE lineas; DEALLOCATE lineas;
        UPDATE comercial.OperacionComercial SET IdEstadoOperacion=@IdCompletada WHERE IdOperacion=@IdOperacion;
        INSERT INTO seguridad.BitacoraEvento(IdUsuario,NombreEntidad,ClaveRegistro,TipoAccion,Comentario)
        VALUES(@IdUsuarioResponsable,N'comercial.OperacionComercial',CONVERT(NVARCHAR(128),@IdOperacion),
               N'COMPLETAR_VENTA',N'Venta confirmada y movimientos de inventario aplicados.');
        COMMIT TRANSACTION;
        SELECT * FROM comercial.OperacionComercial WHERE IdOperacion=@IdOperacion;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local','lineas')>=0 CLOSE lineas;
        IF CURSOR_STATUS('local','lineas')>-3 DEALLOCATE lineas;
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* Credenciales para servicio de autenticación: limitar EXECUTE al componente autorizado.
   El hash se verifica con ASP.NET Core Identity/biblioteca apropiada EN LA APLICACIÓN. */
CREATE PROCEDURE seguridad.pa_Usuario_ObtenerCredenciales
    @NombreUsuario NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdUsuario,NombreUsuario,ResumenCriptograficoContrasena,Activo
    FROM seguridad.Usuario WHERE NombreUsuario=@NombreUsuario;
END;
GO


USE [SGC_UniversoTecnologico];
GO

-- Rol / Crear ([seguridad].[Rol])
CREATE PROCEDURE [seguridad].[pa_Rol_Crear]
    @NombreRol NVARCHAR(80),
    @DescripcionRol NVARCHAR(250) = NULL,
    @Activo BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [seguridad].[Rol] ([NombreRol], [DescripcionRol], [Activo]) VALUES (@NombreRol, @DescripcionRol, COALESCE(@Activo, 1));
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [seguridad].[Rol] WHERE [IdRol]=@IdentificadorNuevo;
END;
GO

-- Rol / ObtenerPorId ([seguridad].[Rol])
CREATE PROCEDURE [seguridad].[pa_Rol_ObtenerPorId]
    @IdRol INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [seguridad].[Rol] WHERE [IdRol]=@IdRol;
END;
GO

-- Rol / Listar ([seguridad].[Rol])
CREATE PROCEDURE [seguridad].[pa_Rol_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [seguridad].[Rol] ORDER BY [IdRol] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- Rol / Actualizar ([seguridad].[Rol])
CREATE PROCEDURE [seguridad].[pa_Rol_Actualizar]
    @IdRol INT,
    @NombreRol NVARCHAR(80),
    @DescripcionRol NVARCHAR(250),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [seguridad].[Rol] SET [NombreRol]=@NombreRol, [DescripcionRol]=@DescripcionRol, [Activo]=@Activo WHERE [IdRol]=@IdRol;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [seguridad].[Rol] WHERE [IdRol]=@IdRol;
END;
GO

-- Rol / Eliminar ([seguridad].[Rol])
CREATE PROCEDURE [seguridad].[pa_Rol_Eliminar]
    @IdRol INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [seguridad].[Rol] SET [Activo]=0 WHERE [IdRol]=@IdRol;
    IF @@ROWCOUNT=0 THROW 52008,N'No se encontró el registro.',1;
    SELECT * FROM [seguridad].[Rol] WHERE [IdRol]=@IdRol;
END;
GO

-- Permiso / Crear ([seguridad].[Permiso])
CREATE PROCEDURE [seguridad].[pa_Permiso_Crear]
    @CodigoPermiso NVARCHAR(50),
    @NombrePermiso NVARCHAR(120),
    @DescripcionPermiso NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [seguridad].[Permiso] ([CodigoPermiso], [NombrePermiso], [DescripcionPermiso]) VALUES (@CodigoPermiso, @NombrePermiso, @DescripcionPermiso);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [seguridad].[Permiso] WHERE [IdPermiso]=@IdentificadorNuevo;
END;
GO

-- Permiso / ObtenerPorId ([seguridad].[Permiso])
CREATE PROCEDURE [seguridad].[pa_Permiso_ObtenerPorId]
    @IdPermiso INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [seguridad].[Permiso] WHERE [IdPermiso]=@IdPermiso;
END;
GO

-- Permiso / Listar ([seguridad].[Permiso])
CREATE PROCEDURE [seguridad].[pa_Permiso_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [seguridad].[Permiso] ORDER BY [IdPermiso] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- Permiso / Actualizar ([seguridad].[Permiso])
CREATE PROCEDURE [seguridad].[pa_Permiso_Actualizar]
    @IdPermiso INT,
    @CodigoPermiso NVARCHAR(50),
    @NombrePermiso NVARCHAR(120),
    @DescripcionPermiso NVARCHAR(250)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [seguridad].[Permiso] SET [CodigoPermiso]=@CodigoPermiso, [NombrePermiso]=@NombrePermiso, [DescripcionPermiso]=@DescripcionPermiso WHERE [IdPermiso]=@IdPermiso;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [seguridad].[Permiso] WHERE [IdPermiso]=@IdPermiso;
END;
GO

-- Permiso / Eliminar ([seguridad].[Permiso])
CREATE PROCEDURE [seguridad].[pa_Permiso_Eliminar]
    @IdPermiso INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [seguridad].[Permiso] WHERE [IdPermiso]=@IdPermiso;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- RolPermiso / Crear ([seguridad].[RolPermiso])
CREATE PROCEDURE [seguridad].[pa_RolPermiso_Crear]
    @IdRol INT,
    @IdPermiso INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [seguridad].[RolPermiso] ([IdRol], [IdPermiso]) VALUES (@IdRol, @IdPermiso);
    SELECT * FROM [seguridad].[RolPermiso] WHERE [IdRol]=@IdRol AND [IdPermiso]=@IdPermiso;
END;
GO

-- RolPermiso / ObtenerPorId ([seguridad].[RolPermiso])
CREATE PROCEDURE [seguridad].[pa_RolPermiso_ObtenerPorId]
    @IdRol INT,
    @IdPermiso INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [seguridad].[RolPermiso] WHERE [IdRol]=@IdRol AND [IdPermiso]=@IdPermiso;
END;
GO

-- RolPermiso / Listar ([seguridad].[RolPermiso])
CREATE PROCEDURE [seguridad].[pa_RolPermiso_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [seguridad].[RolPermiso] ORDER BY [IdRol], [IdPermiso] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- RolPermiso / Actualizar ([seguridad].[RolPermiso])
CREATE PROCEDURE [seguridad].[pa_RolPermiso_Actualizar]
    @IdRol INT,
    @IdPermiso INT,
    @Nuevo_IdRol INT,
    @Nuevo_IdPermiso INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [seguridad].[RolPermiso] SET [IdRol]=@Nuevo_IdRol, [IdPermiso]=@Nuevo_IdPermiso WHERE [IdRol]=@IdRol AND [IdPermiso]=@IdPermiso;
    IF @@ROWCOUNT=0 THROW 52001,N'No se encontró la relación.',1;
    SELECT * FROM [seguridad].[RolPermiso] WHERE [IdRol]=@Nuevo_IdRol AND [IdPermiso]=@Nuevo_IdPermiso;
END;
GO

-- RolPermiso / Eliminar ([seguridad].[RolPermiso])
CREATE PROCEDURE [seguridad].[pa_RolPermiso_Eliminar]
    @IdRol INT,
    @IdPermiso INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [seguridad].[RolPermiso] WHERE [IdRol]=@IdRol AND [IdPermiso]=@IdPermiso;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- Usuario / Crear ([seguridad].[Usuario])
CREATE PROCEDURE [seguridad].[pa_Usuario_Crear]
    @NombreUsuario NVARCHAR(50),
    @ResumenCriptograficoContrasena NVARCHAR(255),
    @NombreCompleto NVARCHAR(150),
    @CorreoElectronico NVARCHAR(150),
    @Telefono NVARCHAR(30) = NULL,
    @Activo BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [seguridad].[Usuario] ([NombreUsuario], [ResumenCriptograficoContrasena], [NombreCompleto], [CorreoElectronico], [Telefono], [Activo]) VALUES (@NombreUsuario, @ResumenCriptograficoContrasena, @NombreCompleto, @CorreoElectronico, @Telefono, COALESCE(@Activo, 1));
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT [IdUsuario], [NombreUsuario], [NombreCompleto], [CorreoElectronico], [Telefono], [Activo], [FechaCreacion], [FechaActualizacion] FROM [seguridad].[Usuario] WHERE [IdUsuario]=@IdentificadorNuevo;
END;
GO

-- Usuario / ObtenerPorId ([seguridad].[Usuario])
CREATE PROCEDURE [seguridad].[pa_Usuario_ObtenerPorId]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [IdUsuario], [NombreUsuario], [NombreCompleto], [CorreoElectronico], [Telefono], [Activo], [FechaCreacion], [FechaActualizacion] FROM [seguridad].[Usuario] WHERE [IdUsuario]=@IdUsuario;
END;
GO

-- Usuario / Listar ([seguridad].[Usuario])
CREATE PROCEDURE [seguridad].[pa_Usuario_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT [IdUsuario], [NombreUsuario], [NombreCompleto], [CorreoElectronico], [Telefono], [Activo], [FechaCreacion], [FechaActualizacion] FROM [seguridad].[Usuario] ORDER BY [IdUsuario] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- Usuario / Actualizar ([seguridad].[Usuario])
CREATE PROCEDURE [seguridad].[pa_Usuario_Actualizar]
    @IdUsuario INT,
    @NombreUsuario NVARCHAR(50),
    @ResumenCriptograficoContrasena NVARCHAR(255),
    @NombreCompleto NVARCHAR(150),
    @CorreoElectronico NVARCHAR(150),
    @Telefono NVARCHAR(30),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [seguridad].[Usuario] SET [NombreUsuario]=@NombreUsuario, [ResumenCriptograficoContrasena]=@ResumenCriptograficoContrasena, [NombreCompleto]=@NombreCompleto, [CorreoElectronico]=@CorreoElectronico, [Telefono]=@Telefono, [Activo]=@Activo, [FechaActualizacion]=SYSDATETIME() WHERE [IdUsuario]=@IdUsuario;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT [IdUsuario], [NombreUsuario], [NombreCompleto], [CorreoElectronico], [Telefono], [Activo], [FechaCreacion], [FechaActualizacion] FROM [seguridad].[Usuario] WHERE [IdUsuario]=@IdUsuario;
END;
GO

-- Usuario / Eliminar ([seguridad].[Usuario])
CREATE PROCEDURE [seguridad].[pa_Usuario_Eliminar]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [seguridad].[Usuario] SET [Activo]=0, [FechaActualizacion]=SYSDATETIME() WHERE [IdUsuario]=@IdUsuario;
    IF @@ROWCOUNT=0 THROW 52008,N'No se encontró el registro.',1;
    SELECT [IdUsuario], [NombreUsuario], [NombreCompleto], [CorreoElectronico], [Telefono], [Activo], [FechaCreacion], [FechaActualizacion] FROM [seguridad].[Usuario] WHERE [IdUsuario]=@IdUsuario;
END;
GO

-- UsuarioRol / Crear ([seguridad].[UsuarioRol])
CREATE PROCEDURE [seguridad].[pa_UsuarioRol_Crear]
    @IdUsuario INT,
    @IdRol INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [seguridad].[UsuarioRol] ([IdUsuario], [IdRol]) VALUES (@IdUsuario, @IdRol);
    SELECT * FROM [seguridad].[UsuarioRol] WHERE [IdUsuario]=@IdUsuario AND [IdRol]=@IdRol;
END;
GO

-- UsuarioRol / ObtenerPorId ([seguridad].[UsuarioRol])
CREATE PROCEDURE [seguridad].[pa_UsuarioRol_ObtenerPorId]
    @IdUsuario INT,
    @IdRol INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [seguridad].[UsuarioRol] WHERE [IdUsuario]=@IdUsuario AND [IdRol]=@IdRol;
END;
GO

-- UsuarioRol / Listar ([seguridad].[UsuarioRol])
CREATE PROCEDURE [seguridad].[pa_UsuarioRol_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [seguridad].[UsuarioRol] ORDER BY [IdUsuario], [IdRol] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- UsuarioRol / Actualizar ([seguridad].[UsuarioRol])
CREATE PROCEDURE [seguridad].[pa_UsuarioRol_Actualizar]
    @IdUsuario INT,
    @IdRol INT,
    @Nuevo_IdUsuario INT,
    @Nuevo_IdRol INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [seguridad].[UsuarioRol] SET [IdUsuario]=@Nuevo_IdUsuario, [IdRol]=@Nuevo_IdRol WHERE [IdUsuario]=@IdUsuario AND [IdRol]=@IdRol;
    IF @@ROWCOUNT=0 THROW 52001,N'No se encontró la relación.',1;
    SELECT * FROM [seguridad].[UsuarioRol] WHERE [IdUsuario]=@Nuevo_IdUsuario AND [IdRol]=@Nuevo_IdRol;
END;
GO

-- UsuarioRol / Eliminar ([seguridad].[UsuarioRol])
CREATE PROCEDURE [seguridad].[pa_UsuarioRol_Eliminar]
    @IdUsuario INT,
    @IdRol INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [seguridad].[UsuarioRol] WHERE [IdUsuario]=@IdUsuario AND [IdRol]=@IdRol;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- BitacoraEvento / Crear ([seguridad].[BitacoraEvento])
CREATE PROCEDURE [seguridad].[pa_BitacoraEvento_Crear]
    @NombreEntidad NVARCHAR(128),
    @TipoAccion NVARCHAR(50),
    @IdUsuario INT = NULL,
    @ClaveRegistro NVARCHAR(128) = NULL,
    @Comentario NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [seguridad].[BitacoraEvento] ([NombreEntidad], [TipoAccion], [IdUsuario], [ClaveRegistro], [Comentario]) VALUES (@NombreEntidad, @TipoAccion, @IdUsuario, @ClaveRegistro, @Comentario);
    DECLARE @IdentificadorNuevo BIGINT = CONVERT(BIGINT, SCOPE_IDENTITY());
    SELECT * FROM [seguridad].[BitacoraEvento] WHERE [IdBitacoraEvento]=@IdentificadorNuevo;
END;
GO

-- BitacoraEvento / ObtenerPorId ([seguridad].[BitacoraEvento])
CREATE PROCEDURE [seguridad].[pa_BitacoraEvento_ObtenerPorId]
    @IdBitacoraEvento BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [seguridad].[BitacoraEvento] WHERE [IdBitacoraEvento]=@IdBitacoraEvento;
END;
GO

-- BitacoraEvento / Listar ([seguridad].[BitacoraEvento])
CREATE PROCEDURE [seguridad].[pa_BitacoraEvento_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [seguridad].[BitacoraEvento] ORDER BY [IdBitacoraEvento] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- BitacoraEvento / Actualizar ([seguridad].[BitacoraEvento])
CREATE PROCEDURE [seguridad].[pa_BitacoraEvento_Actualizar]
    @IdBitacoraEvento BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    THROW 52011, N'La bitácora es inmutable por trazabilidad.', 1;
END;
GO

-- BitacoraEvento / Eliminar ([seguridad].[BitacoraEvento])
CREATE PROCEDURE [seguridad].[pa_BitacoraEvento_Eliminar]
    @IdBitacoraEvento BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    THROW 52031,N'No se elimina la bitácora de auditoría.',1;
END;
GO


-- Cliente / Crear ([catalogos].[Cliente])
CREATE PROCEDURE [catalogos].[pa_Cliente_Crear]
    @Identificacion NVARCHAR(50),
    @NombreORazonSocial NVARCHAR(150),
    @Telefono NVARCHAR(30),
    @CorreoElectronico NVARCHAR(150),
    @Direccion NVARCHAR(250),
    @NombreContacto NVARCHAR(150) = NULL,
    @Activo BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [catalogos].[Cliente] ([Identificacion], [NombreORazonSocial], [Telefono], [CorreoElectronico], [Direccion], [NombreContacto], [Activo]) VALUES (@Identificacion, @NombreORazonSocial, @Telefono, @CorreoElectronico, @Direccion, @NombreContacto, COALESCE(@Activo, 1));
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [catalogos].[Cliente] WHERE [IdCliente]=@IdentificadorNuevo;
END;
GO

-- Cliente / ObtenerPorId ([catalogos].[Cliente])
CREATE PROCEDURE [catalogos].[pa_Cliente_ObtenerPorId]
    @IdCliente INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [catalogos].[Cliente] WHERE [IdCliente]=@IdCliente;
END;
GO

-- Cliente / Listar ([catalogos].[Cliente])
CREATE PROCEDURE [catalogos].[pa_Cliente_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [catalogos].[Cliente] ORDER BY [IdCliente] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- Cliente / Actualizar ([catalogos].[Cliente])
CREATE PROCEDURE [catalogos].[pa_Cliente_Actualizar]
    @IdCliente INT,
    @Identificacion NVARCHAR(50),
    @NombreORazonSocial NVARCHAR(150),
    @NombreContacto NVARCHAR(150),
    @Telefono NVARCHAR(30),
    @CorreoElectronico NVARCHAR(150),
    @Direccion NVARCHAR(250),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[Cliente] SET [Identificacion]=@Identificacion, [NombreORazonSocial]=@NombreORazonSocial, [NombreContacto]=@NombreContacto, [Telefono]=@Telefono, [CorreoElectronico]=@CorreoElectronico, [Direccion]=@Direccion, [Activo]=@Activo, [FechaActualizacion]=SYSDATETIME() WHERE [IdCliente]=@IdCliente;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[Cliente] WHERE [IdCliente]=@IdCliente;
END;
GO

-- Cliente / Eliminar ([catalogos].[Cliente])
CREATE PROCEDURE [catalogos].[pa_Cliente_Eliminar]
    @IdCliente INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[Cliente] SET [Activo]=0, [FechaActualizacion]=SYSDATETIME() WHERE [IdCliente]=@IdCliente;
    IF @@ROWCOUNT=0 THROW 52008,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[Cliente] WHERE [IdCliente]=@IdCliente;
END;
GO

-- Prospecto / Crear ([catalogos].[Prospecto])
CREATE PROCEDURE [catalogos].[pa_Prospecto_Crear]
    @NombreProspecto NVARCHAR(150),
    @Identificacion NVARCHAR(50) = NULL,
    @Telefono NVARCHAR(30) = NULL,
    @CorreoElectronico NVARCHAR(150) = NULL,
    @Direccion NVARCHAR(250) = NULL,
    @Activo BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [catalogos].[Prospecto] ([NombreProspecto], [Identificacion], [Telefono], [CorreoElectronico], [Direccion], [Activo]) VALUES (@NombreProspecto, @Identificacion, @Telefono, @CorreoElectronico, @Direccion, COALESCE(@Activo, 1));
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [catalogos].[Prospecto] WHERE [IdProspecto]=@IdentificadorNuevo;
END;
GO

-- Prospecto / ObtenerPorId ([catalogos].[Prospecto])
CREATE PROCEDURE [catalogos].[pa_Prospecto_ObtenerPorId]
    @IdProspecto INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [catalogos].[Prospecto] WHERE [IdProspecto]=@IdProspecto;
END;
GO

-- Prospecto / Listar ([catalogos].[Prospecto])
CREATE PROCEDURE [catalogos].[pa_Prospecto_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [catalogos].[Prospecto] ORDER BY [IdProspecto] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- Prospecto / Actualizar ([catalogos].[Prospecto])
CREATE PROCEDURE [catalogos].[pa_Prospecto_Actualizar]
    @IdProspecto INT,
    @NombreProspecto NVARCHAR(150),
    @Identificacion NVARCHAR(50),
    @Telefono NVARCHAR(30),
    @CorreoElectronico NVARCHAR(150),
    @Direccion NVARCHAR(250),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[Prospecto] SET [NombreProspecto]=@NombreProspecto, [Identificacion]=@Identificacion, [Telefono]=@Telefono, [CorreoElectronico]=@CorreoElectronico, [Direccion]=@Direccion, [Activo]=@Activo, [FechaActualizacion]=SYSDATETIME() WHERE [IdProspecto]=@IdProspecto;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[Prospecto] WHERE [IdProspecto]=@IdProspecto;
END;
GO

-- Prospecto / Eliminar ([catalogos].[Prospecto])
CREATE PROCEDURE [catalogos].[pa_Prospecto_Eliminar]
    @IdProspecto INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[Prospecto] SET [Activo]=0, [FechaActualizacion]=SYSDATETIME() WHERE [IdProspecto]=@IdProspecto;
    IF @@ROWCOUNT=0 THROW 52008,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[Prospecto] WHERE [IdProspecto]=@IdProspecto;
END;
GO

-- Marca / Crear ([catalogos].[Marca])
CREATE PROCEDURE [catalogos].[pa_Marca_Crear]
    @NombreMarca NVARCHAR(80),
    @Activo BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [catalogos].[Marca] ([NombreMarca], [Activo]) VALUES (@NombreMarca, COALESCE(@Activo, 1));
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [catalogos].[Marca] WHERE [IdMarca]=@IdentificadorNuevo;
END;
GO

-- Marca / ObtenerPorId ([catalogos].[Marca])
CREATE PROCEDURE [catalogos].[pa_Marca_ObtenerPorId]
    @IdMarca INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [catalogos].[Marca] WHERE [IdMarca]=@IdMarca;
END;
GO

-- Marca / Listar ([catalogos].[Marca])
CREATE PROCEDURE [catalogos].[pa_Marca_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [catalogos].[Marca] ORDER BY [IdMarca] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- Marca / Actualizar ([catalogos].[Marca])
CREATE PROCEDURE [catalogos].[pa_Marca_Actualizar]
    @IdMarca INT,
    @NombreMarca NVARCHAR(80),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[Marca] SET [NombreMarca]=@NombreMarca, [Activo]=@Activo WHERE [IdMarca]=@IdMarca;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[Marca] WHERE [IdMarca]=@IdMarca;
END;
GO

-- Marca / Eliminar ([catalogos].[Marca])
CREATE PROCEDURE [catalogos].[pa_Marca_Eliminar]
    @IdMarca INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[Marca] SET [Activo]=0 WHERE [IdMarca]=@IdMarca;
    IF @@ROWCOUNT=0 THROW 52008,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[Marca] WHERE [IdMarca]=@IdMarca;
END;
GO

-- EstadoEquipo / Crear ([catalogos].[EstadoEquipo])
CREATE PROCEDURE [catalogos].[pa_EstadoEquipo_Crear]
    @NombreEstado NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [catalogos].[EstadoEquipo] ([NombreEstado]) VALUES (@NombreEstado);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [catalogos].[EstadoEquipo] WHERE [IdEstadoEquipo]=@IdentificadorNuevo;
END;
GO

-- EstadoEquipo / ObtenerPorId ([catalogos].[EstadoEquipo])
CREATE PROCEDURE [catalogos].[pa_EstadoEquipo_ObtenerPorId]
    @IdEstadoEquipo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [catalogos].[EstadoEquipo] WHERE [IdEstadoEquipo]=@IdEstadoEquipo;
END;
GO

-- EstadoEquipo / Listar ([catalogos].[EstadoEquipo])
CREATE PROCEDURE [catalogos].[pa_EstadoEquipo_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [catalogos].[EstadoEquipo] ORDER BY [IdEstadoEquipo] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- EstadoEquipo / Actualizar ([catalogos].[EstadoEquipo])
CREATE PROCEDURE [catalogos].[pa_EstadoEquipo_Actualizar]
    @IdEstadoEquipo INT,
    @NombreEstado NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[EstadoEquipo] SET [NombreEstado]=@NombreEstado WHERE [IdEstadoEquipo]=@IdEstadoEquipo;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[EstadoEquipo] WHERE [IdEstadoEquipo]=@IdEstadoEquipo;
END;
GO

-- EstadoEquipo / Eliminar ([catalogos].[EstadoEquipo])
CREATE PROCEDURE [catalogos].[pa_EstadoEquipo_Eliminar]
    @IdEstadoEquipo INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [catalogos].[EstadoEquipo] WHERE [IdEstadoEquipo]=@IdEstadoEquipo;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- ModeloEquipo / Crear ([catalogos].[ModeloEquipo])
CREATE PROCEDURE [catalogos].[pa_ModeloEquipo_Crear]
    @IdMarca INT,
    @NombreModelo NVARCHAR(100),
    @DescripcionModelo NVARCHAR(250) = NULL,
    @Activo BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [catalogos].[ModeloEquipo] ([IdMarca], [NombreModelo], [DescripcionModelo], [Activo]) VALUES (@IdMarca, @NombreModelo, @DescripcionModelo, COALESCE(@Activo, 1));
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [catalogos].[ModeloEquipo] WHERE [IdModeloEquipo]=@IdentificadorNuevo;
END;
GO

-- ModeloEquipo / ObtenerPorId ([catalogos].[ModeloEquipo])
CREATE PROCEDURE [catalogos].[pa_ModeloEquipo_ObtenerPorId]
    @IdModeloEquipo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [catalogos].[ModeloEquipo] WHERE [IdModeloEquipo]=@IdModeloEquipo;
END;
GO

-- ModeloEquipo / Listar ([catalogos].[ModeloEquipo])
CREATE PROCEDURE [catalogos].[pa_ModeloEquipo_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [catalogos].[ModeloEquipo] ORDER BY [IdModeloEquipo] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- ModeloEquipo / Actualizar ([catalogos].[ModeloEquipo])
CREATE PROCEDURE [catalogos].[pa_ModeloEquipo_Actualizar]
    @IdModeloEquipo INT,
    @IdMarca INT,
    @NombreModelo NVARCHAR(100),
    @DescripcionModelo NVARCHAR(250),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[ModeloEquipo] SET [IdMarca]=@IdMarca, [NombreModelo]=@NombreModelo, [DescripcionModelo]=@DescripcionModelo, [Activo]=@Activo WHERE [IdModeloEquipo]=@IdModeloEquipo;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[ModeloEquipo] WHERE [IdModeloEquipo]=@IdModeloEquipo;
END;
GO

-- ModeloEquipo / Eliminar ([catalogos].[ModeloEquipo])
CREATE PROCEDURE [catalogos].[pa_ModeloEquipo_Eliminar]
    @IdModeloEquipo INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[ModeloEquipo] SET [Activo]=0 WHERE [IdModeloEquipo]=@IdModeloEquipo;
    IF @@ROWCOUNT=0 THROW 52008,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[ModeloEquipo] WHERE [IdModeloEquipo]=@IdModeloEquipo;
END;
GO

-- Equipo / Crear ([catalogos].[Equipo])
CREATE PROCEDURE [catalogos].[pa_Equipo_Crear]
    @IdCliente INT,
    @IdModeloEquipo INT,
    @UbicacionFisica NVARCHAR(200),
    @IdEstadoEquipo INT,
    @NumeroSerie NVARCHAR(100) = NULL,
    @Activo BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [catalogos].[Equipo] ([IdCliente], [IdModeloEquipo], [UbicacionFisica], [IdEstadoEquipo], [NumeroSerie], [Activo]) VALUES (@IdCliente, @IdModeloEquipo, @UbicacionFisica, @IdEstadoEquipo, @NumeroSerie, COALESCE(@Activo, 1));
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [catalogos].[Equipo] WHERE [IdEquipo]=@IdentificadorNuevo;
END;
GO

-- Equipo / ObtenerPorId ([catalogos].[Equipo])
CREATE PROCEDURE [catalogos].[pa_Equipo_ObtenerPorId]
    @IdEquipo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [catalogos].[Equipo] WHERE [IdEquipo]=@IdEquipo;
END;
GO

-- Equipo / Listar ([catalogos].[Equipo])
CREATE PROCEDURE [catalogos].[pa_Equipo_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [catalogos].[Equipo] ORDER BY [IdEquipo] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- Equipo / Actualizar ([catalogos].[Equipo])
CREATE PROCEDURE [catalogos].[pa_Equipo_Actualizar]
    @IdEquipo INT,
    @IdCliente INT,
    @IdModeloEquipo INT,
    @NumeroSerie NVARCHAR(100),
    @UbicacionFisica NVARCHAR(200),
    @IdEstadoEquipo INT,
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[Equipo] SET [IdCliente]=@IdCliente, [IdModeloEquipo]=@IdModeloEquipo, [NumeroSerie]=@NumeroSerie, [UbicacionFisica]=@UbicacionFisica, [IdEstadoEquipo]=@IdEstadoEquipo, [Activo]=@Activo, [FechaActualizacion]=SYSDATETIME() WHERE [IdEquipo]=@IdEquipo;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[Equipo] WHERE [IdEquipo]=@IdEquipo;
END;
GO

-- Equipo / Eliminar ([catalogos].[Equipo])
CREATE PROCEDURE [catalogos].[pa_Equipo_Eliminar]
    @IdEquipo INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[Equipo] SET [Activo]=0, [FechaActualizacion]=SYSDATETIME() WHERE [IdEquipo]=@IdEquipo;
    IF @@ROWCOUNT=0 THROW 52008,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[Equipo] WHERE [IdEquipo]=@IdEquipo;
END;
GO

-- UnidadMedida / Crear ([catalogos].[UnidadMedida])
CREATE PROCEDURE [catalogos].[pa_UnidadMedida_Crear]
    @CodigoUnidad NVARCHAR(20),
    @NombreUnidad NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [catalogos].[UnidadMedida] ([CodigoUnidad], [NombreUnidad]) VALUES (@CodigoUnidad, @NombreUnidad);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [catalogos].[UnidadMedida] WHERE [IdUnidadMedida]=@IdentificadorNuevo;
END;
GO

-- UnidadMedida / ObtenerPorId ([catalogos].[UnidadMedida])
CREATE PROCEDURE [catalogos].[pa_UnidadMedida_ObtenerPorId]
    @IdUnidadMedida INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [catalogos].[UnidadMedida] WHERE [IdUnidadMedida]=@IdUnidadMedida;
END;
GO

-- UnidadMedida / Listar ([catalogos].[UnidadMedida])
CREATE PROCEDURE [catalogos].[pa_UnidadMedida_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [catalogos].[UnidadMedida] ORDER BY [IdUnidadMedida] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- UnidadMedida / Actualizar ([catalogos].[UnidadMedida])
CREATE PROCEDURE [catalogos].[pa_UnidadMedida_Actualizar]
    @IdUnidadMedida INT,
    @CodigoUnidad NVARCHAR(20),
    @NombreUnidad NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[UnidadMedida] SET [CodigoUnidad]=@CodigoUnidad, [NombreUnidad]=@NombreUnidad WHERE [IdUnidadMedida]=@IdUnidadMedida;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[UnidadMedida] WHERE [IdUnidadMedida]=@IdUnidadMedida;
END;
GO

-- UnidadMedida / Eliminar ([catalogos].[UnidadMedida])
CREATE PROCEDURE [catalogos].[pa_UnidadMedida_Eliminar]
    @IdUnidadMedida INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [catalogos].[UnidadMedida] WHERE [IdUnidadMedida]=@IdUnidadMedida;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- TipoArticulo / Crear ([catalogos].[TipoArticulo])
CREATE PROCEDURE [catalogos].[pa_TipoArticulo_Crear]
    @NombreTipo NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [catalogos].[TipoArticulo] ([NombreTipo]) VALUES (@NombreTipo);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [catalogos].[TipoArticulo] WHERE [IdTipoArticulo]=@IdentificadorNuevo;
END;
GO

-- TipoArticulo / ObtenerPorId ([catalogos].[TipoArticulo])
CREATE PROCEDURE [catalogos].[pa_TipoArticulo_ObtenerPorId]
    @IdTipoArticulo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [catalogos].[TipoArticulo] WHERE [IdTipoArticulo]=@IdTipoArticulo;
END;
GO

-- TipoArticulo / Listar ([catalogos].[TipoArticulo])
CREATE PROCEDURE [catalogos].[pa_TipoArticulo_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [catalogos].[TipoArticulo] ORDER BY [IdTipoArticulo] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- TipoArticulo / Actualizar ([catalogos].[TipoArticulo])
CREATE PROCEDURE [catalogos].[pa_TipoArticulo_Actualizar]
    @IdTipoArticulo INT,
    @NombreTipo NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[TipoArticulo] SET [NombreTipo]=@NombreTipo WHERE [IdTipoArticulo]=@IdTipoArticulo;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[TipoArticulo] WHERE [IdTipoArticulo]=@IdTipoArticulo;
END;
GO

-- TipoArticulo / Eliminar ([catalogos].[TipoArticulo])
CREATE PROCEDURE [catalogos].[pa_TipoArticulo_Eliminar]
    @IdTipoArticulo INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [catalogos].[TipoArticulo] WHERE [IdTipoArticulo]=@IdTipoArticulo;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- Articulo / Crear ([catalogos].[Articulo])
CREATE PROCEDURE [catalogos].[pa_Articulo_Crear]
    @CodigoArticulo NVARCHAR(50),
    @NombreArticulo NVARCHAR(150),
    @IdTipoArticulo INT,
    @IdUnidadMedida INT,
    @CostoUnitario DECIMAL(18,2),
    @DescripcionArticulo NVARCHAR(250) = NULL,
    @ExistenciaMinima INT = NULL,
    @Activo BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [catalogos].[Articulo] ([CodigoArticulo], [NombreArticulo], [IdTipoArticulo], [IdUnidadMedida], [CostoUnitario], [DescripcionArticulo], [ExistenciaMinima], [Activo]) VALUES (@CodigoArticulo, @NombreArticulo, @IdTipoArticulo, @IdUnidadMedida, @CostoUnitario, @DescripcionArticulo, COALESCE(@ExistenciaMinima, 0), COALESCE(@Activo, 1));
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [catalogos].[Articulo] WHERE [IdArticulo]=@IdentificadorNuevo;
END;
GO

-- Articulo / ObtenerPorId ([catalogos].[Articulo])
CREATE PROCEDURE [catalogos].[pa_Articulo_ObtenerPorId]
    @IdArticulo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [catalogos].[Articulo] WHERE [IdArticulo]=@IdArticulo;
END;
GO

-- Articulo / Listar ([catalogos].[Articulo])
CREATE PROCEDURE [catalogos].[pa_Articulo_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [catalogos].[Articulo] ORDER BY [IdArticulo] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- Articulo / Actualizar ([catalogos].[Articulo])
CREATE PROCEDURE [catalogos].[pa_Articulo_Actualizar]
    @IdArticulo INT,
    @CodigoArticulo NVARCHAR(50),
    @NombreArticulo NVARCHAR(150),
    @DescripcionArticulo NVARCHAR(250),
    @IdTipoArticulo INT,
    @IdUnidadMedida INT,
    @CostoUnitario DECIMAL(18,2),
    @ExistenciaMinima INT,
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[Articulo] SET [CodigoArticulo]=@CodigoArticulo, [NombreArticulo]=@NombreArticulo, [DescripcionArticulo]=@DescripcionArticulo, [IdTipoArticulo]=@IdTipoArticulo, [IdUnidadMedida]=@IdUnidadMedida, [CostoUnitario]=@CostoUnitario, [ExistenciaMinima]=@ExistenciaMinima, [Activo]=@Activo, [FechaActualizacion]=SYSDATETIME() WHERE [IdArticulo]=@IdArticulo;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[Articulo] WHERE [IdArticulo]=@IdArticulo;
END;
GO

-- Articulo / Eliminar ([catalogos].[Articulo])
CREATE PROCEDURE [catalogos].[pa_Articulo_Eliminar]
    @IdArticulo INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[Articulo] SET [Activo]=0, [FechaActualizacion]=SYSDATETIME() WHERE [IdArticulo]=@IdArticulo;
    IF @@ROWCOUNT=0 THROW 52008,N'No se encontró el registro.',1;
    SELECT * FROM [catalogos].[Articulo] WHERE [IdArticulo]=@IdArticulo;
END;
GO

-- CompatibilidadRepuesto / Crear ([catalogos].[CompatibilidadRepuesto])
CREATE PROCEDURE [catalogos].[pa_CompatibilidadRepuesto_Crear]
    @IdArticulo INT,
    @IdModeloEquipo INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM catalogos.Articulo a JOIN catalogos.TipoArticulo t ON t.IdTipoArticulo=a.IdTipoArticulo WHERE a.IdArticulo=@IdArticulo AND t.NombreTipo=N'Repuesto') THROW 52044,N'Solo los repuestos admiten compatibilidad.',1;
    INSERT INTO [catalogos].[CompatibilidadRepuesto] ([IdArticulo], [IdModeloEquipo]) VALUES (@IdArticulo, @IdModeloEquipo);
    SELECT * FROM [catalogos].[CompatibilidadRepuesto] WHERE [IdArticulo]=@IdArticulo AND [IdModeloEquipo]=@IdModeloEquipo;
END;
GO

-- CompatibilidadRepuesto / ObtenerPorId ([catalogos].[CompatibilidadRepuesto])
CREATE PROCEDURE [catalogos].[pa_CompatibilidadRepuesto_ObtenerPorId]
    @IdArticulo INT,
    @IdModeloEquipo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [catalogos].[CompatibilidadRepuesto] WHERE [IdArticulo]=@IdArticulo AND [IdModeloEquipo]=@IdModeloEquipo;
END;
GO

-- CompatibilidadRepuesto / Listar ([catalogos].[CompatibilidadRepuesto])
CREATE PROCEDURE [catalogos].[pa_CompatibilidadRepuesto_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [catalogos].[CompatibilidadRepuesto] ORDER BY [IdArticulo], [IdModeloEquipo] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- CompatibilidadRepuesto / Actualizar ([catalogos].[CompatibilidadRepuesto])
CREATE PROCEDURE [catalogos].[pa_CompatibilidadRepuesto_Actualizar]
    @IdArticulo INT,
    @IdModeloEquipo INT,
    @Nuevo_IdArticulo INT,
    @Nuevo_IdModeloEquipo INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [catalogos].[CompatibilidadRepuesto] SET [IdArticulo]=@Nuevo_IdArticulo, [IdModeloEquipo]=@Nuevo_IdModeloEquipo WHERE [IdArticulo]=@IdArticulo AND [IdModeloEquipo]=@IdModeloEquipo;
    IF @@ROWCOUNT=0 THROW 52001,N'No se encontró la relación.',1;
    SELECT * FROM [catalogos].[CompatibilidadRepuesto] WHERE [IdArticulo]=@Nuevo_IdArticulo AND [IdModeloEquipo]=@Nuevo_IdModeloEquipo;
END;
GO

-- CompatibilidadRepuesto / Eliminar ([catalogos].[CompatibilidadRepuesto])
CREATE PROCEDURE [catalogos].[pa_CompatibilidadRepuesto_Eliminar]
    @IdArticulo INT,
    @IdModeloEquipo INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [catalogos].[CompatibilidadRepuesto] WHERE [IdArticulo]=@IdArticulo AND [IdModeloEquipo]=@IdModeloEquipo;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO



USE [SGC_UniversoTecnologico];
GO

-- TipoMovimiento / Crear ([inventario].[TipoMovimiento])
CREATE PROCEDURE [inventario].[pa_TipoMovimiento_Crear]
    @NombreTipo NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [inventario].[TipoMovimiento] ([NombreTipo]) VALUES (@NombreTipo);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [inventario].[TipoMovimiento] WHERE [IdTipoMovimiento]=@IdentificadorNuevo;
END;
GO

-- TipoMovimiento / ObtenerPorId ([inventario].[TipoMovimiento])
CREATE PROCEDURE [inventario].[pa_TipoMovimiento_ObtenerPorId]
    @IdTipoMovimiento INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [inventario].[TipoMovimiento] WHERE [IdTipoMovimiento]=@IdTipoMovimiento;
END;
GO

-- TipoMovimiento / Listar ([inventario].[TipoMovimiento])
CREATE PROCEDURE [inventario].[pa_TipoMovimiento_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [inventario].[TipoMovimiento] ORDER BY [IdTipoMovimiento] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- TipoMovimiento / Actualizar ([inventario].[TipoMovimiento])
CREATE PROCEDURE [inventario].[pa_TipoMovimiento_Actualizar]
    @IdTipoMovimiento INT,
    @NombreTipo NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [inventario].[TipoMovimiento] SET [NombreTipo]=@NombreTipo WHERE [IdTipoMovimiento]=@IdTipoMovimiento;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [inventario].[TipoMovimiento] WHERE [IdTipoMovimiento]=@IdTipoMovimiento;
END;
GO

-- TipoMovimiento / Eliminar ([inventario].[TipoMovimiento])
CREATE PROCEDURE [inventario].[pa_TipoMovimiento_Eliminar]
    @IdTipoMovimiento INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [inventario].[TipoMovimiento] WHERE [IdTipoMovimiento]=@IdTipoMovimiento;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- MotivoMovimiento / Crear ([inventario].[MotivoMovimiento])
CREATE PROCEDURE [inventario].[pa_MotivoMovimiento_Crear]
    @IdTipoMovimiento INT,
    @NombreMotivo NVARCHAR(80),
    @DescripcionMotivo NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [inventario].[MotivoMovimiento] ([IdTipoMovimiento], [NombreMotivo], [DescripcionMotivo]) VALUES (@IdTipoMovimiento, @NombreMotivo, @DescripcionMotivo);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [inventario].[MotivoMovimiento] WHERE [IdMotivoMovimiento]=@IdentificadorNuevo;
END;
GO

-- MotivoMovimiento / ObtenerPorId ([inventario].[MotivoMovimiento])
CREATE PROCEDURE [inventario].[pa_MotivoMovimiento_ObtenerPorId]
    @IdMotivoMovimiento INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [inventario].[MotivoMovimiento] WHERE [IdMotivoMovimiento]=@IdMotivoMovimiento;
END;
GO

-- MotivoMovimiento / Listar ([inventario].[MotivoMovimiento])
CREATE PROCEDURE [inventario].[pa_MotivoMovimiento_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [inventario].[MotivoMovimiento] ORDER BY [IdMotivoMovimiento] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- MotivoMovimiento / Actualizar ([inventario].[MotivoMovimiento])
CREATE PROCEDURE [inventario].[pa_MotivoMovimiento_Actualizar]
    @IdMotivoMovimiento INT,
    @IdTipoMovimiento INT,
    @NombreMotivo NVARCHAR(80),
    @DescripcionMotivo NVARCHAR(250)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [inventario].[MotivoMovimiento] SET [IdTipoMovimiento]=@IdTipoMovimiento, [NombreMotivo]=@NombreMotivo, [DescripcionMotivo]=@DescripcionMotivo WHERE [IdMotivoMovimiento]=@IdMotivoMovimiento;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [inventario].[MotivoMovimiento] WHERE [IdMotivoMovimiento]=@IdMotivoMovimiento;
END;
GO

-- MotivoMovimiento / Eliminar ([inventario].[MotivoMovimiento])
CREATE PROCEDURE [inventario].[pa_MotivoMovimiento_Eliminar]
    @IdMotivoMovimiento INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [inventario].[MotivoMovimiento] WHERE [IdMotivoMovimiento]=@IdMotivoMovimiento;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- MovimientoInventario / Crear ([inventario].[MovimientoInventario])
CREATE PROCEDURE [inventario].[pa_MovimientoInventario_Crear]
    @IdArticulo INT,
    @IdMotivoMovimiento INT,
    @Cantidad INT,
    @IdUsuario INT,
    @EntidadReferencia NVARCHAR(60) = NULL,
    @IdReferencia INT = NULL,
    @Observaciones NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC inventario.pa_RegistrarMovimientoInventario @IdArticulo=@IdArticulo, @IdMotivoMovimiento=@IdMotivoMovimiento, @Cantidad=@Cantidad, @IdUsuario=@IdUsuario, @EntidadReferencia=@EntidadReferencia, @IdReferencia=@IdReferencia, @Observaciones=@Observaciones;
END;
GO

-- MovimientoInventario / ObtenerPorId ([inventario].[MovimientoInventario])
CREATE PROCEDURE [inventario].[pa_MovimientoInventario_ObtenerPorId]
    @IdMovimientoInventario BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [inventario].[MovimientoInventario] WHERE [IdMovimientoInventario]=@IdMovimientoInventario;
END;
GO

-- MovimientoInventario / Listar ([inventario].[MovimientoInventario])
CREATE PROCEDURE [inventario].[pa_MovimientoInventario_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [inventario].[MovimientoInventario] ORDER BY [IdMovimientoInventario] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- MovimientoInventario / Actualizar ([inventario].[MovimientoInventario])
CREATE PROCEDURE [inventario].[pa_MovimientoInventario_Actualizar]
    @IdMovimientoInventario BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    THROW 52010, N'Los movimientos son inmutables. Registre un movimiento de compensación.', 1;
END;
GO

-- MovimientoInventario / Eliminar ([inventario].[MovimientoInventario])
CREATE PROCEDURE [inventario].[pa_MovimientoInventario_Eliminar]
    @IdMovimientoInventario BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    THROW 52030,N'No se eliminan movimientos; registre una compensación para conservar el historial.',1;
END;
GO


-- EstadoCotizacion / Crear ([comercial].[EstadoCotizacion])
CREATE PROCEDURE [comercial].[pa_EstadoCotizacion_Crear]
    @NombreEstado NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [comercial].[EstadoCotizacion] ([NombreEstado]) VALUES (@NombreEstado);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [comercial].[EstadoCotizacion] WHERE [IdEstadoCotizacion]=@IdentificadorNuevo;
END;
GO

-- EstadoCotizacion / ObtenerPorId ([comercial].[EstadoCotizacion])
CREATE PROCEDURE [comercial].[pa_EstadoCotizacion_ObtenerPorId]
    @IdEstadoCotizacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [comercial].[EstadoCotizacion] WHERE [IdEstadoCotizacion]=@IdEstadoCotizacion;
END;
GO

-- EstadoCotizacion / Listar ([comercial].[EstadoCotizacion])
CREATE PROCEDURE [comercial].[pa_EstadoCotizacion_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [comercial].[EstadoCotizacion] ORDER BY [IdEstadoCotizacion] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- EstadoCotizacion / Actualizar ([comercial].[EstadoCotizacion])
CREATE PROCEDURE [comercial].[pa_EstadoCotizacion_Actualizar]
    @IdEstadoCotizacion INT,
    @NombreEstado NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [comercial].[EstadoCotizacion] SET [NombreEstado]=@NombreEstado WHERE [IdEstadoCotizacion]=@IdEstadoCotizacion;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [comercial].[EstadoCotizacion] WHERE [IdEstadoCotizacion]=@IdEstadoCotizacion;
END;
GO

-- EstadoCotizacion / Eliminar ([comercial].[EstadoCotizacion])
CREATE PROCEDURE [comercial].[pa_EstadoCotizacion_Eliminar]
    @IdEstadoCotizacion INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [comercial].[EstadoCotizacion] WHERE [IdEstadoCotizacion]=@IdEstadoCotizacion;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- Cotizacion / Crear ([comercial].[Cotizacion])
CREATE PROCEDURE [comercial].[pa_Cotizacion_Crear]
    @IdEstadoCotizacion INT,
    @IdUsuarioCreador INT,
    @IdCliente INT = NULL,
    @IdProspecto INT = NULL,
    @FechaCotizacion DATE = NULL,
    @FechaVencimiento DATE = NULL,
    @Observaciones NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM comercial.EstadoCotizacion WHERE IdEstadoCotizacion=@IdEstadoCotizacion AND NombreEstado=N'Borrador') THROW 52050,N'La cotización debe crearse en estado Borrador.',1;
    INSERT INTO [comercial].[Cotizacion] ([IdEstadoCotizacion], [IdUsuarioCreador], [IdCliente], [IdProspecto], [FechaCotizacion], [FechaVencimiento], [Observaciones]) VALUES (@IdEstadoCotizacion, @IdUsuarioCreador, @IdCliente, @IdProspecto, COALESCE(@FechaCotizacion, CAST(GETDATE() AS DATE)), @FechaVencimiento, @Observaciones);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [comercial].[Cotizacion] WHERE [IdCotizacion]=@IdentificadorNuevo;
END;
GO

-- Cotizacion / ObtenerPorId ([comercial].[Cotizacion])
CREATE PROCEDURE [comercial].[pa_Cotizacion_ObtenerPorId]
    @IdCotizacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [comercial].[Cotizacion] WHERE [IdCotizacion]=@IdCotizacion;
END;
GO

-- Cotizacion / Listar ([comercial].[Cotizacion])
CREATE PROCEDURE [comercial].[pa_Cotizacion_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [comercial].[Cotizacion] ORDER BY [IdCotizacion] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- Cotizacion / Actualizar ([comercial].[Cotizacion])
CREATE PROCEDURE [comercial].[pa_Cotizacion_Actualizar]
    @IdCotizacion INT,
    @IdCliente INT,
    @IdProspecto INT,
    @FechaCotizacion DATE,
    @FechaVencimiento DATE,
    @IdEstadoCotizacion INT,
    @Observaciones NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM comercial.Cotizacion q JOIN comercial.EstadoCotizacion e ON e.IdEstadoCotizacion=q.IdEstadoCotizacion WHERE q.IdCotizacion=@IdCotizacion AND e.NombreEstado=N'Borrador') THROW 52020,N'Solo se puede editar una cotización en borrador; el cambio de estado debe gestionarse de forma controlada.',1;
    UPDATE [comercial].[Cotizacion] SET [IdCliente]=@IdCliente, [IdProspecto]=@IdProspecto, [FechaCotizacion]=@FechaCotizacion, [FechaVencimiento]=@FechaVencimiento, [IdEstadoCotizacion]=@IdEstadoCotizacion, [Observaciones]=@Observaciones WHERE [IdCotizacion]=@IdCotizacion;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [comercial].[Cotizacion] WHERE [IdCotizacion]=@IdCotizacion;
END;
GO

-- Cotizacion / Eliminar ([comercial].[Cotizacion])
CREATE PROCEDURE [comercial].[pa_Cotizacion_Eliminar]
    @IdCotizacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    IF NOT EXISTS (SELECT 1 FROM comercial.Cotizacion q JOIN comercial.EstadoCotizacion e ON e.IdEstadoCotizacion=q.IdEstadoCotizacion WHERE q.IdCotizacion=@IdCotizacion AND e.NombreEstado=N'Borrador') BEGIN ROLLBACK TRANSACTION; THROW 52033,N'Solo se elimina físicamente una cotización en borrador.',1; END;
    DELETE FROM comercial.DetalleCotizacion WHERE IdCotizacion=@IdCotizacion;
    DELETE FROM [comercial].[Cotizacion] WHERE [IdCotizacion]=@IdCotizacion;
    COMMIT TRANSACTION;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- DetalleCotizacion / Crear ([comercial].[DetalleCotizacion])
CREATE PROCEDURE [comercial].[pa_DetalleCotizacion_Crear]
    @IdCotizacion INT,
    @NumeroLinea SMALLINT,
    @DescripcionLinea NVARCHAR(250),
    @Cantidad DECIMAL(18,2),
    @PrecioUnitario DECIMAL(18,2),
    @IdArticulo INT = NULL,
    @PorcentajeImpuesto DECIMAL(5,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM comercial.Cotizacion q JOIN comercial.EstadoCotizacion e ON e.IdEstadoCotizacion=q.IdEstadoCotizacion WHERE q.IdCotizacion=@IdCotizacion AND e.NombreEstado=N'Borrador') THROW 52051,N'El detalle solo se agrega a cotizaciones en borrador.',1;
    INSERT INTO [comercial].[DetalleCotizacion] ([IdCotizacion], [NumeroLinea], [DescripcionLinea], [Cantidad], [PrecioUnitario], [IdArticulo], [PorcentajeImpuesto]) VALUES (@IdCotizacion, @NumeroLinea, @DescripcionLinea, @Cantidad, @PrecioUnitario, @IdArticulo, COALESCE(@PorcentajeImpuesto, 0));
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [comercial].[DetalleCotizacion] WHERE [IdDetalleCotizacion]=@IdentificadorNuevo;
END;
GO

-- DetalleCotizacion / ObtenerPorId ([comercial].[DetalleCotizacion])
CREATE PROCEDURE [comercial].[pa_DetalleCotizacion_ObtenerPorId]
    @IdDetalleCotizacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [comercial].[DetalleCotizacion] WHERE [IdDetalleCotizacion]=@IdDetalleCotizacion;
END;
GO

-- DetalleCotizacion / Listar ([comercial].[DetalleCotizacion])
CREATE PROCEDURE [comercial].[pa_DetalleCotizacion_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [comercial].[DetalleCotizacion] ORDER BY [IdDetalleCotizacion] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- DetalleCotizacion / Actualizar ([comercial].[DetalleCotizacion])
CREATE PROCEDURE [comercial].[pa_DetalleCotizacion_Actualizar]
    @IdDetalleCotizacion INT,
    @IdCotizacion INT,
    @NumeroLinea SMALLINT,
    @IdArticulo INT,
    @DescripcionLinea NVARCHAR(250),
    @Cantidad DECIMAL(18,2),
    @PrecioUnitario DECIMAL(18,2),
    @PorcentajeImpuesto DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM comercial.DetalleCotizacion d JOIN comercial.Cotizacion q ON q.IdCotizacion=d.IdCotizacion JOIN comercial.EstadoCotizacion e ON e.IdEstadoCotizacion=q.IdEstadoCotizacion WHERE d.IdDetalleCotizacion=@IdDetalleCotizacion AND e.NombreEstado=N'Borrador') THROW 52021,N'Solo se puede editar el detalle de una cotización en borrador.',1;
    UPDATE [comercial].[DetalleCotizacion] SET [IdCotizacion]=@IdCotizacion, [NumeroLinea]=@NumeroLinea, [IdArticulo]=@IdArticulo, [DescripcionLinea]=@DescripcionLinea, [Cantidad]=@Cantidad, [PrecioUnitario]=@PrecioUnitario, [PorcentajeImpuesto]=@PorcentajeImpuesto WHERE [IdDetalleCotizacion]=@IdDetalleCotizacion;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [comercial].[DetalleCotizacion] WHERE [IdDetalleCotizacion]=@IdDetalleCotizacion;
END;
GO

-- DetalleCotizacion / Eliminar ([comercial].[DetalleCotizacion])
CREATE PROCEDURE [comercial].[pa_DetalleCotizacion_Eliminar]
    @IdDetalleCotizacion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM comercial.DetalleCotizacion d JOIN comercial.Cotizacion q ON q.IdCotizacion=d.IdCotizacion JOIN comercial.EstadoCotizacion e ON e.IdEstadoCotizacion=q.IdEstadoCotizacion WHERE d.IdDetalleCotizacion=@IdDetalleCotizacion AND e.NombreEstado=N'Borrador') THROW 52034,N'Solo se elimina detalle de cotizaciones en borrador.',1;
    DELETE FROM [comercial].[DetalleCotizacion] WHERE [IdDetalleCotizacion]=@IdDetalleCotizacion;
    IF @@ROWCOUNT=0 THROW 52006,N'No se encontró la línea.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- TipoOperacion / Crear ([comercial].[TipoOperacion])
CREATE PROCEDURE [comercial].[pa_TipoOperacion_Crear]
    @NombreTipo NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [comercial].[TipoOperacion] ([NombreTipo]) VALUES (@NombreTipo);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [comercial].[TipoOperacion] WHERE [IdTipoOperacion]=@IdentificadorNuevo;
END;
GO

-- TipoOperacion / ObtenerPorId ([comercial].[TipoOperacion])
CREATE PROCEDURE [comercial].[pa_TipoOperacion_ObtenerPorId]
    @IdTipoOperacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [comercial].[TipoOperacion] WHERE [IdTipoOperacion]=@IdTipoOperacion;
END;
GO

-- TipoOperacion / Listar ([comercial].[TipoOperacion])
CREATE PROCEDURE [comercial].[pa_TipoOperacion_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [comercial].[TipoOperacion] ORDER BY [IdTipoOperacion] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- TipoOperacion / Actualizar ([comercial].[TipoOperacion])
CREATE PROCEDURE [comercial].[pa_TipoOperacion_Actualizar]
    @IdTipoOperacion INT,
    @NombreTipo NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [comercial].[TipoOperacion] SET [NombreTipo]=@NombreTipo WHERE [IdTipoOperacion]=@IdTipoOperacion;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [comercial].[TipoOperacion] WHERE [IdTipoOperacion]=@IdTipoOperacion;
END;
GO

-- TipoOperacion / Eliminar ([comercial].[TipoOperacion])
CREATE PROCEDURE [comercial].[pa_TipoOperacion_Eliminar]
    @IdTipoOperacion INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [comercial].[TipoOperacion] WHERE [IdTipoOperacion]=@IdTipoOperacion;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- EstadoOperacion / Crear ([comercial].[EstadoOperacion])
CREATE PROCEDURE [comercial].[pa_EstadoOperacion_Crear]
    @NombreEstado NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [comercial].[EstadoOperacion] ([NombreEstado]) VALUES (@NombreEstado);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [comercial].[EstadoOperacion] WHERE [IdEstadoOperacion]=@IdentificadorNuevo;
END;
GO

-- EstadoOperacion / ObtenerPorId ([comercial].[EstadoOperacion])
CREATE PROCEDURE [comercial].[pa_EstadoOperacion_ObtenerPorId]
    @IdEstadoOperacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [comercial].[EstadoOperacion] WHERE [IdEstadoOperacion]=@IdEstadoOperacion;
END;
GO

-- EstadoOperacion / Listar ([comercial].[EstadoOperacion])
CREATE PROCEDURE [comercial].[pa_EstadoOperacion_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [comercial].[EstadoOperacion] ORDER BY [IdEstadoOperacion] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- EstadoOperacion / Actualizar ([comercial].[EstadoOperacion])
CREATE PROCEDURE [comercial].[pa_EstadoOperacion_Actualizar]
    @IdEstadoOperacion INT,
    @NombreEstado NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [comercial].[EstadoOperacion] SET [NombreEstado]=@NombreEstado WHERE [IdEstadoOperacion]=@IdEstadoOperacion;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [comercial].[EstadoOperacion] WHERE [IdEstadoOperacion]=@IdEstadoOperacion;
END;
GO

-- EstadoOperacion / Eliminar ([comercial].[EstadoOperacion])
CREATE PROCEDURE [comercial].[pa_EstadoOperacion_Eliminar]
    @IdEstadoOperacion INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [comercial].[EstadoOperacion] WHERE [IdEstadoOperacion]=@IdEstadoOperacion;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- OperacionComercial / Crear ([comercial].[OperacionComercial])
CREATE PROCEDURE [comercial].[pa_OperacionComercial_Crear]
    @IdCliente INT,
    @IdTipoOperacion INT,
    @IdEstadoOperacion INT,
    @IdUsuarioCreador INT,
    @IdCotizacionOrigen INT = NULL,
    @FechaOperacion DATE = NULL,
    @Observaciones NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM comercial.EstadoOperacion WHERE IdEstadoOperacion=@IdEstadoOperacion AND NombreEstado=N'Registrada') THROW 52052,N'La operación debe crearse como Registrada.',1;
    INSERT INTO [comercial].[OperacionComercial] ([IdCliente], [IdTipoOperacion], [IdEstadoOperacion], [IdUsuarioCreador], [IdCotizacionOrigen], [FechaOperacion], [Observaciones]) VALUES (@IdCliente, @IdTipoOperacion, @IdEstadoOperacion, @IdUsuarioCreador, @IdCotizacionOrigen, COALESCE(@FechaOperacion, CAST(GETDATE() AS DATE)), @Observaciones);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [comercial].[OperacionComercial] WHERE [IdOperacion]=@IdentificadorNuevo;
END;
GO

-- OperacionComercial / ObtenerPorId ([comercial].[OperacionComercial])
CREATE PROCEDURE [comercial].[pa_OperacionComercial_ObtenerPorId]
    @IdOperacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [comercial].[OperacionComercial] WHERE [IdOperacion]=@IdOperacion;
END;
GO

-- OperacionComercial / Listar ([comercial].[OperacionComercial])
CREATE PROCEDURE [comercial].[pa_OperacionComercial_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [comercial].[OperacionComercial] ORDER BY [IdOperacion] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- OperacionComercial / Actualizar ([comercial].[OperacionComercial])
CREATE PROCEDURE [comercial].[pa_OperacionComercial_Actualizar]
    @IdOperacion INT,
    @IdCliente INT,
    @IdTipoOperacion INT,
    @IdEstadoOperacion INT,
    @IdCotizacionOrigen INT,
    @FechaOperacion DATE,
    @Observaciones NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM comercial.OperacionComercial o JOIN comercial.EstadoOperacion e ON e.IdEstadoOperacion=o.IdEstadoOperacion WHERE o.IdOperacion=@IdOperacion AND e.NombreEstado<>N'Registrada') THROW 52025,N'La operación está finalizada o anulada.',1;
    IF EXISTS(SELECT 1 FROM comercial.DetalleOperacion d JOIN comercial.Garantia g ON g.IdDetalleOperacion=d.IdDetalleOperacion WHERE d.IdOperacion=@IdOperacion) AND EXISTS(SELECT 1 FROM comercial.OperacionComercial WHERE IdOperacion=@IdOperacion AND FechaOperacion<>@FechaOperacion) THROW 52026,N'No se puede alterar la fecha de una venta con garantías.',1;
    IF EXISTS(SELECT 1 FROM comercial.TipoOperacion t JOIN comercial.EstadoOperacion e ON e.IdEstadoOperacion=@IdEstadoOperacion WHERE t.IdTipoOperacion=@IdTipoOperacion AND t.NombreTipo=N'Venta' AND e.NombreEstado=N'Completada') THROW 52043,N'Para completar una venta use comercial.pa_CompletarVenta.',1;
    IF EXISTS(SELECT 1 FROM comercial.EstadoOperacion WHERE IdEstadoOperacion=@IdEstadoOperacion AND NombreEstado=N'Anulada') THROW 52057,N'Para anular use pa_OperacionComercial_Eliminar.',1;
    UPDATE [comercial].[OperacionComercial] SET [IdCliente]=@IdCliente, [IdTipoOperacion]=@IdTipoOperacion, [IdEstadoOperacion]=@IdEstadoOperacion, [IdCotizacionOrigen]=@IdCotizacionOrigen, [FechaOperacion]=@FechaOperacion, [Observaciones]=@Observaciones WHERE [IdOperacion]=@IdOperacion;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [comercial].[OperacionComercial] WHERE [IdOperacion]=@IdOperacion;
END;
GO

-- OperacionComercial / Eliminar ([comercial].[OperacionComercial])
CREATE PROCEDURE [comercial].[pa_OperacionComercial_Eliminar]
    @IdOperacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    IF EXISTS(SELECT 1 FROM comercial.OperacionComercial o JOIN comercial.EstadoOperacion e ON e.IdEstadoOperacion=o.IdEstadoOperacion WHERE o.IdOperacion=@IdOperacion AND e.NombreEstado=N'Completada') BEGIN ROLLBACK TRANSACTION; THROW 52047,N'Una operación completada no se anula por CRUD genérico.',1; END;
    DECLARE @IdAnulada INT=(SELECT IdEstadoOperacion FROM comercial.EstadoOperacion WHERE NombreEstado=N'Anulada');
    UPDATE [comercial].[OperacionComercial] SET IdEstadoOperacion=@IdAnulada WHERE [IdOperacion]=@IdOperacion;
    IF @@ROWCOUNT=0 BEGIN ROLLBACK TRANSACTION; THROW 52005,N'No se encontró la operación.',1; END;
    UPDATE comercial.Garantia SET Activo=0 WHERE IdDetalleOperacion IN (SELECT IdDetalleOperacion FROM comercial.DetalleOperacion WHERE IdOperacion=@IdOperacion);
    COMMIT TRANSACTION;
    SELECT * FROM [comercial].[OperacionComercial] WHERE [IdOperacion]=@IdOperacion;
END;
GO

-- DetalleOperacion / Crear ([comercial].[DetalleOperacion])
CREATE PROCEDURE [comercial].[pa_DetalleOperacion_Crear]
    @IdOperacion INT,
    @NumeroLinea SMALLINT,
    @DescripcionLinea NVARCHAR(250),
    @Cantidad DECIMAL(18,2),
    @PrecioUnitario DECIMAL(18,2),
    @IdArticulo INT = NULL,
    @IdEquipo INT = NULL,
    @PorcentajeImpuesto DECIMAL(5,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM comercial.OperacionComercial o JOIN comercial.EstadoOperacion e ON e.IdEstadoOperacion=o.IdEstadoOperacion WHERE o.IdOperacion=@IdOperacion AND e.NombreEstado=N'Registrada') THROW 52053,N'Solo se agregan líneas a operaciones registradas.',1;
    INSERT INTO [comercial].[DetalleOperacion] ([IdOperacion], [NumeroLinea], [DescripcionLinea], [Cantidad], [PrecioUnitario], [IdArticulo], [IdEquipo], [PorcentajeImpuesto]) VALUES (@IdOperacion, @NumeroLinea, @DescripcionLinea, @Cantidad, @PrecioUnitario, @IdArticulo, @IdEquipo, COALESCE(@PorcentajeImpuesto, 0));
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [comercial].[DetalleOperacion] WHERE [IdDetalleOperacion]=@IdentificadorNuevo;
END;
GO

-- DetalleOperacion / ObtenerPorId ([comercial].[DetalleOperacion])
CREATE PROCEDURE [comercial].[pa_DetalleOperacion_ObtenerPorId]
    @IdDetalleOperacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [comercial].[DetalleOperacion] WHERE [IdDetalleOperacion]=@IdDetalleOperacion;
END;
GO

-- DetalleOperacion / Listar ([comercial].[DetalleOperacion])
CREATE PROCEDURE [comercial].[pa_DetalleOperacion_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [comercial].[DetalleOperacion] ORDER BY [IdDetalleOperacion] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- DetalleOperacion / Actualizar ([comercial].[DetalleOperacion])
CREATE PROCEDURE [comercial].[pa_DetalleOperacion_Actualizar]
    @IdDetalleOperacion INT,
    @IdOperacion INT,
    @NumeroLinea SMALLINT,
    @IdArticulo INT,
    @IdEquipo INT,
    @DescripcionLinea NVARCHAR(250),
    @Cantidad DECIMAL(18,2),
    @PrecioUnitario DECIMAL(18,2),
    @PorcentajeImpuesto DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM comercial.Garantia WHERE IdDetalleOperacion=@IdDetalleOperacion) THROW 52023,N'La línea tiene una garantía; no se puede alterar.',1;
    IF EXISTS (SELECT 1 FROM comercial.DetalleOperacion d JOIN comercial.OperacionComercial o ON o.IdOperacion=d.IdOperacion JOIN comercial.EstadoOperacion e ON e.IdEstadoOperacion=o.IdEstadoOperacion WHERE d.IdDetalleOperacion=@IdDetalleOperacion AND e.NombreEstado<>N'Registrada') THROW 52024,N'Solo se pueden editar operaciones registradas.',1;
    IF NOT EXISTS(SELECT 1 FROM comercial.OperacionComercial o JOIN comercial.EstadoOperacion e ON e.IdEstadoOperacion=o.IdEstadoOperacion WHERE o.IdOperacion=@IdOperacion AND e.NombreEstado=N'Registrada') THROW 52053,N'La operación destino no está registrada.',1;
    UPDATE [comercial].[DetalleOperacion] SET [IdOperacion]=@IdOperacion, [NumeroLinea]=@NumeroLinea, [IdArticulo]=@IdArticulo, [IdEquipo]=@IdEquipo, [DescripcionLinea]=@DescripcionLinea, [Cantidad]=@Cantidad, [PrecioUnitario]=@PrecioUnitario, [PorcentajeImpuesto]=@PorcentajeImpuesto WHERE [IdDetalleOperacion]=@IdDetalleOperacion;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [comercial].[DetalleOperacion] WHERE [IdDetalleOperacion]=@IdDetalleOperacion;
END;
GO

-- DetalleOperacion / Eliminar ([comercial].[DetalleOperacion])
CREATE PROCEDURE [comercial].[pa_DetalleOperacion_Eliminar]
    @IdDetalleOperacion INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [comercial].[DetalleOperacion] WHERE [IdDetalleOperacion]=@IdDetalleOperacion;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- Garantia / Crear ([comercial].[Garantia])
CREATE PROCEDURE [comercial].[pa_Garantia_Crear]
    @IdDetalleOperacion INT,
    @FechaInicio DATE,
    @DescripcionCobertura NVARCHAR(250),
    @MesesCobertura TINYINT = NULL,
    @Activo BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @MesesCobertura IS NOT NULL AND @MesesCobertura<>4 THROW 52056,N'La cobertura estándar del equipo vendido es de cuatro meses.',1;
    INSERT INTO [comercial].[Garantia] ([IdDetalleOperacion], [FechaInicio], [DescripcionCobertura], [MesesCobertura], [Activo]) VALUES (@IdDetalleOperacion, @FechaInicio, @DescripcionCobertura, COALESCE(@MesesCobertura, 4), COALESCE(@Activo, 1));
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [comercial].[Garantia] WHERE [IdGarantia]=@IdentificadorNuevo;
END;
GO

-- Garantia / ObtenerPorId ([comercial].[Garantia])
CREATE PROCEDURE [comercial].[pa_Garantia_ObtenerPorId]
    @IdGarantia INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [comercial].[Garantia] WHERE [IdGarantia]=@IdGarantia;
END;
GO

-- Garantia / Listar ([comercial].[Garantia])
CREATE PROCEDURE [comercial].[pa_Garantia_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [comercial].[Garantia] ORDER BY [IdGarantia] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- Garantia / Actualizar ([comercial].[Garantia])
CREATE PROCEDURE [comercial].[pa_Garantia_Actualizar]
    @IdGarantia INT,
    @IdDetalleOperacion INT,
    @FechaInicio DATE,
    @MesesCobertura TINYINT,
    @DescripcionCobertura NVARCHAR(250),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF @MesesCobertura<>4 THROW 52027,N'La garantía de mantenimiento estándar es de cuatro meses.',1;
    UPDATE [comercial].[Garantia] SET [IdDetalleOperacion]=@IdDetalleOperacion, [FechaInicio]=@FechaInicio, [MesesCobertura]=@MesesCobertura, [DescripcionCobertura]=@DescripcionCobertura, [Activo]=@Activo WHERE [IdGarantia]=@IdGarantia;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [comercial].[Garantia] WHERE [IdGarantia]=@IdGarantia;
END;
GO

-- Garantia / Eliminar ([comercial].[Garantia])
CREATE PROCEDURE [comercial].[pa_Garantia_Eliminar]
    @IdGarantia INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [comercial].[Garantia] SET [Activo]=0 WHERE [IdGarantia]=@IdGarantia;
    IF @@ROWCOUNT=0 THROW 52008,N'No se encontró el registro.',1;
    SELECT * FROM [comercial].[Garantia] WHERE [IdGarantia]=@IdGarantia;
END;
GO

-- ContratoAlquiler / Crear ([comercial].[ContratoAlquiler])
CREATE PROCEDURE [comercial].[pa_ContratoAlquiler_Crear]
    @IdOperacion INT,
    @FechaInicio DATE,
    @FechaFin DATE = NULL,
    @ObservacionesContrato NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM comercial.OperacionComercial o JOIN comercial.TipoOperacion t ON t.IdTipoOperacion=o.IdTipoOperacion WHERE o.IdOperacion=@IdOperacion AND t.NombreTipo=N'Alquiler') THROW 52042,N'Solo una operación de alquiler puede tener contrato.',1;
    INSERT INTO [comercial].[ContratoAlquiler] ([IdOperacion], [FechaInicio], [FechaFin], [ObservacionesContrato]) VALUES (@IdOperacion, @FechaInicio, @FechaFin, @ObservacionesContrato);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [comercial].[ContratoAlquiler] WHERE [IdContratoAlquiler]=@IdentificadorNuevo;
END;
GO

-- ContratoAlquiler / ObtenerPorId ([comercial].[ContratoAlquiler])
CREATE PROCEDURE [comercial].[pa_ContratoAlquiler_ObtenerPorId]
    @IdContratoAlquiler INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [comercial].[ContratoAlquiler] WHERE [IdContratoAlquiler]=@IdContratoAlquiler;
END;
GO

-- ContratoAlquiler / Listar ([comercial].[ContratoAlquiler])
CREATE PROCEDURE [comercial].[pa_ContratoAlquiler_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [comercial].[ContratoAlquiler] ORDER BY [IdContratoAlquiler] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- ContratoAlquiler / Actualizar ([comercial].[ContratoAlquiler])
CREATE PROCEDURE [comercial].[pa_ContratoAlquiler_Actualizar]
    @IdContratoAlquiler INT,
    @IdOperacion INT,
    @FechaInicio DATE,
    @FechaFin DATE,
    @ObservacionesContrato NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM comercial.OperacionComercial o JOIN comercial.TipoOperacion t ON t.IdTipoOperacion=o.IdTipoOperacion WHERE o.IdOperacion=@IdOperacion AND t.NombreTipo=N'Alquiler') THROW 52042,N'Solo una operación de alquiler puede tener contrato.',1;
    UPDATE [comercial].[ContratoAlquiler] SET [IdOperacion]=@IdOperacion, [FechaInicio]=@FechaInicio, [FechaFin]=@FechaFin, [ObservacionesContrato]=@ObservacionesContrato WHERE [IdContratoAlquiler]=@IdContratoAlquiler;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [comercial].[ContratoAlquiler] WHERE [IdContratoAlquiler]=@IdContratoAlquiler;
END;
GO

-- ContratoAlquiler / Eliminar ([comercial].[ContratoAlquiler])
CREATE PROCEDURE [comercial].[pa_ContratoAlquiler_Eliminar]
    @IdContratoAlquiler INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [comercial].[ContratoAlquiler] WHERE [IdContratoAlquiler]=@IdContratoAlquiler;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- EquipoContratoAlquiler / Crear ([comercial].[EquipoContratoAlquiler])
CREATE PROCEDURE [comercial].[pa_EquipoContratoAlquiler_Crear]
    @IdContratoAlquiler INT,
    @IdEquipo INT,
    @CuotaMensual DECIMAL(18,2) = NULL,
    @Activo BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM comercial.ContratoAlquiler c JOIN comercial.OperacionComercial o ON o.IdOperacion=c.IdOperacion JOIN comercial.TipoOperacion t ON t.IdTipoOperacion=o.IdTipoOperacion JOIN catalogos.Equipo e ON e.IdCliente=o.IdCliente WHERE c.IdContratoAlquiler=@IdContratoAlquiler AND t.NombreTipo=N'Alquiler' AND e.IdEquipo=@IdEquipo) THROW 52045,N'El equipo no pertenece al cliente del alquiler.',1;
    INSERT INTO [comercial].[EquipoContratoAlquiler] ([IdContratoAlquiler], [IdEquipo], [CuotaMensual], [Activo]) VALUES (@IdContratoAlquiler, @IdEquipo, @CuotaMensual, COALESCE(@Activo, 1));
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [comercial].[EquipoContratoAlquiler] WHERE [IdEquipoContratoAlquiler]=@IdentificadorNuevo;
END;
GO

-- EquipoContratoAlquiler / ObtenerPorId ([comercial].[EquipoContratoAlquiler])
CREATE PROCEDURE [comercial].[pa_EquipoContratoAlquiler_ObtenerPorId]
    @IdEquipoContratoAlquiler INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [comercial].[EquipoContratoAlquiler] WHERE [IdEquipoContratoAlquiler]=@IdEquipoContratoAlquiler;
END;
GO

-- EquipoContratoAlquiler / Listar ([comercial].[EquipoContratoAlquiler])
CREATE PROCEDURE [comercial].[pa_EquipoContratoAlquiler_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [comercial].[EquipoContratoAlquiler] ORDER BY [IdEquipoContratoAlquiler] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- EquipoContratoAlquiler / Actualizar ([comercial].[EquipoContratoAlquiler])
CREATE PROCEDURE [comercial].[pa_EquipoContratoAlquiler_Actualizar]
    @IdEquipoContratoAlquiler INT,
    @IdContratoAlquiler INT,
    @IdEquipo INT,
    @CuotaMensual DECIMAL(18,2),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM comercial.ContratoAlquiler c JOIN comercial.OperacionComercial o ON o.IdOperacion=c.IdOperacion JOIN comercial.TipoOperacion t ON t.IdTipoOperacion=o.IdTipoOperacion JOIN catalogos.Equipo e ON e.IdCliente=o.IdCliente WHERE c.IdContratoAlquiler=@IdContratoAlquiler AND t.NombreTipo=N'Alquiler' AND e.IdEquipo=@IdEquipo) THROW 52045,N'El equipo no pertenece al cliente del contrato.',1;
    UPDATE [comercial].[EquipoContratoAlquiler] SET [IdContratoAlquiler]=@IdContratoAlquiler, [IdEquipo]=@IdEquipo, [CuotaMensual]=@CuotaMensual, [Activo]=@Activo WHERE [IdEquipoContratoAlquiler]=@IdEquipoContratoAlquiler;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [comercial].[EquipoContratoAlquiler] WHERE [IdEquipoContratoAlquiler]=@IdEquipoContratoAlquiler;
END;
GO

-- EquipoContratoAlquiler / Eliminar ([comercial].[EquipoContratoAlquiler])
CREATE PROCEDURE [comercial].[pa_EquipoContratoAlquiler_Eliminar]
    @IdEquipoContratoAlquiler INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [comercial].[EquipoContratoAlquiler] SET [Activo]=0 WHERE [IdEquipoContratoAlquiler]=@IdEquipoContratoAlquiler;
    IF @@ROWCOUNT=0 THROW 52008,N'No se encontró el registro.',1;
    SELECT * FROM [comercial].[EquipoContratoAlquiler] WHERE [IdEquipoContratoAlquiler]=@IdEquipoContratoAlquiler;
END;
GO



USE [SGC_UniversoTecnologico];
GO

-- EstadoSolicitudServicio / Crear ([servicio_tecnico].[EstadoSolicitudServicio])
CREATE PROCEDURE [servicio_tecnico].[pa_EstadoSolicitudServicio_Crear]
    @NombreEstado NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [servicio_tecnico].[EstadoSolicitudServicio] ([NombreEstado]) VALUES (@NombreEstado);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [servicio_tecnico].[EstadoSolicitudServicio] WHERE [IdEstadoSolicitudServicio]=@IdentificadorNuevo;
END;
GO

-- EstadoSolicitudServicio / ObtenerPorId ([servicio_tecnico].[EstadoSolicitudServicio])
CREATE PROCEDURE [servicio_tecnico].[pa_EstadoSolicitudServicio_ObtenerPorId]
    @IdEstadoSolicitudServicio INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [servicio_tecnico].[EstadoSolicitudServicio] WHERE [IdEstadoSolicitudServicio]=@IdEstadoSolicitudServicio;
END;
GO

-- EstadoSolicitudServicio / Listar ([servicio_tecnico].[EstadoSolicitudServicio])
CREATE PROCEDURE [servicio_tecnico].[pa_EstadoSolicitudServicio_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [servicio_tecnico].[EstadoSolicitudServicio] ORDER BY [IdEstadoSolicitudServicio] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- EstadoSolicitudServicio / Actualizar ([servicio_tecnico].[EstadoSolicitudServicio])
CREATE PROCEDURE [servicio_tecnico].[pa_EstadoSolicitudServicio_Actualizar]
    @IdEstadoSolicitudServicio INT,
    @NombreEstado NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [servicio_tecnico].[EstadoSolicitudServicio] SET [NombreEstado]=@NombreEstado WHERE [IdEstadoSolicitudServicio]=@IdEstadoSolicitudServicio;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [servicio_tecnico].[EstadoSolicitudServicio] WHERE [IdEstadoSolicitudServicio]=@IdEstadoSolicitudServicio;
END;
GO

-- EstadoSolicitudServicio / Eliminar ([servicio_tecnico].[EstadoSolicitudServicio])
CREATE PROCEDURE [servicio_tecnico].[pa_EstadoSolicitudServicio_Eliminar]
    @IdEstadoSolicitudServicio INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [servicio_tecnico].[EstadoSolicitudServicio] WHERE [IdEstadoSolicitudServicio]=@IdEstadoSolicitudServicio;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- SolicitudServicio / Crear ([servicio_tecnico].[SolicitudServicio])
CREATE PROCEDURE [servicio_tecnico].[pa_SolicitudServicio_Crear]
    @IdCliente INT,
    @IdEquipo INT,
    @IdEstadoSolicitudServicio INT,
    @IdUsuarioCreador INT,
    @FechaSolicitud DATE = NULL,
    @DescripcionProblema NVARCHAR(400) = NULL,
    @Diagnostico NVARCHAR(400) = NULL,
    @IdUsuarioTecnicoAsignado INT = NULL,
    @FechaAtencionProgramada DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM catalogos.Equipo WHERE IdEquipo=@IdEquipo AND IdCliente=@IdCliente) THROW 52040,N'El equipo no pertenece al cliente.',1;
    INSERT INTO [servicio_tecnico].[SolicitudServicio] ([IdCliente], [IdEquipo], [IdEstadoSolicitudServicio], [IdUsuarioCreador], [FechaSolicitud], [DescripcionProblema], [Diagnostico], [IdUsuarioTecnicoAsignado], [FechaAtencionProgramada]) VALUES (@IdCliente, @IdEquipo, @IdEstadoSolicitudServicio, @IdUsuarioCreador, COALESCE(@FechaSolicitud, CAST(GETDATE() AS DATE)), @DescripcionProblema, @Diagnostico, @IdUsuarioTecnicoAsignado, @FechaAtencionProgramada);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [servicio_tecnico].[SolicitudServicio] WHERE [IdSolicitudServicio]=@IdentificadorNuevo;
END;
GO

-- SolicitudServicio / ObtenerPorId ([servicio_tecnico].[SolicitudServicio])
CREATE PROCEDURE [servicio_tecnico].[pa_SolicitudServicio_ObtenerPorId]
    @IdSolicitudServicio INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [servicio_tecnico].[SolicitudServicio] WHERE [IdSolicitudServicio]=@IdSolicitudServicio;
END;
GO

-- SolicitudServicio / Listar ([servicio_tecnico].[SolicitudServicio])
CREATE PROCEDURE [servicio_tecnico].[pa_SolicitudServicio_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [servicio_tecnico].[SolicitudServicio] ORDER BY [IdSolicitudServicio] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- SolicitudServicio / Actualizar ([servicio_tecnico].[SolicitudServicio])
CREATE PROCEDURE [servicio_tecnico].[pa_SolicitudServicio_Actualizar]
    @IdSolicitudServicio INT,
    @IdCliente INT,
    @IdEquipo INT,
    @FechaSolicitud DATE,
    @DescripcionProblema NVARCHAR(400),
    @Diagnostico NVARCHAR(400),
    @IdUsuarioTecnicoAsignado INT,
    @FechaAtencionProgramada DATE,
    @IdEstadoSolicitudServicio INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM catalogos.Equipo WHERE IdEquipo=@IdEquipo AND IdCliente=@IdCliente) THROW 52040,N'El equipo no pertenece al cliente.',1;
    UPDATE [servicio_tecnico].[SolicitudServicio] SET [IdCliente]=@IdCliente, [IdEquipo]=@IdEquipo, [FechaSolicitud]=@FechaSolicitud, [DescripcionProblema]=@DescripcionProblema, [Diagnostico]=@Diagnostico, [IdUsuarioTecnicoAsignado]=@IdUsuarioTecnicoAsignado, [FechaAtencionProgramada]=@FechaAtencionProgramada, [IdEstadoSolicitudServicio]=@IdEstadoSolicitudServicio WHERE [IdSolicitudServicio]=@IdSolicitudServicio;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [servicio_tecnico].[SolicitudServicio] WHERE [IdSolicitudServicio]=@IdSolicitudServicio;
END;
GO

-- SolicitudServicio / Eliminar ([servicio_tecnico].[SolicitudServicio])
CREATE PROCEDURE [servicio_tecnico].[pa_SolicitudServicio_Eliminar]
    @IdSolicitudServicio INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdCancelada INT=(SELECT IdEstadoSolicitudServicio FROM servicio_tecnico.EstadoSolicitudServicio WHERE NombreEstado=N'Cancelada');
    UPDATE [servicio_tecnico].[SolicitudServicio] SET IdEstadoSolicitudServicio=@IdCancelada WHERE [IdSolicitudServicio]=@IdSolicitudServicio;
    IF @@ROWCOUNT=0 THROW 52004,N'No se encontró la solicitud.',1;
    SELECT * FROM [servicio_tecnico].[SolicitudServicio] WHERE [IdSolicitudServicio]=@IdSolicitudServicio;
END;
GO

-- EstadoOrdenTrabajo / Crear ([servicio_tecnico].[EstadoOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_EstadoOrdenTrabajo_Crear]
    @NombreEstado NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [servicio_tecnico].[EstadoOrdenTrabajo] ([NombreEstado]) VALUES (@NombreEstado);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [servicio_tecnico].[EstadoOrdenTrabajo] WHERE [IdEstadoOrdenTrabajo]=@IdentificadorNuevo;
END;
GO

-- EstadoOrdenTrabajo / ObtenerPorId ([servicio_tecnico].[EstadoOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_EstadoOrdenTrabajo_ObtenerPorId]
    @IdEstadoOrdenTrabajo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [servicio_tecnico].[EstadoOrdenTrabajo] WHERE [IdEstadoOrdenTrabajo]=@IdEstadoOrdenTrabajo;
END;
GO

-- EstadoOrdenTrabajo / Listar ([servicio_tecnico].[EstadoOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_EstadoOrdenTrabajo_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [servicio_tecnico].[EstadoOrdenTrabajo] ORDER BY [IdEstadoOrdenTrabajo] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- EstadoOrdenTrabajo / Actualizar ([servicio_tecnico].[EstadoOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_EstadoOrdenTrabajo_Actualizar]
    @IdEstadoOrdenTrabajo INT,
    @NombreEstado NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [servicio_tecnico].[EstadoOrdenTrabajo] SET [NombreEstado]=@NombreEstado WHERE [IdEstadoOrdenTrabajo]=@IdEstadoOrdenTrabajo;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [servicio_tecnico].[EstadoOrdenTrabajo] WHERE [IdEstadoOrdenTrabajo]=@IdEstadoOrdenTrabajo;
END;
GO

-- EstadoOrdenTrabajo / Eliminar ([servicio_tecnico].[EstadoOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_EstadoOrdenTrabajo_Eliminar]
    @IdEstadoOrdenTrabajo INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [servicio_tecnico].[EstadoOrdenTrabajo] WHERE [IdEstadoOrdenTrabajo]=@IdEstadoOrdenTrabajo;
    IF @@ROWCOUNT=0 THROW 52009,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- OrdenTrabajo / Crear ([servicio_tecnico].[OrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_OrdenTrabajo_Crear]
    @IdSolicitudServicio INT,
    @IdEstadoOrdenTrabajo INT,
    @IdUsuarioResponsable INT = NULL,
    @FechaAtencion DATETIME2(0) = NULL,
    @Observaciones NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM servicio_tecnico.EstadoOrdenTrabajo WHERE IdEstadoOrdenTrabajo=@IdEstadoOrdenTrabajo AND NombreEstado IN (N'Cerrada',N'Cancelada')) THROW 52046,N'La orden debe comenzar abierta o en proceso.',1;
    INSERT INTO [servicio_tecnico].[OrdenTrabajo] ([IdSolicitudServicio], [IdEstadoOrdenTrabajo], [IdUsuarioResponsable], [FechaAtencion], [Observaciones]) VALUES (@IdSolicitudServicio, @IdEstadoOrdenTrabajo, @IdUsuarioResponsable, @FechaAtencion, @Observaciones);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [servicio_tecnico].[OrdenTrabajo] WHERE [IdOrdenTrabajo]=@IdentificadorNuevo;
END;
GO

-- OrdenTrabajo / ObtenerPorId ([servicio_tecnico].[OrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_OrdenTrabajo_ObtenerPorId]
    @IdOrdenTrabajo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [servicio_tecnico].[OrdenTrabajo] WHERE [IdOrdenTrabajo]=@IdOrdenTrabajo;
END;
GO

-- OrdenTrabajo / Listar ([servicio_tecnico].[OrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_OrdenTrabajo_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [servicio_tecnico].[OrdenTrabajo] ORDER BY [IdOrdenTrabajo] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- OrdenTrabajo / Actualizar ([servicio_tecnico].[OrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_OrdenTrabajo_Actualizar]
    @IdOrdenTrabajo INT,
    @IdSolicitudServicio INT,
    @IdEstadoOrdenTrabajo INT,
    @IdUsuarioResponsable INT,
    @FechaAtencion DATETIME2(0),
    @Observaciones NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM servicio_tecnico.OrdenTrabajo WHERE IdOrdenTrabajo=@IdOrdenTrabajo AND FechaCierre IS NOT NULL) THROW 52028,N'No se edita una orden cerrada.',1;
    IF EXISTS(SELECT 1 FROM servicio_tecnico.EstadoOrdenTrabajo WHERE IdEstadoOrdenTrabajo=@IdEstadoOrdenTrabajo AND NombreEstado=N'Cerrada') THROW 52029,N'Para cerrar una orden use servicio_tecnico.pa_CerrarOrdenTrabajo.',1;
    UPDATE [servicio_tecnico].[OrdenTrabajo] SET [IdSolicitudServicio]=@IdSolicitudServicio, [IdEstadoOrdenTrabajo]=@IdEstadoOrdenTrabajo, [IdUsuarioResponsable]=@IdUsuarioResponsable, [FechaAtencion]=@FechaAtencion, [Observaciones]=@Observaciones WHERE [IdOrdenTrabajo]=@IdOrdenTrabajo;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [servicio_tecnico].[OrdenTrabajo] WHERE [IdOrdenTrabajo]=@IdOrdenTrabajo;
END;
GO

-- OrdenTrabajo / Eliminar ([servicio_tecnico].[OrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_OrdenTrabajo_Eliminar]
    @IdOrdenTrabajo INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM servicio_tecnico.OrdenTrabajo WHERE IdOrdenTrabajo=@IdOrdenTrabajo AND FechaCierre IS NOT NULL) THROW 52032,N'Una orden cerrada no se puede cancelar.',1;
    DECLARE @IdCancelada INT=(SELECT IdEstadoOrdenTrabajo FROM servicio_tecnico.EstadoOrdenTrabajo WHERE NombreEstado=N'Cancelada');
    UPDATE [servicio_tecnico].[OrdenTrabajo] SET IdEstadoOrdenTrabajo=@IdCancelada WHERE [IdOrdenTrabajo]=@IdOrdenTrabajo;
    IF @@ROWCOUNT=0 THROW 52003,N'No se encontró la orden.',1;
    SELECT * FROM [servicio_tecnico].[OrdenTrabajo] WHERE [IdOrdenTrabajo]=@IdOrdenTrabajo;
END;
GO

-- AvanceOrdenTrabajo / Crear ([servicio_tecnico].[AvanceOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_AvanceOrdenTrabajo_Crear]
    @IdOrdenTrabajo INT,
    @Observaciones NVARCHAR(400),
    @IdUsuarioRegistro INT,
    @MinutosTrabajados INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM servicio_tecnico.OrdenTrabajo ot JOIN servicio_tecnico.EstadoOrdenTrabajo e ON e.IdEstadoOrdenTrabajo=ot.IdEstadoOrdenTrabajo WHERE ot.IdOrdenTrabajo=@IdOrdenTrabajo AND ot.FechaCierre IS NULL AND ot.FechaAplicacionInventario IS NULL AND e.NombreEstado NOT IN (N'Cerrada',N'Cancelada')) THROW 52054,N'No se puede agregar información a órdenes cerradas o canceladas.',1;
    INSERT INTO [servicio_tecnico].[AvanceOrdenTrabajo] ([IdOrdenTrabajo], [Observaciones], [IdUsuarioRegistro], [MinutosTrabajados]) VALUES (@IdOrdenTrabajo, @Observaciones, @IdUsuarioRegistro, @MinutosTrabajados);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [servicio_tecnico].[AvanceOrdenTrabajo] WHERE [IdAvanceOrdenTrabajo]=@IdentificadorNuevo;
END;
GO

-- AvanceOrdenTrabajo / ObtenerPorId ([servicio_tecnico].[AvanceOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_AvanceOrdenTrabajo_ObtenerPorId]
    @IdAvanceOrdenTrabajo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [servicio_tecnico].[AvanceOrdenTrabajo] WHERE [IdAvanceOrdenTrabajo]=@IdAvanceOrdenTrabajo;
END;
GO

-- AvanceOrdenTrabajo / Listar ([servicio_tecnico].[AvanceOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_AvanceOrdenTrabajo_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [servicio_tecnico].[AvanceOrdenTrabajo] ORDER BY [IdAvanceOrdenTrabajo] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- AvanceOrdenTrabajo / Actualizar ([servicio_tecnico].[AvanceOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_AvanceOrdenTrabajo_Actualizar]
    @IdAvanceOrdenTrabajo INT,
    @IdOrdenTrabajo INT,
    @Observaciones NVARCHAR(400),
    @MinutosTrabajados INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM servicio_tecnico.AvanceOrdenTrabajo d JOIN servicio_tecnico.OrdenTrabajo o ON o.IdOrdenTrabajo=d.IdOrdenTrabajo WHERE d.IdAvanceOrdenTrabajo=@IdAvanceOrdenTrabajo AND (o.FechaCierre IS NOT NULL OR o.FechaAplicacionInventario IS NOT NULL)) THROW 52022,N'No se puede alterar una orden cerrada.',1;
    IF NOT EXISTS(SELECT 1 FROM servicio_tecnico.OrdenTrabajo o JOIN servicio_tecnico.EstadoOrdenTrabajo e ON e.IdEstadoOrdenTrabajo=o.IdEstadoOrdenTrabajo WHERE o.IdOrdenTrabajo=@IdOrdenTrabajo AND o.FechaCierre IS NULL AND o.FechaAplicacionInventario IS NULL AND e.NombreEstado NOT IN (N'Cerrada',N'Cancelada')) THROW 52054,N'La orden destino está cerrada o cancelada.',1;
    UPDATE [servicio_tecnico].[AvanceOrdenTrabajo] SET [IdOrdenTrabajo]=@IdOrdenTrabajo, [Observaciones]=@Observaciones, [MinutosTrabajados]=@MinutosTrabajados WHERE [IdAvanceOrdenTrabajo]=@IdAvanceOrdenTrabajo;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [servicio_tecnico].[AvanceOrdenTrabajo] WHERE [IdAvanceOrdenTrabajo]=@IdAvanceOrdenTrabajo;
END;
GO

-- AvanceOrdenTrabajo / Eliminar ([servicio_tecnico].[AvanceOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_AvanceOrdenTrabajo_Eliminar]
    @IdAvanceOrdenTrabajo INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM servicio_tecnico.AvanceOrdenTrabajo d JOIN servicio_tecnico.OrdenTrabajo o ON o.IdOrdenTrabajo=d.IdOrdenTrabajo WHERE d.IdAvanceOrdenTrabajo=@IdAvanceOrdenTrabajo AND o.FechaCierre IS NOT NULL) THROW 52035,N'No se elimina información de una orden cerrada.',1;
    DELETE FROM [servicio_tecnico].[AvanceOrdenTrabajo] WHERE [IdAvanceOrdenTrabajo]=@IdAvanceOrdenTrabajo;
    IF @@ROWCOUNT=0 THROW 52007,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO

-- RepuestoOrdenTrabajo / Crear ([servicio_tecnico].[RepuestoOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_RepuestoOrdenTrabajo_Crear]
    @IdOrdenTrabajo INT,
    @IdArticulo INT,
    @Cantidad INT,
    @CostoUnitarioAlUso DECIMAL(18,2),
    @Observaciones NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM catalogos.Articulo a JOIN catalogos.TipoArticulo t ON t.IdTipoArticulo=a.IdTipoArticulo WHERE a.IdArticulo=@IdArticulo AND t.NombreTipo IN (N'Repuesto',N'Consumible')) THROW 52055,N'La orden solo admite repuestos o consumibles en este detalle.',1;
    IF NOT EXISTS(SELECT 1 FROM servicio_tecnico.OrdenTrabajo ot JOIN servicio_tecnico.EstadoOrdenTrabajo e ON e.IdEstadoOrdenTrabajo=ot.IdEstadoOrdenTrabajo WHERE ot.IdOrdenTrabajo=@IdOrdenTrabajo AND ot.FechaCierre IS NULL AND ot.FechaAplicacionInventario IS NULL AND e.NombreEstado NOT IN (N'Cerrada',N'Cancelada')) THROW 52054,N'No se puede agregar información a órdenes cerradas o canceladas.',1;
    INSERT INTO [servicio_tecnico].[RepuestoOrdenTrabajo] ([IdOrdenTrabajo], [IdArticulo], [Cantidad], [CostoUnitarioAlUso], [Observaciones]) VALUES (@IdOrdenTrabajo, @IdArticulo, @Cantidad, @CostoUnitarioAlUso, @Observaciones);
    DECLARE @IdentificadorNuevo INT = CONVERT(INT, SCOPE_IDENTITY());
    SELECT * FROM [servicio_tecnico].[RepuestoOrdenTrabajo] WHERE [IdRepuestoOrdenTrabajo]=@IdentificadorNuevo;
END;
GO

-- RepuestoOrdenTrabajo / ObtenerPorId ([servicio_tecnico].[RepuestoOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_RepuestoOrdenTrabajo_ObtenerPorId]
    @IdRepuestoOrdenTrabajo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [servicio_tecnico].[RepuestoOrdenTrabajo] WHERE [IdRepuestoOrdenTrabajo]=@IdRepuestoOrdenTrabajo;
END;
GO

-- RepuestoOrdenTrabajo / Listar ([servicio_tecnico].[RepuestoOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_RepuestoOrdenTrabajo_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [servicio_tecnico].[RepuestoOrdenTrabajo] ORDER BY [IdRepuestoOrdenTrabajo] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- RepuestoOrdenTrabajo / Actualizar ([servicio_tecnico].[RepuestoOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_RepuestoOrdenTrabajo_Actualizar]
    @IdRepuestoOrdenTrabajo INT,
    @IdOrdenTrabajo INT,
    @IdArticulo INT,
    @Cantidad INT,
    @CostoUnitarioAlUso DECIMAL(18,2),
    @Observaciones NVARCHAR(250)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM servicio_tecnico.RepuestoOrdenTrabajo d JOIN servicio_tecnico.OrdenTrabajo o ON o.IdOrdenTrabajo=d.IdOrdenTrabajo WHERE d.IdRepuestoOrdenTrabajo=@IdRepuestoOrdenTrabajo AND (o.FechaCierre IS NOT NULL OR o.FechaAplicacionInventario IS NOT NULL)) THROW 52022,N'No se puede alterar una orden cerrada.',1;
    IF NOT EXISTS(SELECT 1 FROM servicio_tecnico.OrdenTrabajo o JOIN servicio_tecnico.EstadoOrdenTrabajo e ON e.IdEstadoOrdenTrabajo=o.IdEstadoOrdenTrabajo WHERE o.IdOrdenTrabajo=@IdOrdenTrabajo AND o.FechaCierre IS NULL AND o.FechaAplicacionInventario IS NULL AND e.NombreEstado NOT IN (N'Cerrada',N'Cancelada')) THROW 52054,N'La orden destino está cerrada o cancelada.',1;
    IF NOT EXISTS(SELECT 1 FROM catalogos.Articulo a JOIN catalogos.TipoArticulo t ON t.IdTipoArticulo=a.IdTipoArticulo WHERE a.IdArticulo=@IdArticulo AND t.NombreTipo IN (N'Repuesto',N'Consumible')) THROW 52055,N'El artículo no es un repuesto o consumible.',1;
    UPDATE [servicio_tecnico].[RepuestoOrdenTrabajo] SET [IdOrdenTrabajo]=@IdOrdenTrabajo, [IdArticulo]=@IdArticulo, [Cantidad]=@Cantidad, [CostoUnitarioAlUso]=@CostoUnitarioAlUso, [Observaciones]=@Observaciones WHERE [IdRepuestoOrdenTrabajo]=@IdRepuestoOrdenTrabajo;
    IF @@ROWCOUNT=0 THROW 52002,N'No se encontró el registro.',1;
    SELECT * FROM [servicio_tecnico].[RepuestoOrdenTrabajo] WHERE [IdRepuestoOrdenTrabajo]=@IdRepuestoOrdenTrabajo;
END;
GO

-- RepuestoOrdenTrabajo / Eliminar ([servicio_tecnico].[RepuestoOrdenTrabajo])
CREATE PROCEDURE [servicio_tecnico].[pa_RepuestoOrdenTrabajo_Eliminar]
    @IdRepuestoOrdenTrabajo INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM servicio_tecnico.RepuestoOrdenTrabajo d JOIN servicio_tecnico.OrdenTrabajo o ON o.IdOrdenTrabajo=d.IdOrdenTrabajo WHERE d.IdRepuestoOrdenTrabajo=@IdRepuestoOrdenTrabajo AND o.FechaCierre IS NOT NULL) THROW 52035,N'No se elimina información de una orden cerrada.',1;
    DELETE FROM [servicio_tecnico].[RepuestoOrdenTrabajo] WHERE [IdRepuestoOrdenTrabajo]=@IdRepuestoOrdenTrabajo;
    IF @@ROWCOUNT=0 THROW 52007,N'No se encontró el registro.',1;
    SELECT CAST(1 AS BIT) AS Eliminado;
END;
GO


-- LecturaMensual / Crear ([operaciones].[LecturaMensual])
CREATE PROCEDURE [operaciones].[pa_LecturaMensual_Crear]
    @IdEquipoContratoAlquiler INT,
    @AnioLectura SMALLINT,
    @MesLectura TINYINT,
    @ValorLectura BIGINT,
    @IdUsuarioLectura INT,
    @Observaciones NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC operaciones.pa_RegistrarLecturaMensual @IdEquipoContratoAlquiler=@IdEquipoContratoAlquiler, @AnioLectura=@AnioLectura, @MesLectura=@MesLectura, @ValorLectura=@ValorLectura, @IdUsuarioLectura=@IdUsuarioLectura, @Observaciones=@Observaciones;
END;
GO

-- LecturaMensual / ObtenerPorId ([operaciones].[LecturaMensual])
CREATE PROCEDURE [operaciones].[pa_LecturaMensual_ObtenerPorId]
    @IdLecturaMensual INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [operaciones].[LecturaMensual] WHERE [IdLecturaMensual]=@IdLecturaMensual;
END;
GO

-- LecturaMensual / Listar ([operaciones].[LecturaMensual])
CREATE PROCEDURE [operaciones].[pa_LecturaMensual_Listar]
    @Pagina INT = 1,
    @TamanoPagina INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @Pagina < 1 OR @TamanoPagina < 1 OR @TamanoPagina > 500 THROW 52000, N'Paginación inválida (máximo 500 registros).', 1;
    SELECT * FROM [operaciones].[LecturaMensual] ORDER BY [IdLecturaMensual] OFFSET ((@Pagina-1)*@TamanoPagina) ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

-- LecturaMensual / Actualizar ([operaciones].[LecturaMensual])
CREATE PROCEDURE [operaciones].[pa_LecturaMensual_Actualizar]
    @IdLecturaMensual INT,
    @ValorLectura BIGINT,
    @Observaciones NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC operaciones.pa_CorregirLecturaMensual @IdLecturaMensual=@IdLecturaMensual,@ValorLectura=@ValorLectura,@Observaciones=@Observaciones;
END;
GO

-- LecturaMensual / Eliminar ([operaciones].[LecturaMensual])
CREATE PROCEDURE [operaciones].[pa_LecturaMensual_Eliminar]
    @IdLecturaMensual INT,
    @IdUsuarioResponsable INT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC operaciones.pa_EliminarUltimaLecturaMensual @IdLecturaMensual=@IdLecturaMensual,@IdUsuarioResponsable=@IdUsuarioResponsable;
END;
GO

