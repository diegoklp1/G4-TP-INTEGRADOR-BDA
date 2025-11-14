-- =============================================================
-- SCRIPT: 04_SP_INVOCACIONES_IMPORTACIONES.sql
-- PROPOSITO: SCRIPT DE EJECUCION DE IMPORTACIONES
-- Base de Datos: COM5600_G04
-- 
-- IMPORTANTE: 
-- 1. Ejecutar este script EN ORDEN.
-- 2. Asegurarse de que las rutas a los archivos sean correctas.
-- 3. Para OPENROWSET (Excel), el archivo debe estar en una carpeta con
--    permisos para el servicio de SQL Server
-- 
-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =============================================================

USE COM5600_G04;
GO

PRINT '--- Iniciando Proceso de Importacion de Datos ---';
GO

-- 1. Importar Consorcios (Excel)
PRINT '1. Ejecutando sp_Importar_Consorcios...';
EXEC sp_Importar_Consorcios 
    @RutaArchivoXLSX = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\ARCHIVOS\datos varios.xlsx',
    @Id_Adm = 1; -- Asumiendo que el ID de la Admin es 1
GO

-- 2. Importar Unidades Funcionales (CSV)
PRINT '2. Ejecutando sp_Importar_UF...';
EXEC sp_Importar_UnidadesFuncionales 
    @RutaArchivoTXT = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\ARCHIVOS\UF por consorcio.txt';
GO

-- 3. Importar Personas (Inquilinos/Propietarios) (CSV)
PRINT '3. Ejecutando sp_Importar_Personas...';
EXEC sp_Importar_Personas 
    @RutaArchivoCSV = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\ARCHIVOS\Inquilino-propietarios-datos.csv';
GO

-- 4. Vincular Personas con Unidades Funcionales (CSV)
PRINT '4. Ejecutando sp_Importar_UF_Persona...';
EXEC sp_Importar_UF_Persona 
    @RutaArchivoCSV = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\ARCHIVOS\Inquilino-propietarios-UF.csv';
GO

-- 5. Importar Proveedores (Excel)
PRINT '5. Ejecutando sp_Importar_Proveedores...';
EXEC sp_Importar_Proveedores
    @RutaArchivoXLSX = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\ARCHIVOS\datos varios.xlsx';
GO

-- 6. Importar Gastos (JSON)
PRINT '6. Ejecutando sp_Importar_Gastos_JSON...';
EXEC sp_Importar_Gastos_JSON 
    @RutaArchivoJSON = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\ARCHIVOS\Servicios.Servicios.json';
GO

-- 7. Importar y Conciliar Pagos (CSV)
-- (Este SP asume que las Expensas ya fueron generadas)
PRINT '7. Ejecutando sp_Importar_PagosConsorcios...';
EXEC sp_Importar_PagosConsorcios 
    @RutaArchivoCSV = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\ARCHIVOS\pagos_consorcios.csv';
GO

PRINT '--- Proceso de Importacion Finalizado ---';
GO
