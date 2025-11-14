/*
================================================================================
SCRIPT DE ACTUALIZACION DE STORED PROCEDURES DE IMPORTACIÓN
Base de Datos: COM5600_G04
================================================================================
*/

USE COM5600_G04;
GO

-- 3. sp_Importar_Personas
-- Importa inquilinos y propietarios desde un CSV a la tabla Persona.
-- Realiza limpieza de DNI, CBU y maneja duplicados internos del CSV.
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
            Email_CSV = LOWER(REPLACE(Email_CSV,' ','')),
            Telefono_CSV = LTRIM(RTRIM(Telefono_CSV)),
            CBU_CSV = LTRIM(RTRIM(CBU_CSV));

       
        UPDATE #TempPersonas SET Es_Inquilino_BIT = CASE WHEN LTRIM(RTRIM(Inquilino_CSV)) = '1' THEN 1 ELSE 0 END;
        UPDATE #TempPersonas SET DNI_Limpio = NULL WHERE ISNUMERIC(DNI_Limpio) = 0;
        DELETE FROM #TempPersonas WHERE DNI_Limpio IS NULL;

		/*
		-- VALIDACIÓN DE DUPLICADOS EN ORIGEN
		DECLARE @DNIDuplicado VARCHAR(20);
		SELECT TOP 1 @DNIDuplicado = DNI_Limpio
		FROM #TempPersonas
		GROUP BY DNI_Limpio
		HAVING COUNT(*) > 1;

		-- Si encuentro un duplicado
		IF @DNIDuplicado IS NOT NULL
		BEGIN
        DECLARE @ErrorMsg VARCHAR(200) = 'ERROR: El archivo CSV tiene DNIs duplicados. El DNI ' + @DNIDuplicado + ' aparece más de una vez. Corregir archivo de origen.'; 
        THROW 50001, @ErrorMsg, 1;
        END
		*/

        -- MERGE
		OPEN SYMMETRIC KEY Key_DatosSensibles
		DECRYPTION BY CERTIFICATE Cert_Cifrado_Datos;

        MERGE INTO Persona AS T
        USING (
            SELECT 
                DNI_Limpio,
                Nombre_CSV,
                Apellido_CSV,
                Email_CSV,
                Telefono_CSV,
                CBU_CSV,
                Es_Inquilino_BIT,
				ROW_NUMBER() OVER(PARTITION BY DNI_Limpio ORDER BY DNI_Limpio) AS rn
            FROM #TempPersonas
        ) AS S -- Source
        ON (T.DNI = ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.DNI_Limpio) AND S.rn = 1)

        -- Si el DNI no existe, inserta la persona
        WHEN NOT MATCHED BY TARGET AND s.rn = 1 THEN
            INSERT (
                DNI,
                Nombre,
                Apellido,
				email,
                Telefono,
                CBU_CVU,
                Inquilino
            )
            VALUES (
				ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.DNI_Limpio),
                ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Nombre_CSV),
                ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Apellido_CSV),
                ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Email_CSV),
                ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Telefono_CSV),
                ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.CBU_CSV),
                S.Es_Inquilino_BIT
            )

        -- Si el DNI ya existe, actualiza sus datos
        WHEN MATCHED THEN
            UPDATE SET
				T.Nombre = ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Nombre_CSV),
                T.Apellido = ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Apellido_CSV),
                T.Email = ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Email_CSV),
                T.Telefono = ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Telefono_CSV),
                T.CBU_CVU = ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.CBU_CSV),
                T.Inquilino = S.Es_Inquilino_BIT;
    END TRY
    BEGIN CATCH
		IF (XACT_STATE()) <> 0 ROLLBACK TRANSACTION;
        IF (SELECT KEY_GUID('Key_DatosSensibles')) IS NOT NULL CLOSE SYMMETRIC KEY Key_DatosSensibles;
        PRINT 'ERROR: No se pudo importar el archivo de Personas (cifrado).';
        THROW;
    END CATCH

    DROP TABLE #TempPersonas;
    SET NOCOUNT OFF;
END
GO

