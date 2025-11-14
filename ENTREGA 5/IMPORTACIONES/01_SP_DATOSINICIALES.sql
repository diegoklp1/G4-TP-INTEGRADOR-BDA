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
INSERT INTO Administracion (
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

INSERT INTO TipoRelacionPersonaUnidad (Nombre) 
VALUES 
    ('Propietario'), 
    ('Inquilino');  
GO

IF NOT EXISTS (SELECT 1 FROM Forma_De_Pago WHERE Id_Forma_De_Pago = 1)
    INSERT INTO Forma_De_Pago (Nombre) VALUES ('Transferencia Bancaria');

IF NOT EXISTS (SELECT 1 FROM Forma_De_Pago WHERE Id_Forma_De_Pago = 2)
    INSERT INTO Forma_De_Pago (Nombre) VALUES ('Efectivo');

IF NOT EXISTS (SELECT 1 FROM Forma_De_Pago WHERE Id_Forma_De_Pago = 3)
    INSERT INTO Forma_De_Pago (Nombre) VALUES ('Debito Automatico');

INSERT INTO Tipo_ingreso (Id_Tipo_Ingreso,Nombre) VALUES (1,'EN TERMINO');
INSERT INTO Tipo_ingreso (Id_Tipo_Ingreso,Nombre) VALUES (2,'ADEUDADO');
INSERT INTO Tipo_ingreso (Id_Tipo_Ingreso,Nombre) VALUES (3,'ADELANTADO');


INSERT INTO Tipo_Gasto (Nombre) VALUES
('BANCARIOS'),
('LIMPIEZA'),
('ADMINISTRACION'),
('SEGUROS'),
('GASTOS GENERALES'),
('SERVICIOS PUBLICOS');

INSERT INTO Tipo_Servicio (Nombre) VALUES
('Agua'),
('Luz'),
('Gas'); 
GO






-- DESPUES DE IMPORTAR CONSORCIO,GASTOS,UF,UFPERSONA,PERSONA
USE COM5600_G04;




--EXEC sp_Generar_Expensas @IdConsorcio = 1 , @Periodo ='2025-04-01'
--EXEC sp_Generar_Expensas @IdConsorcio = 1 , @Periodo ='2025-05-01'
--EXEC sp_Generar_Expensas @IdConsorcio = 1 , @Periodo ='2025-06-01'


IF OBJECT_ID('sp_Generar_Detalle_Expensas', 'P') IS NOT NULL
    DROP PROCEDURE sp_Generar_Detalle_Expensas;
GO

CREATE PROCEDURE sp_Generar_Detalle_Expensas
    @Id_Liquidacion_Mensual INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Id_Consorcio INT, @Periodo DATE, @TotalOrd DECIMAL(10,2), @TotalExt DECIMAL(10,2);
    DECLARE @PrecioCochera DECIMAL(9,2), @PrecioBaulera DECIMAL(9,2);

    BEGIN TRY
        -- 1. Obtener datos de la liquidacion "padre" y del consorcio
        SELECT 
            @Id_Consorcio = L.Id_Consorcio,
            -- Importante: Convertimos el PERIODO (datetime) a DATE aqui
            @Periodo = CAST(L.Periodo AS DATE),
            @TotalOrd = L.Total_Gasto_Ordinarios,
            @TotalExt = L.Total_Gasto_Extraordinarios,
            @PrecioCochera = C.Precio_Cochera,
            @PrecioBaulera = C.Precio_Baulera
        FROM Liquidacion_Mensual AS L
        JOIN Consorcio AS C ON L.Id_Consorcio = C.Id_Consorcio
        WHERE L.Id_Liquidacion_Mensual = @Id_Liquidacion_Mensual;

        IF @Id_Consorcio IS NULL
        BEGIN
            THROW 50001, 'No se encontro la liquidacion mensual especificada.', 1;
            RETURN;
        END

        -- 2. (Re)generar los detalles
        DELETE FROM Detalle_Expensa_UF WHERE Id_Expensa = @Id_Liquidacion_Mensual;

        -- 3. Insertar todos los detalles de expensas (uno por UF)
        INSERT INTO Detalle_Expensa_UF (
            Id_Expensa, Id_Consorcio, NroUf, Saldo_Anterior, Pagos_Recibidos_Mes,
            Deuda, Interes_Por_Mora, Importe_Ordinario_Prorrateado,
            Importe_Extraordinario_Prorrateado, Total_A_Pagar
        )
        SELECT
            @Id_Liquidacion_Mensual AS Id_Expensa,
            UF.Id_Consorcio, UF.NroUf,
            
            ISNULL(PREV_DET.Total_A_Pagar - PREV_DET.Pagos_Recibidos_Mes, 0) AS Saldo_Anterior,
            0 AS Pagos_Recibidos_Mes,
            ISNULL(PREV_DET.Total_A_Pagar - PREV_DET.Pagos_Recibidos_Mes, 0) AS Deuda,
            ISNULL(PREV_DET.Total_A_Pagar - PREV_DET.Pagos_Recibidos_Mes, 0) * 0.05 AS Interes_Por_Mora,

            (@TotalOrd * UF.Coeficiente / 100) + 
            (CASE WHEN UF.Cochera = 1 THEN @PrecioCochera ELSE 0 END) +
            (CASE WHEN UF.Baulera = 1 THEN @PrecioBaulera ELSE 0 END)
            AS Importe_Ordinario_Prorrateado,

            (@TotalExt * UF.Coeficiente / 100) AS Importe_Extraordinario_Prorrateado,
            
            (ISNULL(PREV_DET.Total_A_Pagar - PREV_DET.Pagos_Recibidos_Mes, 0)) + -- Deuda
            (ISNULL(PREV_DET.Total_A_Pagar - PREV_DET.Pagos_Recibidos_Mes, 0) * 0.05) + -- Interes
            (@TotalOrd * UF.Coeficiente / 100) + 
            (CASE WHEN UF.Cochera = 1 THEN @PrecioCochera ELSE 0 END) +
            (CASE WHEN UF.Baulera = 1 THEN @PrecioBaulera ELSE 0 END) +
            (@TotalExt * UF.Coeficiente / 100)
            AS Total_A_Pagar

        FROM Unidad_Funcional AS UF
        
        -- Buscamos la liquidacion del mes anterior
        LEFT JOIN Liquidacion_Mensual AS PREV_LIQ 
            ON PREV_LIQ.Id_Consorcio = UF.Id_Consorcio
            -- *** LA CORRECCION ESTÁ AQUI ***
            -- Comparamos DATE vs DATE, en lugar de DATETIME vs DATE
            AND CAST(PREV_LIQ.Periodo AS DATE) = DATEADD(MONTH, -1, @Periodo)

        -- Buscamos el detalle de expensa de esa liquidacion anterior
        LEFT JOIN Detalle_Expensa_UF AS PREV_DET
            ON PREV_DET.Id_Expensa = PREV_LIQ.Id_Liquidacion_Mensual
            AND PREV_DET.NroUf = UF.NroUf

        WHERE UF.Id_Consorcio = @Id_Consorcio;

        PRINT 'Detalles de expensas (CORREGIDOS) generados para la liquidacion ID: ' + CAST(@Id_Liquidacion_Mensual AS VARCHAR);

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo generar el detalle de expensas.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO