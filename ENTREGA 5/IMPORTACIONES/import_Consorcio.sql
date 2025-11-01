use master;
USE bd_tp_testeo;
GO

-- Insertamos una administración de prueba
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
IF OBJECT_ID('sp_Importar_Consorcios', 'P') IS NOT NULL
    DROP PROCEDURE sp_Importar_Consorcios;
GO

CREATE PROCEDURE sp_Importar_Consorcios
    @RutaArchivoCSV VARCHAR(500),
    @Id_Adm INT
AS
BEGIN
    SET NOCOUNT ON;
    -- TABLA TEMPORAL CON LA ESTRUCTURA DEL CSV
    CREATE TABLE #TempConsorcios (
        Consorcio_CSV VARCHAR(100), 
        Nombre_CSV VARCHAR(100),
        Domicilio_CSV VARCHAR(100),
        CantUnidades_CSV INT,
        M2Totales_CSV INT
    );

    BEGIN TRY
        -- 2. CORRECCIÓN DEL BULK INSERT
        DECLARE @Sql NVARCHAR(MAX);
        SET @Sql = N'
            BULK INSERT #TempConsorcios
            FROM ''' + @RutaArchivoCSV + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '','', 
                ROWTERMINATOR = ''\n'',
                TABLOCK
            );'
        EXEC sp_executesql @Sql;

        -- TRANSFORMACIÓN DE DATOS (ETL)

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
			WHERE A.Id_administracion = @Id_Adm;

        -- MERGE

        MERGE INTO Consorcio AS T --Target
        USING #TempConsorcios AS S --Source
        ON (T.Id_Consorcio = S.Id_Limpio)

        -- Si el ID NO existe en Consorcio, lo inserta
        WHEN NOT MATCHED BY TARGET THEN 
            INSERT (Id_Consorcio, Id_Administracion, Nombre, Domicilio, Cant_unidades, MetrosCuadrados, Precio_Cochera, Precio_Baulera)
            VALUES (S.Id_Limpio, S.Id_Adm, S.Nombre_CSV, S.Domicilio_CSV, S.CantUnidades_CSV, S.M2Totales_CSV, S.Precio_Cochera, S.Precio_Baulera)

        -- Si el ID si existe, actualiza los demás campos
        WHEN MATCHED THEN
            UPDATE SET
                T.Id_Administracion = S.Id_Adm,
                T.Nombre = S.Nombre_CSV,
                T.Domicilio = S.Domicilio_CSV,
                T.Cant_unidades = S.CantUnidades_CSV,
                T.MetrosCuadrados = S.M2Totales_CSV,
                T.Precio_Cochera = S.Precio_Cochera,
                T.Precio_Baulera = S.Precio_Baulera;
        
        PRINT 'Importación de Consorcios completada.';

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo importar el archivo.';
        PRINT ERROR_MESSAGE(); 
        THROW; 
    END CATCH

    DROP TABLE #TempConsorcios;
    SET NOCOUNT OFF;
END
GO


EXEC sp_Importar_Consorcios @RutaArchivoCSV = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\datos consorcio.csv', @id_Adm=1

select * from Consorcio
select * from Administracion