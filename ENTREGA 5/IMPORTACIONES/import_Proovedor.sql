
USE bd_tp_testeo
GO
IF OBJECT_ID('sp_Importar_Proveedores', 'P') IS NOT NULL
    DROP PROCEDURE sp_Importar_Proveedores;
GO

CREATE PROCEDURE sp_Importar_Proveedores
    @RutaArchivoXLSX VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
	CREATE TABLE #TempProveedores (
		Tipo_gasto VARCHAR(60), 
		Nombre VARCHAR(80),     
		Cuenta VARCHAR(50),     
		NomConsorcio VARCHAR(200)
	);


    BEGIN TRY
        DECLARE @Sql NVARCHAR(MAX);
        
		SET @Sql = N'
			INSERT INTO #TempProveedores 
			(
				Tipo_gasto,
				Nombre,
				Cuenta,
				NomConsorcio
			)
			SELECT 
				[F1], 
				[F2], 
				[F3], 
				[F4]
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.16.0'',
				''Excel 12.0 Xml;Database=' + @RutaArchivoXLSX + ';HDR=NO;IMEX=1'', 
				''SELECT * FROM [Proveedores$]''
			)
			WHERE NOT ([F1] IS NULL AND [F2] IS NULL AND [F3] IS NULL AND [F4] IS NULL)
			  AND [F4] <> ''Nombre del consorcio''
		';

        
        EXEC sp_executesql @Sql;

        -- TRANSFORMACIÓN DE DATOS (ETL)

        -- Borramos las filas de basura (títulos y encabezados)
        DELETE FROM #TempProveedores 
        WHERE Tipo_gasto = 'Tipo gasto' OR Tipo_gasto IS NULL OR LTRIM(RTRIM(Tipo_gasto)) = '';

        -- (El resto de tu lógica ETL ahora funcionará)
        ALTER TABLE #TempProveedores ADD Id_Consorcio INT;

        DELETE FROM #TempProveedores 
        WHERE NomConsorcio IS NULL OR Tipo_gasto IS NULL  OR LTRIM(RTRIM(NomConsorcio)) = '';

        UPDATE T 
        SET T.Id_Consorcio = C.Id_Consorcio 
        FROM #TempProveedores AS T 
        JOIN Consorcio AS C ON UPPER(LTRIM(RTRIM(T.NomConsorcio))) = C.Nombre;
        
        DELETE FROM #TempProveedores WHERE Id_Consorcio IS NULL;
        
        UPDATE #TempProveedores 
        SET Nombre = LTRIM(RTRIM(Nombre)),
            Cuenta = LTRIM(RTRIM(Cuenta)),
            Tipo_gasto = LTRIM(RTRIM(Tipo_gasto));

        MERGE INTO Proovedor AS T
        USING (
            SELECT DISTINCT 
                Tipo_gasto,
                Nombre,
                Cuenta, 
                Id_Consorcio
            FROM #TempProveedores
            WHERE Id_Consorcio IS NOT NULL
              AND Nombre IS NOT NULL 
        ) AS S
        ON (T.Id_Consorcio = S.Id_Consorcio AND T.Nombre_Gasto = S.Nombre)
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (Id_Consorcio, Nombre_Gasto, Descripcion, Cuenta)
            VALUES (S.Id_Consorcio, S.Nombre, S.Tipo_gasto, S.Cuenta)
        WHEN MATCHED THEN
            UPDATE SET
                T.Descripcion = S.Tipo_gasto,
                T.Cuenta = S.Cuenta;
        
        PRINT 'Importación de Proveedores (XLSX) completada.';

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo importar el archivo XLSX de Proveedores.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
        
    DROP TABLE #TempProveedores;
    SET NOCOUNT OFF;
END
GO

EXEC sp_Importar_Proveedores
    @RutaArchivoXLSX = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\ARCHIVOS\datos varios.xlsx';
GO


SELECT * FROM Consorcio;
SELECT * FROM Proovedor;
GO



select * from Proovedor
select * from Gasto_Ordinario