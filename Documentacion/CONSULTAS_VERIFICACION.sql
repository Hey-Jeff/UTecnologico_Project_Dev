USE SGC_UniversoTecnologico;
GO
SELECT COUNT(*) AS TotalTablas
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id=t.schema_id
WHERE s.name IN (N'seguridad',N'catalogos',N'inventario',N'comercial',N'servicio_tecnico',N'operaciones');

SELECT COUNT(*) AS TotalProcedimientos
FROM sys.procedures p
JOIN sys.schemas s ON s.schema_id=p.schema_id
WHERE s.name IN (N'seguridad',N'catalogos',N'inventario',N'comercial',N'servicio_tecnico',N'operaciones');

SELECT COUNT(*) AS TotalVistas
FROM sys.views v
JOIN sys.schemas s ON s.schema_id=v.schema_id
WHERE s.name IN (N'catalogos',N'inventario',N'comercial');

EXEC catalogos.pa_Cliente_Listar @Pagina=1,@TamanoPagina=10;
