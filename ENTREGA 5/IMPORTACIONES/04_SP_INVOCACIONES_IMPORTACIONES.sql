/*
================================================================================
SCRIPT DE EJECUCIÓN DE IMPORTACIONES
Base de Datos: COM5600_G04

IMPORTANTE: 
1. Ejecutar este script EN ORDEN.
2. Asegurarse de que las rutas a los archivos sean correctas.
3. Para OPENROWSET (Excel), el archivo debe estar en una carpeta con
   permisos para el servicio de SQL Server (ej: C:\Temp\Import\).
================================================================================
*/

USE COM5600_G04;
GO

PRINT '--- Iniciando Proceso de Importación de Datos ---';
GO

-- NOTA: Las rutas 'D:\Diego\Downloads...' son de ejemplo.
-- Reemplazar por 'C:\Temp\Import\' o la ruta que corresponda.

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

PRINT '--- Proceso de Importación Finalizado ---';
GO

/*
-- Descomentar para verificar los datos importados --

SELECT * FROM Consorcio;
SELECT * FROM Unidad_Funcional;
SELECT * FROM Persona;
SELECT * FROM Unidad_Persona;
SELECT * FROM Proovedor;
SELECT * FROM Gasto_Ordinario;
SELECT * FROM Pago;
SELECT * FROM Detalle_Pago;
SELECT * FROM Detalle_Expensa_UF WHERE Deuda > 0 OR Pagos_Recibidos_Mes > 0;
SELECT * FROM Persona WHERE SaldoAFavor > 0;

*/