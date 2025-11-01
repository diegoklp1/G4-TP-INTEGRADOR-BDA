use master
USE bd_tp_testeo
GO
/*
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
CREATE TABLE Proovedor (
    Id INT PRIMARY KEY IDENTITY(1,1), 
    Id_Consorcio INT,
    Nombre VARCHAR(60),
    Descripcion VARCHAR(100),
    Cuenta VARCHAR(50),

    CONSTRAINT FK_Proovedor_Consorcio
    FOREIGN KEY (Id_Consorcio)
    REFERENCES Consorcio(Id)
);
GO
*/
USE bd_tp_testeo
GO
IF OBJECT_ID('sp_Importar_Proveedores', 'P') IS NOT NULL
    DROP PROCEDURE sp_Importar_Proveedores;
GO

CREATE PROCEDURE sp_Importar_Proveedores
    @RutaArchivoCSV VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
	-- TABLA TEMPORAL CON LA MISMA ESTRUCTURA DEL CSV
    CREATE TABLE #TempProveedores (
		col_vacia VARCHAR(10),
        Tipo_gasto VARCHAR(60), 
        Nombre VARCHAR(80),     
        Cuenta VARCHAR(50),    
        NomConsorcio VARCHAR(200) 
    );

    BEGIN TRY
        -- CARGAR CSV
        DECLARE @Sql NVARCHAR(MAX);
        SET @Sql = N'
            BULK INSERT #TempProveedores
            FROM ''' + @RutaArchivoCSV + '''
            WITH (
                FIRSTROW = 3,
                FIELDTERMINATOR = '','', -- Separado por comas
                ROWTERMINATOR = ''\n'',
                TABLOCK
            );'
        EXEC sp_executesql @Sql;

        -- TRANSFORMACIÓN DE DATOS (ETL)

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

        -- MERGE

        MERGE INTO Proovedor AS T -- T = Target (Destino)
        USING (
            -- Obtengo los proveedores únicos por Consorcio
            SELECT DISTINCT 
                Tipo_gasto,
                Nombre,
                Cuenta, 
                Id_Consorcio
            FROM #TempProveedores
            WHERE Id_Consorcio IS NOT NULL -- Solo si encontramos el consorcio
              AND Nombre IS NOT NULL 
        ) AS S -- S = Source (Origen)
        ON (T.Id_Consorcio = S.Id_Consorcio AND T.Nombre_gasto = S.Nombre)

        -- Si no existe (mismo nombre + mismo consorcio), lo crea
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (Id_Consorcio, Nombre_gasto, Descripcion, Cuenta)
            VALUES (S.Id_Consorcio, S.Nombre, S.Tipo_gasto, S.Cuenta)

        -- Si ya existe, actualiza sus datos 
        WHEN MATCHED THEN
            -- (FIX 2: Mapeo de columnas corregido)
            UPDATE SET
                T.Descripcion = S.Tipo_gasto,
                T.Cuenta = S.Cuenta;
        
        PRINT 'Importación de Proveedores completada.';

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo importar el archivo de Proveedores.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
	 
    DROP TABLE #TempProveedores;
    SET NOCOUNT OFF;
END
GO


EXEC sp_Importar_Proveedores
    @RutaArchivoCSV = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\datos proovedores.csv';
GO

SELECT * FROM Consorcio;
SELECT * FROM Proovedor;
GO
