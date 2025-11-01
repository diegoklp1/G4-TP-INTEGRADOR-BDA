USE bd_tp_testeo
GO
truncate table Unidad_Funcional

CREATE TABLE Unidad_Funcional (
    Id_Consorcio INT NOT NULL,
    NroUf VARCHAR(10) NOT NULL,
    
    Piso VARCHAR(5),
    Departamento VARCHAR(6),
    Coeficiente DECIMAL(5, 2),
    M2_UF DECIMAL(7, 2),
    Baulera BIT NOT NULL DEFAULT 0,
    Cochera BIT NOT NULL DEFAULT 0,
    M2_Baulera DECIMAL(5, 2),
    M2_Cochera DECIMAL(5, 2),
    CONSTRAINT PK_UnidadFuncional PRIMARY KEY (Id_Consorcio, NroUf),
    CONSTRAINT FK_UF_Consorcio FOREIGN KEY (Id_Consorcio) REFERENCES Consorcio(Id_consorcio)
);
GO

USE bd_tp_testeo
GO

IF OBJECT_ID('sp_Importar_UnidadesFuncionales', 'P') IS NOT NULL
    DROP PROCEDURE sp_Importar_UnidadesFuncionales;
GO

CREATE PROCEDURE sp_Importar_UnidadesFuncionales
    @RutaArchivoTXT VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    CREATE TABLE #TempUF (
        NomConsorcio_CSV VARCHAR(100),
        NroUF_CSV VARCHAR(10),
        Piso_CSV VARCHAR(10),
        Depto_CSV VARCHAR(10),
        Coeficiente_CSV VARCHAR(10),
        M2_UF_CSV VARCHAR(10),
        Baulera_CSV VARCHAR(5),
        Cochera_CSV VARCHAR(5),
        M2_Baulera_CSV VARCHAR(10),
        M2_Cochera_CSV VARCHAR(10)
    );

    BEGIN TRY 
        DECLARE @Sql NVARCHAR(MAX);
        SET @Sql = N'
            BULK INSERT #TempUF
            FROM ''' + @RutaArchivoTXT + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ''\t'',
                ROWTERMINATOR = ''\n'',
                TABLOCK
            );'
        EXEC sp_executesql @Sql;

        --(ETL)     
        ALTER TABLE #TempUF ADD Id_Consorcio INT;      
        DELETE FROM #TempUF WHERE NomConsorcio_CSV IS NULL OR NroUF_CSV IS NULL;
        UPDATE #TempUF
        SET NomConsorcio_CSV = UPPER(LTRIM(RTRIM(NomConsorcio_CSV))),
            NroUF_CSV = LTRIM(RTRIM(NroUF_CSV)),
            Coeficiente_CSV = REPLACE(LTRIM(RTRIM(Coeficiente_CSV)), ',', '.'),
			Piso_CSV = LTRIM(RTRIM(Piso_CSV)),
			Depto_CSV = LTRIM(RTRIM(Depto_CSV)),
			Baulera_CSV = CASE WHEN LTRIM(RTRIM(Baulera_CSV)) = 'SI' THEN 1 ELSE 0 END,
			Cochera_CSV = CASE WHEN LTRIM(RTRIM(Cochera_CSV)) = 'SI' THEN 1 ELSE 0 END;

        -- Buscar el ID del Consorcio
        UPDATE T SET T.Id_Consorcio = C.Id_consorcio FROM #TempUF AS T
        JOIN Consorcio AS C ON T.NomConsorcio_CSV = C.Nombre;

        DELETE FROM #TempUF WHERE Id_Consorcio IS NULL;

        -- MERGE
        MERGE INTO Unidad_Funcional AS T
        USING #TempUF AS S
        ON (T.Id_Consorcio = S.Id_Consorcio AND T.NroUf = S.NroUF_CSV)

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                Id_Consorcio, NroUf, Piso, Departamento, Coeficiente, M2_UF, Baulera, Cochera, M2_Baulera, M2_Cochera
            )
            VALUES (
                S.Id_Consorcio, S.NroUF_CSV, S.Piso_CSV, S.Depto_CSV,
                CAST(S.Coeficiente_CSV AS DECIMAL(5, 2)),
                CAST(S.M2_UF_CSV AS DECIMAL(7, 2)),
                Baulera_CSV,Cochera_CSV,
                CAST(S.M2_Baulera_CSV AS DECIMAL(5, 2)),
                CAST(S.M2_Cochera_CSV AS DECIMAL(5, 2))
            )

        WHEN MATCHED THEN
            UPDATE SET
                T.Piso = S.Piso_CSV,
                T.Departamento =S.Depto_CSV,
                T.Coeficiente = CAST(S.Coeficiente_CSV AS DECIMAL(5, 2)),
                T.M2_UF = CAST(S.M2_UF_CSV AS DECIMAL(7, 2)),
                T.Baulera = S.Baulera_CSV,
                T.Cochera = S.Cochera_CSV,
                T.M2_Baulera = CAST(S.M2_Baulera_CSV AS DECIMAL(5, 2)),
                T.M2_Cochera = CAST(S.M2_Cochera_CSV AS DECIMAL(5, 2));

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo importar el archivo de UF (TXT).';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH

    DROP TABLE #TempUF;
    SET NOCOUNT OFF;
END
GO

EXEC sp_Importar_UnidadesFuncionales 
	@RutaArchivoTxt = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\UF por consorcio.txt';


SELECT * FROM Unidad_Funcional 
ORDER BY Id_Consorcio,CAST(NroUf AS INT)

