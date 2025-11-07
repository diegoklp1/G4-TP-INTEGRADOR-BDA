/*
=========================================================
-- SCRIPT: 05_CreacionSPsCatalogos.sql
-- PROPÓSITO: Crea SPs de Lectura para todas las 
--            tablas de "tipos" (catálogos).
--
-- Fecha de entrega:	07/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387
=========================================================
*/

USE COM5600_G04;
GO

PRINT '--- Creando SPs de Catálogos ---'
GO

-----------------------------------
-- Para Tabla Tipo_Gasto_Ordinario
-----------------------------------
IF OBJECT_ID('sp_ListarTiposGastoOrdinario') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ListarTiposGastoOrdinario;
END
GO

CREATE PROCEDURE sp_ListarTiposGastoOrdinario
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        SELECT Id_Tipo_Gasto, Nombre 
        FROM Tipo_Gasto_Ordinario 
        ORDER BY Nombre;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-------------------------------
-- Para Tabla Tipo_Servicio
-------------------------------
IF OBJECT_ID('sp_ListarTiposServicio') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ListarTiposServicio;
END
GO

CREATE PROCEDURE sp_ListarTiposServicio
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        SELECT Id_Tipo_Servicio, Nombre 
        FROM Tipo_Servicio 
        ORDER BY Nombre;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

---------------------------------------
-- Para Tabla TipoRelacionPersonaUnidad
---------------------------------------
IF OBJECT_ID('sp_ListarTipoRelacionPersonaUnidad') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ListarTipoRelacionPersonaUnidad;
END
GO

CREATE PROCEDURE sp_ListarTipoRelacionPersonaUnidad
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        SELECT ID_Tipo_Relacion_P_U, Nombre 
        FROM TipoRelacionPersonaUnidad 
        ORDER BY Nombre;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-------------------------------
-- Para Tabla Forma_De_Pago
-------------------------------
IF OBJECT_ID('sp_ListarFormasDePago') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ListarFormasDePago;
END
GO

CREATE PROCEDURE sp_ListarFormasDePago
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        SELECT Id_Forma_De_Pago, Nombre 
        FROM Forma_De_Pago 
        ORDER BY Nombre;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-------------------------------
-- Para Tabla Tipo_ingreso
-------------------------------
IF OBJECT_ID('sp_ListarTipo_ingreso') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ListarTipo_ingreso;
END
GO

CREATE PROCEDURE sp_ListarTipo_ingreso
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        SELECT Id_Tipo_Ingreso, Nombre 
        FROM Tipo_ingreso 
        ORDER BY Nombre;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

----------------------------------------
-- Para Tabla Tipo_Pago_Extraordinario
----------------------------------------
IF OBJECT_ID('sp_ListarTipo_Pago_Extraordinario') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ListarTipo_Pago_Extraordinario;
END
GO

CREATE PROCEDURE sp_ListarTipo_Pago_Extraordinario
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        SELECT Id_tipo_pago, Nombre 
        FROM Tipo_Pago_Extraordinario 
        ORDER BY Nombre;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '--- SPs de Catálogos Creados ---'
GO
