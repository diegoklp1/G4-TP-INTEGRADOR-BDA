-- =============================================================
-- SCRIPT: 01_SP_DATOSINICIALES.sql
-- PROPOSITO: Insertar los datos iniciales basicos en las tablas.

-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =============================================================

-- DATOS DE PRUEBA INICIALES

USE COM5600_G04
GO
-- DATOS DE ADMINSISTRACION
INSERT INTO [negocio].[Administracion] (
    Razon_Social,
    CUIT,
    Direccion,
    Telefono,
    Email,
    Cuenta_Deposito,
	Precio_Cochera_Default,
	Precio_Baulera_Default
)
VALUES (
    'Administradora de Consorcios BDA', -- Razon_Social
    '30-12345678-9',                   -- CUIT
    'Av. de Mayo 1234, CABA',          -- Direccion
    '11-4567-8901',                    -- Telefono
    'contacto@admbda.com',             -- Email
    '0170123400001234567890',          -- Cuenta_Deposito (CBU de 22 digitos)
	1000,
	1000
);
GO
-- Insertamos los tipos de relacion que una persona puede tener con una UF
-- (El ID_Tipo_Relacion_P_U es IDENTITY, por eso no lo especificamos)

INSERT INTO [unidades].[TipoRelacionPersonaUnidad](Nombre) 
VALUES 
    ('Propietario'), 
    ('Inquilino');  
GO

IF NOT EXISTS (SELECT 1 FROM [pagos].[Forma_De_Pago] WHERE Id_Forma_De_Pago = 1)
    INSERT INTO [pagos].[Forma_De_Pago] (Nombre) VALUES ('Transferencia Bancaria');

IF NOT EXISTS (SELECT 1 FROM [pagos].[Forma_De_Pago] WHERE Id_Forma_De_Pago = 2)
    INSERT INTO [pagos].[Forma_De_Pago] (Nombre) VALUES ('Efectivo');

IF NOT EXISTS (SELECT 1 FROM [pagos].[Forma_De_Pago] WHERE Id_Forma_De_Pago = 3)
    INSERT INTO [pagos].[Forma_De_Pago] (Nombre) VALUES ('Debito Automatico');

INSERT INTO [pagos].[Tipo_ingreso] (Id_Tipo_Ingreso,Nombre) VALUES (1,'EN TERMINO');
INSERT INTO [pagos].[Tipo_ingreso] (Id_Tipo_Ingreso,Nombre) VALUES (2,'ADEUDADO');
INSERT INTO [pagos].[Tipo_ingreso] (Id_Tipo_Ingreso,Nombre) VALUES (3,'ADELANTADO');


INSERT INTO [gastos].[Tipo_Gasto_Ordinario] (Nombre) VALUES
('BANCARIOS'),
('LIMPIEZA'),
('ADMINISTRACION'),
('SEGUROS'),
('GASTOS GENERALES'),
('SERVICIOS PUBLICOS');

INSERT INTO [gastos].[Tipo_Servicio] (Nombre) VALUES
('Agua'),
('Luz'),
('Gas'); 

GO
