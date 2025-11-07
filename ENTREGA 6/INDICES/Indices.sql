--FALTA - CONTINUAR
--Administración / Consorcio
CREATE INDEX IX_Consorcio_IdAdministracion
    ON Consorcio(Id_Administracion);

--Proveedores
CREATE INDEX IX_Proovedor_IdConsorcio
    ON Proovedor(Id_Consorcio);

--Estado Financiero
CREATE INDEX IX_EstadoFinanciero_IdConsorcio
    ON Estado_Financiero(Id_Consorcio);

CREATE INDEX IX_EstadoFinanciero_Periodo
    ON Estado_Financiero(Periodo);

--Gastos Ordinarios
CREATE INDEX IX_GastoOrdinario_IdConsorcio
    ON Gasto_Ordinario(Id_Consorcio);

CREATE INDEX IX_GastoOrdinario_IdTipoGasto
    ON Gasto_Ordinario(Id_Tipo_Gasto);

CREATE INDEX IX_GastoOrdinario_Fecha
    ON Gasto_Ordinario(Fecha);

--Gastos Extraordinarios
CREATE INDEX IX_GastoExtra_IdConsorcio
    ON Gasto_Extraordinario(Id_Consorcio);

CREATE INDEX IX_GastoExtra_IdTipoPago
    ON Gasto_Extraordinario(Id_tipo_pago);

CREATE INDEX IX_GastoExtra_Fecha
    ON Gasto_Extraordinario(Fecha);

--Unidad Funcional / Personas / Relaciones
-- Consultas por consorcio
CREATE INDEX IX_UF_IdConsorcio
    ON Unidad_Funcional(Id_Consorcio);

CREATE INDEX IX_UnidadPersona_IdConsorcio
    ON Unidad_Persona(Id_Consorcio);

CREATE INDEX IX_UnidadPersona_IdPersona
    ON Unidad_Persona(Id_Persona);

CREATE INDEX IX_UnidadPersona_IdTipoRelacion
    ON Unidad_Persona(Id_TipoRelacion);

--Liquidación / Expensa UF
CREATE INDEX IX_LiquidacionMensual_IdConsorcio
    ON Liquidacion_Mensual(Id_Consorcio);

CREATE INDEX IX_LiquidacionMensual_Periodo
    ON Liquidacion_Mensual(Periodo);

--Pagos / Detalle de Pago
CREATE INDEX IX_Pago_IdFormaPago
    ON Pago(Id_Forma_De_Pago);

CREATE INDEX IX_Pago_Fecha
    ON Pago(Fecha);

CREATE INDEX IX_DetallePago_IdPago
    ON Detalle_Pago(Id_Pago);

CREATE INDEX IX_DetallePago_IdDetalleExpensa
    ON Detalle_Pago(Id_Detalle_Expensa);

CREATE INDEX IX_DetallePago_IdTipoIngreso
    ON Detalle_Pago(Id_Tipo_Ingreso);

