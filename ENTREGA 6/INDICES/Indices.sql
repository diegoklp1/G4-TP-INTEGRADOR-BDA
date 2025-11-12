---Reporte 1 y 2
CREATE NONCLUSTERED INDEX IX_Pago ON Pago (
Id_Pago, Fecha);
CREATE NONCLUSTERED INDEX IX_Detalle_Pago ON Detalle_Pago (
Id_Pago, Id_Detalle_Expensa, Importe_Usado, Id_Tipo_Ingreso);
CREATE NONCLUSTERED INDEX IX_Detalle_Expensa_UF ON Detalle_Expensa_UF (
Id_Detalle_Expensa, Id_Expensa, Id_Consorcio, NroUF, Importe_Ordinario_Prorrateado, Importe_Extraordinario_Prorrateado);
CREATE NONCLUSTERED INDEX IX_Liquidacion_Mensual ON Liquidacion_Mensual (
Id_Liquidacion_Mensual, Id_Consorcio, Fecha_Vencimiento1, Periodo);
--Reporte 2
CREATE NONCLUSTERED INDEX IX_Unidad_Funcional ON Unidad_Funcional (
Id_Consorcio, Piso, NroUF, Departamento);

--Reporte 3
CREATE NONCLUSTERED INDEX IX_Tipo_Ingreso ON Tipo_Ingreso (
Id_Tipo_Ingreso, Nombre);

--Reporte 4
CREATE NONCLUSTERED INDEX IX_Gasto_Ordinario ON Gasto_Ordinario (
Id_Consorcio, Id_Tipo_Gasto, Fecha);
CREATE NONCLUSTERED INDEX IX_Gasto_Extraordinario ON Gasto_Extraordinario (
Id_Consorcio, Fecha);

--Reporte 5
CREATE NONCLUSTERED INDEX IX_Consorcio ON Consorcio (Id_Consorcio);
CREATE NONCLUSTERED INDEX IX_Unidad_Persona ON Consorcio (Id_Consorcio, Id_Persona, NroUF);
CREATE NONCLUSTERED INDEX IX_Persona ON Persona (Id_Persona, NroUF);
