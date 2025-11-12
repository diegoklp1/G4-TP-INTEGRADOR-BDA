---Script de Ejecución
--Reporte1
EXEC sp_ReporteRecaudacionSemanal
    @FechaInicio = '2025-01-01',
    @FechaFin = '2025-12-31',
    @IdConsorcio = 1;
---

--Reporte2
EXEC sp_reporte_recaudacion_mensual_departamento
    @FechaInicio = '2025-01-01',
    @FechaFin = '2025-12-31',
    @IdConsorcio = 1;
---

--Reporte3
EXEC sp_reporte_recaudacion_por_tipo
    @FechaInicio = '2025-01-01',
    @FechaFin = '2025-12-31',
    @IdConsorcio = 1;
---

--Reporte4
EXEC sp_top_meses_ingresos_gastos 
    @IdConsorcio = 1, 
    @IdTipoGasto = NULL,  -- o un ID específico
    @Anio = 2025;

---

--Reporte5
EXEC sp_Top3MorososPorConsorcioPisoAnio 
     @Id_Consorcio = 1,
     @Piso = '2',
     @Anio = 2024;
---

--Reporte6
EXEC sp_intervalo_pagos_ordinarios
    @FechaInicio = '2025-01-01',
    @FechaFin = '2025-12-31',
    @IdConsorcio = 1;
---
