USE bd_tp_testeo
CREATE TABLE Persona (
    DNI VARCHAR(11) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Apellido VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NULL,
    Telefono VARCHAR(50) NULL,
	inquilino bit,
	CBU_CVU VARCHAR(30)
);
GO


USE bd_tp_testeo
GO

IF OBJECT_ID('sp_Importar_Personas', 'P') IS NOT NULL
    DROP PROCEDURE sp_Importar_Personas;
GO

CREATE PROCEDURE sp_Importar_Personas
    @RutaArchivoCSV VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
	-- CREO LA TABLA TEMPORAL QUE COINCIDE CON LAS COLUMNAS DEL CSV
    CREATE TABLE #TempPersonas (
        Nombre_CSV VARCHAR(100),
        Apellido_CSV VARCHAR(100),
        DNI_CSV VARCHAR(20),
        Email_CSV VARCHAR(100),
        Telefono_CSV VARCHAR(50),
        CBU_CSV VARCHAR(50),
        Inquilino_CSV VARCHAR(5) -- (Leemos '1' o '0' como texto)
    );

    BEGIN TRY
        --CARGO CSV
        DECLARE @Sql NVARCHAR(MAX);
        SET @Sql = N'
            BULK INSERT #TempPersonas
            FROM ''' + @RutaArchivoCSV + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '';'', 
                ROWTERMINATOR = ''\n'',
                TABLOCK
            );'
        EXEC sp_executesql @Sql;

        -- PROCESO ETL
        ALTER TABLE #TempPersonas  ADD DNI_Limpio VARCHAR(20), Es_Inquilino_BIT BIT;
        DELETE FROM #TempPersonas WHERE DNI_CSV IS NULL OR LTRIM(RTRIM(DNI_CSV)) = '';
        UPDATE #TempPersonas
        SET 
		
			Nombre_CSV = UPPER(LTRIM(RTRIM(Nombre_CSV))),
            Apellido_CSV = UPPER(LTRIM(RTRIM(Apellido_CSV))),
            DNI_Limpio = LTRIM(RTRIM(DNI_CSV)),
            Email_CSV = LOWER(LTRIM(RTRIM(Email_CSV))),
            Telefono_CSV = LTRIM(RTRIM(Telefono_CSV)),
            CBU_CSV = CASE 
                -- Si CBU está en notación científica (3,62...E+021)
                WHEN LTRIM(RTRIM(CBU_CSV)) LIKE '%E+%' THEN 
                    CONVERT(VARCHAR(30), --4 Convierto el número a texto
                        CAST( -- 3 Convierto a DECIMAL para expandir el número
                            CAST( -- 2 Convierto a FLOAT para tomar el 'E+21'
                                REPLACE(LTRIM(RTRIM(CBU_CSV)), ',', '.') AS FLOAT -- 1 Reemplazo , por . 
                            ) 
                            AS DECIMAL(28, 0) 
                        )
                    )
                -- Si no es notación científica, solo se limpia
                ELSE LTRIM(RTRIM(CBU_CSV))
            END;

       
        UPDATE #TempPersonas SET Es_Inquilino_BIT = CASE WHEN LTRIM(RTRIM(Inquilino_CSV)) = '1' THEN 1 ELSE 0 END;
        UPDATE #TempPersonas SET DNI_Limpio = NULL WHERE ISNUMERIC(DNI_Limpio) = 0;
        DELETE FROM #TempPersonas WHERE DNI_Limpio IS NULL;

		-- VALIDACIÓN DE DUPLICADOS EN ORIGEN
		DECLARE @DNIDuplicado VARCHAR(20);
		SELECT TOP 1 @DNIDuplicado = DNI_Limpio
		FROM #TempPersonas
		GROUP BY DNI_Limpio
		HAVING COUNT(*) > 1;

		-- Si encuentro un duplicado, @DNIDuplicado no es nulo
		IF @DNIDuplicado IS NOT NULL
		BEGIN
        DECLARE @ErrorMsg VARCHAR(200) = 'ERROR: El archivo CSV tiene DNIs duplicados. El DNI ' + @DNIDuplicado + ' aparece más de una vez. Corregir archivo de origen.'; 
        THROW 50001, @ErrorMsg, 1;
        END

        -- MERGE
        MERGE INTO Persona AS T -- Target
        USING (
            -- DISTINCT para valores únicos
            SELECT DISTINCT
                DNI_Limpio,
                Nombre_CSV,
                Apellido_CSV,
                Email_CSV,
                Telefono_CSV,
                CBU_CSV,
                Es_Inquilino_BIT
            FROM #TempPersonas
        ) AS S -- Source
        ON (T.DNI = S.DNI_Limpio)

        -- Si el DNI no existe, inserta la persona
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                -- Id_persona (PK) se asume IDENTITY
                DNI,
                Nombre,
                Apellido,
				email,
                Telefono,
                CBU_CVU,
                Inquilino
            )
            VALUES (
                S.DNI_Limpio,
                S.Nombre_CSV,
                S.Apellido_CSV,
                S.Email_CSV,
                S.Telefono_CSV,
                S.CBU_CSV,
                S.Es_Inquilino_BIT
            )

        -- Si el DNI ya existe, actualiza sus datos
        WHEN MATCHED THEN
            UPDATE SET
                T.Nombre = S.Nombre_CSV,
                T.Apellido = S.Apellido_CSV,
                T.Email = S.Email_CSV,
                T.Telefono = S.Telefono_CSV,
                T.CBU_CVU = S.CBU_CSV,
                T.Inquilino = S.Es_Inquilino_BIT;
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo importar el archivo de Personas.';
        --PRINT ERROR_MESSAGE();
        THROW;
    END CATCH

    DROP TABLE #TempPersonas;
    SET NOCOUNT OFF;
END
GO

EXEC sp_Importar_Personas
    @RutaArchivoCSV = 'D:\Diego\Downloads\Archivos para el TP\Inquilino-propietarios-datos.csv';
GO

SELECT * FROM Persona