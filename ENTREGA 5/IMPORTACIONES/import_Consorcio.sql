USE bd_tp_testeo;

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
    '0170123400001234567890',          -- Cuenta_Deposito (CBU de 22 dígitos)
	1000,
	1000
);
GO
USE bd_tp_testeo;
GO
IF OBJECT_ID('sp_Importar_Consorcios', 'P') IS NOT NULL
    DROP PROCEDURE sp_Importar_Consorcios;
GO

CREATE PROCEDURE sp_Importar_Consorcios
    @RutaArchivoXLSX VARCHAR(500),
    @Id_Adm INT
AS
BEGIN
    SET NOCOUNT ON;
    CREATE TABLE #TempConsorcios (
        Consorcio_CSV VARCHAR(100), 
        Nombre_CSV VARCHAR(100),
        Domicilio_CSV VARCHAR(100),
        CantUnidades_CSV INT,
        M2Totales_CSV INT
    );

    BEGIN TRY
        DECLARE @Sql NVARCHAR(MAX);
        
        SET @Sql = N'
            INSERT INTO #TempConsorcios 
            (
                Consorcio_CSV, 
                Nombre_CSV, 
                Domicilio_CSV, 
                CantUnidades_CSV, 
                M2Totales_CSV
            )
            SELECT 
                [Consorcio],
                [Nombre del consorcio],
                [Domicilio],
                [Cant unidades funcionales],
                [M2 totales]
            FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.16.0'',
                ''Excel 12.0;Database=' + @RutaArchivoXLSX+ ';HDR=YES;IMEX=1'',
                ''SELECT * FROM [Consorcios$]'')' 

        EXEC sp_executesql @Sql;

        -- (El resto del ETL y MERGE queda igual)
        ALTER TABLE #TempConsorcios ADD Id_Limpio INT, 
                                       Id_Adm INT, 
                                       Precio_Cochera DECIMAL(9, 2), 
                                       Precio_Baulera DECIMAL(9, 2);
        DELETE FROM #TempConsorcios WHERE Consorcio_CSV IS NULL;
        UPDATE #TempConsorcios 
        SET Id_Limpio = TRY_CONVERT(INT, REPLACE(Consorcio_CSV, 'Consorcio ', ''));
        DELETE FROM #TempConsorcios WHERE Id_Limpio IS NULL;
        UPDATE #TempConsorcios SET Nombre_CSV = UPPER(Nombre_CSV) WHERE Nombre_CSV IS NOT NULL;
        UPDATE #TempConsorcios SET Domicilio_CSV = 'DOMICILIO NO INFORMADO' WHERE Domicilio_CSV IS NULL OR Domicilio_CSV = '';
        UPDATE #TempConsorcios SET CantUnidades_CSV = 0 WHERE CantUnidades_CSV IS NULL;
        UPDATE #TempConsorcios SET M2Totales_CSV = 0 WHERE M2Totales_CSV < 0;
        UPDATE T
            SET T.Id_Adm = @Id_Adm,
                T.Precio_Cochera = A.Precio_Cochera_Default, 
                T.Precio_Baulera = A.Precio_Baulera_Default
            FROM #TempConsorcios AS T, Administracion AS A
            WHERE A.Id_Administracion = @Id_Adm;
        MERGE INTO Consorcio AS T
        USING #TempConsorcios AS S
        ON (T.Id_Consorcio = S.Id_Limpio)
        WHEN NOT MATCHED BY TARGET THEN 
            INSERT (Id_Consorcio, Id_Administracion, Nombre, Domicilio, Cant_unidades, MetrosCuadrados, Precio_Cochera, Precio_Baulera)
            VALUES (S.Id_Limpio, S.Id_Adm, S.Nombre_CSV, S.Domicilio_CSV, S.CantUnidades_CSV, S.M2Totales_CSV, S.Precio_Cochera, S.Precio_Baulera)
        WHEN MATCHED THEN
            UPDATE SET
                T.Id_Administracion = S.Id_Adm,
                T.Nombre = S.Nombre_CSV,
                T.Domicilio = S.Domicilio_CSV,
                T.Cant_unidades = S.CantUnidades_CSV,
                T.MetrosCuadrados = S.M2Totales_CSV,
                T.Precio_Cochera = S.Precio_Cochera,
                T.Precio_Baulera = S.Precio_Baulera;
        PRINT 'Importación de Consorcios (XLSX) completada.';

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo importar el archivo XLSX.';
        PRINT ERROR_MESSAGE(); 
        THROW; 
    END CATCH

    DROP TABLE #TempConsorcios;
    SET NOCOUNT OFF;
END
GO

use bd_tp_testeo
EXEC sp_Importar_Consorcios @RutaArchivoXLSX = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\ARCHIVOS\datos varios.xlsx',@id_Adm=1

SELECT * FROM Consorcio
