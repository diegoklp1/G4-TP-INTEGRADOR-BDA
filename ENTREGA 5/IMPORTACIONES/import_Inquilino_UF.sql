USE bd_tp_testeo
GO

CREATE TABLE Tipo_Relacion (
    Id_TipoRelacion INT PRIMARY KEY,
    Descripcion VARCHAR(50) NOT NULL
);
GO
INSERT INTO Tipo_Relacion (Id_TipoRelacion, Descripcion) VALUES
    (1, 'Propietario'),(2, 'Inquilino');
GO

IF OBJECT_ID('[Unidad_Funcional-Persona]', 'U') IS NOT NULL
    DROP TABLE [Unidad_Funcional-Persona];
GO

CREATE TABLE [Unidad_Funcional-Persona] (
    Id_Consorcio INT NOT NULL,
    NumUf VARCHAR(10) NOT NULL,
    DNI VARCHAR(11) NOT NULL,
    Id_TipoRelacion INT NOT NULL,
    Fecha_Inicio DATE NOT NULL,
    Fecha_Fin DATE NULL, 
    CONSTRAINT PK_UF_Persona PRIMARY KEY (Id_Consorcio, NumUf, DNI, Id_TipoRelacion),
    CONSTRAINT FK_UFP_UF FOREIGN KEY (Id_Consorcio, NumUf) REFERENCES Unidad_Funcional(Id_Consorcio, NroUf),
    CONSTRAINT FK_UFP_Persona FOREIGN KEY (DNI) REFERENCES Persona(DNI),
    CONSTRAINT FK_UFP_TipoRelacion FOREIGN KEY (Id_TipoRelacion) REFERENCES Tipo_Relacion(Id_TipoRelacion)
);
GO
USE bd_tp_testeo
GO

USE bd_tp_testeo
GO

IF OBJECT_ID('sp_Importar_UF_Persona', 'P') IS NOT NULL
    DROP PROCEDURE sp_Importar_UF_Persona;
GO

CREATE PROCEDURE sp_Importar_UF_Persona
    @RutaArchivoCSV VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. CREAR TABLA TEMPORAL
    CREATE TABLE #TempLink (
        CBU_CSV VARCHAR(50),
        NomConsorcio_CSV VARCHAR(100),
        NroUF_CSV VARCHAR(10),
        Piso_CSV VARCHAR(10),
        Depto_CSV VARCHAR(10)
    );

    BEGIN TRY
        -- CSV
        DECLARE @Sql NVARCHAR(MAX);
        SET @Sql = N'
            BULK INSERT #TempLink
            FROM ''' + @RutaArchivoCSV + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ''|'',
                ROWTERMINATOR = ''\n'',
                TABLOCK
            );'
        EXEC sp_executesql @Sql;

        -- ETL

        ALTER TABLE #TempLink ADD Id_Consorcio_Limpio INT, 
                                    NroUF_Limpio VARCHAR(10), 
                                    DNI_Limpio VARCHAR(11),
                                    Id_TipoRelacion_Limpio INT;

        DELETE FROM #TempLink WHERE CBU_CSV IS NULL OR NroUF_CSV IS NULL;

        UPDATE #TempLink
        SET 
			CBU_CSV = LTRIM(RTRIM(CBU_CSV)),
            NomConsorcio_CSV = UPPER(LTRIM(RTRIM(NomConsorcio_CSV))),
            NroUF_Limpio = LTRIM(RTRIM(NroUF_CSV));

        UPDATE T
        SET T.DNI_Limpio = P.DNI,
            T.Id_TipoRelacion_Limpio = 
			CASE 
				WHEN P.Inquilino = 1 
				THEN 2 --inquilino 
				ELSE 1 --propietario
			END
        FROM #TempLink AS T
        JOIN Persona AS P ON T.CBU_CSV = P.CBU_CVU; -- Ahora CBU_CSV está limpio

        UPDATE T
        SET T.Id_Consorcio_Limpio = C.Id
        FROM #TempLink AS T
        JOIN Consorcio AS C ON T.NomConsorcio_CSV = C.Nombre;

        DELETE FROM #TempLink 
        WHERE Id_Consorcio_Limpio IS NULL OR DNI_Limpio IS NULL;

        -- MERGE
        MERGE INTO [Unidad_Funcional-Persona] AS T
        USING (
            SELECT DISTINCT 
                Id_Consorcio_Limpio, 
                NroUF_Limpio, 
                DNI_Limpio,
                Id_TipoRelacion_Limpio
            FROM #TempLink AS TLink
            WHERE EXISTS (
                SELECT 1 FROM Unidad_Funcional UF
                WHERE UF.Id_Consorcio = TLink.Id_Consorcio_Limpio
                  AND UF.NroUf = TLink.NroUF_Limpio
            )
        ) AS S
        ON (T.Id_Consorcio = S.Id_Consorcio_Limpio 
            AND T.NumUf = S.NroUF_Limpio 
            AND T.DNI = S.DNI_Limpio 
			AND T.Id_TipoRelacion = S.Id_TipoRelacion_Limpio)

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                Id_Consorcio, NumUf, DNI, Id_TipoRelacion,  Fecha_Inicio
            )
            VALUES (
                S.Id_Consorcio_Limpio, S.NroUF_Limpio, S.DNI_Limpio, S.Id_TipoRelacion_Limpio,
                GETDATE() 
            );
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo importar el archivo de vínculo UF-Persona.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH

    DROP TABLE #TempLink;
    SET NOCOUNT OFF;
END
GO

EXEC sp_Importar_UF_Persona
	@RutaArchivoCSV = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\Inquilino-propietarios-UF.csv';
GO

SELECT * FROM [Unidad_Funcional-Persona]