-- 4. sp_Importar_UF_Persona
-- Lee un CSV para vincular las Personas con sus Unidades Funcionales.
-- Utiliza el CBU/CVU como "llave" temporal para encontrar el DNI de la Persona.
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
                                    id_persona_limpio VARCHAR(11),
                                    Id_TipoRelacion_Limpio INT;

        DELETE FROM #TempLink WHERE CBU_CSV IS NULL OR NroUF_CSV IS NULL;

        UPDATE #TempLink
        SET 
			CBU_CSV = LTRIM(RTRIM(CBU_CSV)),
            NomConsorcio_CSV = UPPER(LTRIM(RTRIM(NomConsorcio_CSV))),
            NroUF_Limpio = LTRIM(RTRIM(NroUF_CSV));


		OPEN SYMMETRIC KEY Key_DatosSensibles
        DECRYPTION BY CERTIFICATE Cert_Cifrado_Datos;
        
		UPDATE T
        SET T.id_persona_limpio = P.id_persona,
            T.Id_TipoRelacion_Limpio = 
			CASE 
				WHEN P.Inquilino = 1 
				THEN 2 --inquilino 
				ELSE 1 --propietario
			END
        FROM #TempLink AS T
        JOIN Persona AS P ON T.CBU_CSV = CONVERT(VARCHAR, DECRYPTBYKEY(P.CBU_CVU));
		
		CLOSE SYMMETRIC KEY Key_DatosSensibles;
        
		UPDATE T
        SET T.Id_Consorcio_Limpio = C.Id_consorcio
        FROM #TempLink AS T
        JOIN Consorcio AS C ON T.NomConsorcio_CSV = C.Nombre;

        DELETE FROM #TempLink 
        WHERE Id_Consorcio_Limpio IS NULL OR id_persona_limpio IS NULL;

        -- MERGE
        MERGE INTO Unidad_Persona AS T
        USING (
            SELECT DISTINCT 
                Id_Consorcio_Limpio, 
                NroUF_Limpio, 
                id_persona_limpio,
                Id_TipoRelacion_Limpio
            FROM #TempLink AS TLink
            WHERE EXISTS (
                SELECT 1 FROM Unidad_Funcional UF
                WHERE UF.Id_Consorcio = TLink.Id_Consorcio_Limpio
                  AND UF.NroUf = TLink.NroUF_Limpio
            )
        ) AS S
        ON (T.Id_Consorcio = S.Id_Consorcio_Limpio 
            AND T.NroUf = S.NroUF_Limpio 
            AND T.id_persona = S.id_persona_limpio 
			AND T.Id_TipoRelacion = S.Id_TipoRelacion_Limpio)

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                Id_Consorcio, NroUf, id_persona, Id_TipoRelacion,  Fecha_Inicio
            )
            VALUES (
                S.Id_Consorcio_Limpio, S.NroUF_Limpio, S.id_persona_limpio, S.Id_TipoRelacion_Limpio,
                GETDATE() 
            );
    END TRY
    BEGIN CATCH
		IF (SELECT KEY_GUID('Key_DatosSensibles')) IS NOT NULL
            CLOSE SYMMETRIC KEY Key_DatosSensibles;
        PRINT 'ERROR: No se pudo importar el archivo de vínculo UF-Persona.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH

    DROP TABLE #TempLink;
    SET NOCOUNT OFF;
END
GO


-- 5. sp_Importar_PagosConsorcios
-- Importa un CSV de pagos. Inserta en la cabecera 'Pago' y luego, usando un
-- bucle 'WHILE' (sin cursores), aplica los montos a las expensas adeudadas
-- (lógica de conciliación) insertando en 'Detalle_Pago'.
IF OBJECT_ID('sp_Importar_PagosConsorcios') IS NOT NULL
    DROP PROCEDURE sp_Importar_PagosConsorcios;
GO
CREATE PROCEDURE sp_Importar_PagosConsorcios
    @RutaArchivoCSV VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #PagosTemp (
		id_PAGO_CSV VARCHAR(10),
        Fecha_CSV VARCHAR(20),
        Cuenta_Origen_CSV VARCHAR(22),
        Importe_CSV VARCHAR(20)
    );

    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = N'
            BULK INSERT #PagosTemp
            FROM ''' + @RutaArchivoCSV + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''\n'',
                TABLOCK
            );';
        EXEC sp_executesql @SQL;

        -- ETL
        DELETE FROM #PagosTemp WHERE Cuenta_Origen_CSV IS NULL OR Importe_CSV IS NULL;
        UPDATE #PagosTemp SET 
            Fecha_CSV = TRIM(Fecha_CSV),
            Cuenta_Origen_CSV = LTRIM(RTRIM(Cuenta_Origen_CSV)),
            Importe_CSV = REPLACE(REPLACE(LTRIM(RTRIM(Importe_CSV)), '$', ''), ',', '.');

        ALTER TABLE #PagosTemp ADD Id_Persona INT NULL, NroUF VARCHAR(10) NULL, Es_Asociado BIT NULL;


		OPEN SYMMETRIC KEY Key_DatosSensibles
        DECRYPTION BY CERTIFICATE Cert_Cifrado_Datos;
        /* 
           Es asociado?:
           - Primero buscamos la persona por su CBU/CVU 
           - Luego buscamos la unidad funcional relacionada a esa persona
        */

        UPDATE T SET 
            T.Id_Persona = P.id_persona,
            T.NroUF = UP.NroUf,
            T.Es_Asociado = 1
        FROM #PagosTemp AS T
        INNER JOIN Persona AS P ON T.Cuenta_Origen_CSV = CONVERT(VARCHAR, DECRYPTBYKEY(P.CBU_CVU))
        INNER JOIN Unidad_persona AS UP ON P.id_persona = UP.id_persona
        WHERE UP.Fecha_Fin IS NULL;

        UPDATE #PagosTemp SET Es_Asociado = 0 WHERE Es_Asociado IS NULL;

        
		-- INSERTAR
        INSERT INTO Pago (Id_Pago,Id_Forma_De_Pago, Fecha, Cuenta_Origen, Importe, Es_Pago_Asociado)
        SELECT 
            T.id_PAGO_CSV,1, TRY_CONVERT(DATE, T.Fecha_CSV, 103),ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), T.Cuenta_Origen_CSV), CAST(T.Importe_CSV AS DECIMAL(9,2)), T.Es_Asociado
        FROM #PagosTemp AS T
		LEFT JOIN Pago AS P ON P.Id_Pago = T.id_PAGO_CSV 
		WHERE P.Id_Pago IS NULL;

		CLOSE SYMMETRIC KEY Key_DatosSensibles;

		DECLARE @FilasInsertadas INT = @@ROWCOUNT;
        PRINT 'Importación completada. Se insertaron ' + CAST(@FilasInsertadas AS VARCHAR) + ' nuevos pagos.';

    END TRY
    BEGIN CATCH
		IF (SELECT KEY_GUID('Key_DatosSensibles')) IS NOT NULL
            CLOSE SYMMETRIC KEY Key_DatosSensibles;
            
        PRINT ' Error en la importación de pagos consorcios (cifrado).';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH;

    DROP TABLE #PagosTemp;
END
GO
