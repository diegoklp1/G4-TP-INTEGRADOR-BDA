/*
=========================================================
-- SCRIPT: 03_CreacionSPsTransaccionales.sql
-- PROPÓSITO: Crea SPs para registrar "eventos" o 
--            transacciones, como la carga de gastos
--            o la asignación de personas.
--
-- AUTORES: (Tu grupo)
-- FECHA: 02/11/2025
-- COMISIÓN: (Tu comisión)
-- GRUPO: (Tu grupo)
=========================================================
*/

USE COM5600_G04;
GO

PRINT '--- Creando SPs Transaccionales ---'
GO

-----------------------------------------------------
-- 1. SP para Asignar Persona a Unidad Funcional
--    (Ej: Asignar un Propietario o Inquilino)
-----------------------------------------------------

IF OBJECT_ID('sp_AsignarPersonaUnidad') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_AsignarPersonaUnidad;
END
GO
CREATE PROCEDURE sp_AsignarPersonaUnidad
    @Id_Consorcio INT,         
    @NroUF VARCHAR(10),      
    @Id_Persona INT,
    @Id_TipoRelacion INT
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        -- Validaciones
        IF NOT EXISTS (SELECT 1 FROM Unidad_Funcional WHERE Id_Consorcio = @Id_Consorcio AND NroUf = @NroUF)
            RAISERROR('La Unidad Funcional %s del consorcio %d no existe.', 16, 1, @NroUF, @Id_Consorcio);
        IF NOT EXISTS (SELECT 1 FROM Persona WHERE Id_Persona = @Id_Persona)
            RAISERROR('La Persona con ID %d no existe.', 16, 1, @Id_Persona);
        IF NOT EXISTS (SELECT 1 FROM TipoRelacionPersonaUnidad WHERE ID_Tipo_Relacion_P_U = @Id_TipoRelacion)
            RAISERROR('El Tipo de Relación con ID %d no existe.', 16, 1, @Id_TipoRelacion);

        BEGIN TRANSACTION;

        -- Paso 1: Damos de baja la relación activa anterior (si existe)
        UPDATE Unidad_Persona
        SET Fecha_Fin = GETDATE()
        WHERE Id_Consorcio = @Id_Consorcio
          AND NroUF = @NroUF 
          AND Id_TipoRelacion = @Id_TipoRelacion 
          AND Fecha_Fin IS NULL;
        
        -- Paso 2: Insertamos la nueva relación activa
        INSERT INTO Unidad_Persona
            (Id_Consorcio, NroUF, Id_Persona, Id_TipoRelacion, Fecha_Inicio, Fecha_Fin)
        VALUES
            (@Id_Consorcio, @NroUF, @Id_Persona, @Id_TipoRelacion, GETDATE(), NULL);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
-----------------------------------------------------
-- 2. SP para Desasignar Persona de Unidad Funcional
--    (Pone Fecha_Fin a una relación)
-----------------------------------------------------

IF OBJECT_ID('sp_DesasignarPersonaUnidad') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_DesasignarPersonaUnidad;
END
GO

CREATE PROCEDURE sp_DesasignarPersonaUnidad
    @ID_U_P INT -- El ID de la tabla Unidad_Persona
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Unidad_Persona
    SET Fecha_Fin = GETDATE()
    WHERE ID_U_P = @ID_U_P AND Fecha_Fin IS NULL;
END
GO

-----------------------------------------------------
-- 3. SP para Registrar Gasto Extraordinario
--    (Este es simple)
-----------------------------------------------------

IF OBJECT_ID('sp_RegistrarGastoExtraordinario') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_RegistrarGastoExtraordinario;
END
GO

CREATE PROCEDURE sp_RegistrarGastoExtraordinario
    @Id_Consorcio INT,
    @Id_tipo_pago INT,
    @detalle_trabajo VARCHAR(120),
    @Nro_Cuotas_Actual SMALLINT,
    @Total_Cuotas SMALLINT,
    @Importe DECIMAL(10,2),
    @Fecha DATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Gasto_Extraordinario
        (Id_Consorcio, Id_tipo_pago, detalle_trabajo, Nro_Cuotas_Actual, Total_Cuotas, Importe, Fecha)
    VALUES
        (@Id_Consorcio, @Id_tipo_pago, @detalle_trabajo, @Nro_Cuotas_Actual, @Total_Cuotas, @Importe, @Fecha);
END
GO


-----------------------------------------------------
-- 4. SP para Registrar Gasto Ordinario (CON HERENCIA)
--    (Este es el SP complejo)
-----------------------------------------------------

IF OBJECT_ID('sp_RegistrarGastoOrdinario') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_RegistrarGastoOrdinario;
END
GO

