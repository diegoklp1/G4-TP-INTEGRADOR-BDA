---Script de Ejecución
USE COM5600_G04;
GO

--Reporte 1 - Recaudacion Semanal
BEGIN TRY
    EXEC dbo.sp_ReporteRecaudacionSemanal
        @FechaInicio = '2025-01-01',
        @FechaFin = '2025-12-31',
        @IdConsorcio = 1;
END TRY
BEGIN CATCH
    PRINT 'Error en Reporte 1: ' + ERROR_MESSAGE();
END CATCH;
GO
---

--Reporte 2 - Recaudacion Mensual Departamento
BEGIN TRY
	EXEC dbo.sp_ReporteRecaudacionMensualDepartamento
		@FechaInicio = '2025-01-01',
		@FechaFin = '2025-12-31',
		@IdConsorcio = 1;
END TRY
BEGIN CATCH
    PRINT 'Error en Reporte 2: ' + ERROR_MESSAGE();
END CATCH;
GO
---

--Reporte3
BEGIN TRY
	EXEC dbo.sp_ReporteRecaudacionPorTipo
		@FechaInicio = '2025-01-01',
		@FechaFin = '2025-12-31',
		@IdConsorcio = 1;
END TRY
BEGIN CATCH
    PRINT 'Error en Reporte 3: ' + ERROR_MESSAGE();
END CATCH;
GO
---

--Reporte 4 - Top Meses Ingresos Gastos
BEGIN TRY
	EXEC dbo.sp_ReporteTopMesesIngresosGastos 
		@IdConsorcio = 1, 
		@IdTipoGasto = NULL,  -- o un ID específico
		@Anio = 2025;
END TRY
BEGIN CATCH
    PRINT 'Error en Reporte 4: ' + ERROR_MESSAGE();
END CATCH;
GO
---

--Reporte 5 - Top 3 Morosos
BEGIN TRY
	EXEC dbo.sp_ReporteTop3MorososPorConsorcioPisoAnio 
		 @Id_Consorcio = 1,
		 @Piso = '2',
		 @Anio = 2024;
END TRY
BEGIN CATCH
    PRINT 'Error en Reporte 5: ' + ERROR_MESSAGE();
END CATCH;
GO
---

--Reporte 6 - Intervalo Pagos Ordinarios
BEGIN TRY
	EXEC dbo.sp_ReporteIntervaloPagosOrdinarios
		@FechaInicio = '2025-01-01',
		@FechaFin = '2025-12-31',
		@IdConsorcio = 1;
END TRY
BEGIN CATCH
    PRINT 'Error en Reporte 6: ' + ERROR_MESSAGE();
END CATCH;
GO
---
