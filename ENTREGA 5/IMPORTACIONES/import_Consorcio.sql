USE bd_tp_testeo

CREATE TABLE Administracion (
    Id INT PRIMARY KEY,
    Razon_Social VARCHAR(100),
    CUIT BIGINT,
    Direccion VARCHAR(100),
    Telefono INT,
    Email VARCHAR(100),
    Cuenta_Deposito BIGINT,
	PrecioCocheraDefault DECIMAL(9, 2) NULL,
	PrecioBauleraDefault DECIMAL(9, 2) NULL
);
GO
CREATE TABLE Consorcio (
    Id INT PRIMARY KEY,
    Id_Adm INT,
    Nombre VARCHAR(100),
    Domicilio VARCHAR(100),
    Cant_unidades SMALLINT,
    MetrosCuadrados INT,
    Precio_Cochera DECIMAL(9, 2),
    Precio_Baulera DECIMAL(9, 2),

    CONSTRAINT FK_Consorcio_Administracion FOREIGN KEY (Id_Adm) REFERENCES Administracion(Id)
);
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
		-- CARGAR CSV
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

        -- TRANSFORMACIÓN DE DATOS(ETL)

		ALTER TABLE #TempConsorcios ADD Id_Adm INT, Precio_Cochera DECIMAL(9, 2), Precio_Baulera DECIMAL(9, 2);
        DELETE FROM #TempConsorcios WHERE Consorcio_CSV IS NULL;
		UPDATE #TempConsorcios SET Consorcio_CSV = REPLACE(Consorcio_CSV, 'Consorcio ', '');
		UPDATE #TempConsorcios SET Nombre_CSV = UPPER(Nombre_CSV) WHERE Nombre_CSV IS NOT NULL;
		UPDATE #TempConsorcios SET Domicilio_CSV = 'DOMICILIO NO INFORMADO' WHERE Domicilio_CSV IS NULL OR Domicilio_CSV = '';
		UPDATE #TempConsorcios SET CantUnidades_CSV = 0 WHERE CantUnidades_CSV IS NULL;
		UPDATE #TempConsorcios SET M2Totales_CSV = 0 WHERE M2Totales_CSV < 0;
		UPDATE T
				-- Busco los valores en la tabla Administracion
			SET T.Id_Adm = @Id_Adm,
				T.Precio_Cochera = A.PrecioCocheraDefault, 
				T.Precio_Baulera = A.PrecioBauleraDefault
			FROM #TempConsorcios AS T, Administracion AS A
			WHERE A.Id = @Id_Adm;


        -- MERGE

        MERGE INTO Consorcio AS T --Target
        USING #TempConsorcios AS S --Source
        ON (T.Id = S.Id)

        -- Si el ID NO existe en Consorcio, lo inserta
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (Id, Id_Adm, Nombre, Domicilio, Cant_unidades, MetrosCuadrados, Precio_Cochera, Precio_Baulera)
            VALUES (S.Id, S.Id_Adm, S.Nombre, S.Domicilio, S.Cant_unidades, S.MetrosCuadrados, S.Precio_Cochera, S.Precio_Baulera)

        -- Si el ID si existe, actualiza los demás campos
        WHEN MATCHED THEN
            UPDATE SET
                T.Id_Adm = S.Id_Adm,
                T.Nombre = S.Nombre,
                T.Domicilio = S.Domicilio,
                T.Cant_unidades = S.Cant_unidades,
                T.MetrosCuadrados = S.MetrosCuadrados,
                T.Precio_Cochera = S.Precio_Cochera,
                T.Precio_Baulera = S.Precio_Baulera;
        

    END TRY
    BEGIN CATCH
        -- Manejo de errores (muy importante)
        PRINT 'ERROR: No se pudo importar el archivo.';
        --PRINT ERROR_MESSAGE();
    END CATCH

    DROP TABLE #TempConsorcios;
    SET NOCOUNT OFF;
END
GO



EXEC sp_Importar_Consorcios @RutaArchivoCSV = 'C:\Sistema\Importaciones\consorcios_mayo.csv'

select * from Consorcio
select * from Administracion