-- Este SP necesita recibir TODOS los parámetros posibles de todas las tablas hijas
CREATE PROCEDURE sp_RegistrarGastoOrdinario
    -- Parámetros de la tabla PADRE (Gasto_Ordinario)
    @Id_Consorcio INT,
    @Id_Tipo_Gasto INT,
    @Fecha DATE,
    @Importe_Total DECIMAL(10,2),
    @Descripcion VARCHAR(50),
    
    -- Parámetros de Gasto_Administracion
    @Nro_Factura_Admin INT = NULL,
    
    -- Parámetros de Gasto_Seguro
    @Nro_Factura_Seguro INT = NULL,
    @NombreSeguro VARCHAR(50) = NULL,
    
    -- Parámetros de Gasto_General
    @Desc_General VARCHAR(100) = NULL,
    @Nombre_Responsable VARCHAR(60) = NULL,
    @Nro_Factura_General VARCHAR(50) = NULL,
    
    -- Parámetros de Empresa_Limpieza
    @Nombre_Empresa_Limpieza VARCHAR(50) = NULL,
    @Nro_Factura_Limpieza INT = NULL,
    
    -- Parámetros de Gasto_Mantenimiento
    @CBU_Mantenimiento VARCHAR(22) = NULL,
    
    -- Parámetros de Empleado_Limpieza
    @Sueldo_Empleado DECIMAL(10,2) = NULL,
    @Factura_Productos DECIMAL(10,2) = NULL,
    
    -- Parámetros de Gasto_Servicio_Publico
    @Id_Tipo_Servicio INT = NULL,
    @Nombre_Empresa_Servicio VARCHAR(50) = NULL,
    @Nro_Factura_Servicio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdGastoNuevo INT;
    DECLARE @NombreTipoGasto VARCHAR(50);

    -- Buscamos el nombre del Tipo de Gasto para decidir en qué tabla hija insertar
    -- NOTA: Esto asume que los nombres en la tabla Tipo_Gasto son exactos.
    SELECT @NombreTipoGasto = Nombre FROM Tipo_Gasto_Ordinario WHERE Id_Tipo_Gasto = @Id_Tipo_Gasto;

    IF @NombreTipoGasto IS NULL
    BEGIN
        RAISERROR ('El Id_Tipo_Gasto %d no existe.', 16, 1, @Id_Tipo_Gasto);
        RETURN -1;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Insertamos en la tabla PADRE
        INSERT INTO Gasto_Ordinario
            (Id_Consorcio, Id_Tipo_Gasto, Fecha, Importe_Total, Descripcion)
        VALUES
            (@Id_Consorcio, @Id_Tipo_Gasto, @Fecha, @Importe_Total, @Descripcion);
            
        -- Obtenemos el ID recién creado
        SET @IdGastoNuevo = SCOPE_IDENTITY();

        -- 2. Insertamos en la tabla HIJA correspondiente
        -- (Asumimos los nombres de los tipos de gasto)
        
        IF @NombreTipoGasto = 'Administracion'
        BEGIN
            INSERT INTO Gasto_Administracion (Id_gasto, Nro_Factura)
            VALUES (@IdGastoNuevo, @Nro_Factura_Admin);
        END
        ELSE IF @NombreTipoGasto = 'Seguro'
        BEGIN
            INSERT INTO Gasto_Seguro (Id_gasto, Nro_Factura, NombreSeguro)
            VALUES (@IdGastoNuevo, @Nro_Factura_Seguro, @NombreSeguro);
        END
        ELSE IF @NombreTipoGasto = 'Gasto General'
        BEGIN
            INSERT INTO Gasto_General (Id_gasto, Descripcion, Nombre_Responsable, Nro_factura)
            VALUES (@IdGastoNuevo, @Desc_General, @Nombre_Responsable, @Nro_Factura_General);
        END
        ELSE IF @NombreTipoGasto = 'Empresa Limpieza'
        BEGIN
            INSERT INTO Empresa_Limpieza (Id_gasto, Nombre_Empresa, Nro_factura)
            VALUES (@IdGastoNuevo, @Nombre_Empresa_Limpieza, @Nro_Factura_Limpieza);
        END
        ELSE IF @NombreTipoGasto = 'Mantenimiento'
        BEGIN
            INSERT INTO Gasto_Mantenimiento (Id_gasto, CBU)
            VALUES (@IdGastoNuevo, @CBU_Mantenimiento);
        END
        ELSE IF @NombreTipoGasto = 'Empleado Limpieza'
        BEGIN
            INSERT INTO Empleado_Limpieza (Id_gasto, Sueldo, Factura_Productos)
            VALUES (@IdGastoNuevo, @Sueldo_Empleado, @Factura_Productos);
        END
        ELSE IF @NombreTipoGasto = 'Servicio Publico'
        BEGIN
            INSERT INTO Gasto_Servicio_Publico (Id_gasto, Id_Tipo_Servicio, Nombre_Empresa, Nro_Factura)
            VALUES (@IdGastoNuevo, @Id_Tipo_Servicio, @Nombre_Empresa_Servicio, @Nro_Factura_Servicio);
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
			IF @@TRANCOUNT > 0
				    ROLLBACK TRANSACTION;
				
			throw;
	END CATCH
END
GO

PRINT '--- SPs Transaccionales Creados ---'
GO

PRINT '*********************************************************'
PRINT '*** FIN SCRIPT 03_CreacionSPsTransaccionales.sql ***'
PRINT '*********************************************************'
GO