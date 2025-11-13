USE COM5600_G04;
GO

--Pago
CREATE NONCLUSTERED INDEX IX_Pago
ON Pago (Id_Pago)
INCLUDE (Fecha);

--Detalle Pago
CREATE NONCLUSTERED INDEX IX_Detalle_Pago
ON Detalle_Pago (Id_Detalle_Pago)
INCLUDE (Id_Pago, Id_Detalle_Expensa, Id_Tipo_Ingreso, Importe_Usado);

--Detalle Expensa UF
CREATE NONCLUSTERED INDEX IX_Detalle_Expensa_UF
ON Detalle_Expensa_UF (Id_Detalle_Expensa)
INCLUDE (Id_Expensa, Id_Consorcio, NroUF, Importe_Ordinario_Prorrateado, Importe_Extraordinario_Prorrateado);

--Liquidacion Mensual
CREATE NONCLUSTERED INDEX IX_Liquidacion_Mensual
ON Liquidacion_Mensual (Id_Liquidacion_Mensual)
INCLUDE (Id_Consorcio, Fecha_Vencimiento1, Periodo);

--Unidad Funcional
CREATE NONCLUSTERED INDEX IX_Unidad_Funcional
ON Unidad_Funcional (Id_Consorcio, NroUF)
INCLUDE (Piso, Departamento);

--Tipo Ingreso
CREATE NONCLUSTERED INDEX IX_Tipo_Ingreso
ON Tipo_Ingreso (Id_Tipo_Ingreso)
INCLUDE (Nombre);

--Gasto Ordinario
CREATE NONCLUSTERED INDEX IX_Gasto_Ordinario
ON Gasto_Ordinario (Id_Gasto)
INCLUDE (Id_Tipo_Gasto, Id_Consorcio, Fecha);

--Gasto Extraordinario
CREATE NONCLUSTERED INDEX IX_Gasto_Extraordinario
ON Gasto_Extraordinario (Id_Gasto)
INCLUDE (Id_Consorcio, Id_Tipo_Pago, Fecha);

--Consorcio
CREATE NONCLUSTERED INDEX IX_Consorcio
ON Consorcio (Id_Consorcio)
INCLUDE (Id_Administracion);

--Unidad Persona
CREATE NONCLUSTERED INDEX IX_Unidad_Persona
ON Unidad_Persona (ID_U_P)
INCLUDE (Id_Consorcio, Id_Persona, NroUF, Id_TipoRelacion);

--Persona
CREATE NONCLUSTERED INDEX IX_Persona
ON Persona (Id_Persona)
INCLUDE (DNI);

Go
