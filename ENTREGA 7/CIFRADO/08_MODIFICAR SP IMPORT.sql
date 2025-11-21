/*
================================================================================
SCRIPT DE ACTUALIZACION DE STORED PROCEDURES DE IMPORTACIÓN
Base de Datos: COM5600_G04
================================================================================
*/

USE COM5600_G04;
GO

-- IMPORTAR PERSONAS ENCRIPTADO 
IF OBJECT_ID('dbo.sp_Importar_Personas', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Importar_Personas;
GO
CREATE PROCEDURE dbo.sp_Importar_Personas
    @RutaArchivoCSV VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    CREATE TABLE #TempPersonas (
        Nombre_CSV VARCHAR(100),
        Apellido_CSV VARCHAR(100),
        DNI_CSV VARCHAR(20),
        Email_CSV VARCHAR(100),
        Telefono_CSV VARCHAR(50),
        CBU_CSV VARCHAR(50),
        Inquilino_CSV VARCHAR(5)
    );

    BEGIN TRY
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

        -- MERGE
		OPEN SYMMETRIC KEY Key_DatosSensibles
		DECRYPTION BY CERTIFICATE Cert_Cifrado_Datos;

        MERGE INTO unidades.Persona AS T 
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
        ) AS S
        ON (T.DNI = ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.DNI_Limpio) AND S.rn = 1)

        WHEN NOT MATCHED BY TARGET AND s.rn = 1 THEN
            INSERT (DNI, Nombre, Apellido, email, Telefono, CBU_CVU, Inquilino)
            VALUES (
				ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.DNI_Limpio),
                ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Nombre_CSV),
                ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Apellido_CSV),
                ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Email_CSV),
                ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Telefono_CSV),
                ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.CBU_CSV),
                S.Es_Inquilino_BIT
            )

        WHEN MATCHED THEN
            UPDATE SET
				T.Nombre = ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Nombre_CSV),
                T.Apellido = ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Apellido_CSV),
                T.Email = ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Email_CSV),
                T.Telefono = ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.Telefono_CSV),
                T.CBU_CVU = ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), S.CBU_CSV),
                T.Inquilino = S.Es_Inquilino_BIT;

        -- Cerrar la clave al final de la operación
        CLOSE SYMMETRIC KEY Key_DatosSensibles;
                
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

-- IMPORTAR PERSONA-UNIDAD FUNCIONAL ENCRIPTADO 
IF OBJECT_ID('dbo.sp_Importar_UF_Persona', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Importar_UF_Persona;
GO
CREATE PROCEDURE dbo.sp_Importar_UF_Persona
    @RutaArchivoCSV VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #TempLink (
        CBU_CSV VARCHAR(50),
        NomConsorcio_CSV VARCHAR(100),
        NroUF_CSV VARCHAR(10),
        Piso_CSV VARCHAR(10),
        Depto_CSV VARCHAR(10)
    );

    BEGIN TRY
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
        JOIN unidades.Persona AS P ON T.CBU_CSV = CONVERT(VARCHAR, DECRYPTBYKEY(P.CBU_CVU)); 
		
		CLOSE SYMMETRIC KEY Key_DatosSensibles;
        
		UPDATE T
        SET T.Id_Consorcio_Limpio = C.Id_consorcio
        FROM #TempLink AS T
        JOIN negocio.Consorcio AS C ON T.NomConsorcio_CSV = C.Nombre; 

        DELETE FROM #TempLink 
        WHERE Id_Consorcio_Limpio IS NULL OR id_persona_limpio IS NULL;

        -- MERGE
        MERGE INTO unidades.Unidad_Persona AS T 
        USING (
            SELECT DISTINCT 
                Id_Consorcio_Limpio, 
                NroUF_Limpio, 
                id_persona_limpio,
                Id_TipoRelacion_Limpio
            FROM #TempLink AS TLink
            WHERE EXISTS (
                SELECT 1 FROM unidades.Unidad_Funcional UF 
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


-- IMPORTAR PAGOS ENCRIPTADOS 
IF OBJECT_ID('dbo.sp_Importar_PagosConsorcios') IS NOT NULL
    DROP PROCEDURE dbo.sp_Importar_PagosConsorcios;
GO
CREATE PROCEDURE dbo.sp_Importar_PagosConsorcios
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

        UPDATE T SET 
            T.Id_Persona = P.id_persona,
            T.NroUF = UP.NroUf,
            T.Es_Asociado = 1
        FROM #PagosTemp AS T
        INNER JOIN unidades.Persona AS P ON T.Cuenta_Origen_CSV = CONVERT(VARCHAR, DECRYPTBYKEY(P.CBU_CVU)) 
        INNER JOIN unidades.Unidad_Persona AS UP ON P.id_persona = UP.id_persona 
        WHERE UP.Fecha_Fin IS NULL;

        UPDATE #PagosTemp SET Es_Asociado = 0 WHERE Es_Asociado IS NULL;

        
		-- INSERTAR
        INSERT INTO pagos.Pago (Id_Pago,Id_Forma_De_Pago, Fecha, Cuenta_Origen, Importe, Es_Pago_Asociado) 
        SELECT 
            T.id_PAGO_CSV,1, TRY_CONVERT(DATE, T.Fecha_CSV, 103),ENCRYPTBYKEY(Key_GUID('Key_DatosSensibles'), T.Cuenta_Origen_CSV), CAST(T.Importe_CSV AS DECIMAL(9,2)), T.Es_Asociado
        FROM #PagosTemp AS T
		LEFT JOIN pagos.Pago AS P ON P.Id_Pago = T.id_PAGO_CSV 
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

-- APLICACION DE PAGOS
IF OBJECT_ID('dbo.sp_Procesar_Pagos', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Procesar_Pagos;
GO
CREATE PROCEDURE dbo.sp_Procesar_Pagos
    @FechaCorte DATE
AS
BEGIN
    SET NOCOUNT ON;
	OPEN SYMMETRIC KEY Key_DatosSensibles DECRYPTION BY CERTIFICATE Cert_Cifrado_Datos;
    BEGIN TRY
        -- Identificar pagos a procesar (para la primer UF activa por persona)
        WITH Pagos_CTE AS (
            SELECT 
                P.Id_Pago,
                P.Importe,
                P.Fecha,
                UP.Id_Consorcio,
                UP.NroUf,
                ROW_NUMBER() OVER (PARTITION BY P.Id_Pago ORDER BY UP.Id_Consorcio, UP.NroUf) as rn
            FROM pagos.Pago P
            JOIN unidades.Persona PER ON CONVERT(VARCHAR, DECRYPTBYKEY(P.Cuenta_Origen)) = CONVERT(VARCHAR, DECRYPTBYKEY(PER.Cbu_Cvu))
            JOIN unidades.Unidad_Persona UP ON PER.Id_Persona = UP.Id_Persona 
            WHERE P.Es_Pago_Asociado = 1 AND P.Procesado = 0 
              AND P.Fecha <= @FechaCorte AND UP.Fecha_Fin IS NULL
        )
        SELECT Id_Pago, Importe, Fecha, Id_Consorcio, NroUf 
        INTO #PagosPendientes FROM Pagos_CTE WHERE rn = 1;

        DECLARE @TotalPagos INT = (SELECT COUNT(*) FROM #PagosPendientes);
        PRINT 'Procesando ' + CAST(@TotalPagos AS VARCHAR) + ' pagos.';

        -- Procesamiento secuencial para la tabla temporal
        DECLARE @IdPago INT, @MontoRestante DECIMAL(12,2), @IdConsorcio INT, @NroUF VARCHAR(10);

        WHILE EXISTS (SELECT 1 FROM #PagosPendientes)
        BEGIN
            SELECT TOP 1 
                @IdPago = Id_Pago, 
                @MontoRestante = Importe, 
                @IdConsorcio = Id_Consorcio, 
                @NroUF = NroUf 
            FROM #PagosPendientes;

            -- Imputar deuda mientras quede saldo
            WHILE @MontoRestante > 0
            BEGIN
                DECLARE @IdDetalleDestino INT = NULL;
                DECLARE @SaldoPendiente DECIMAL(12,2) = 0;
                DECLARE @TipoIngreso INT = 1; 

                -- Buscar deuda más antigua
                SELECT TOP 1 
                    @IdDetalleDestino = DE.Id_Detalle_Expensa,
                    @SaldoPendiente = CAST((DE.Total_A_Pagar - DE.Pagos_Recibidos_Mes) AS DECIMAL(12,2))
                FROM liquidacion.Detalle_Expensa_UF DE
                JOIN liquidacion.Liquidacion_Mensual LM ON DE.Id_Expensa = LM.Id_Liquidacion_Mensual
                WHERE DE.Id_Consorcio = @IdConsorcio AND DE.NroUf = @NroUF
                  AND (DE.Total_A_Pagar - DE.Pagos_Recibidos_Mes) > 0.01
                ORDER BY LM.Periodo ASC;

                -- Si no hay deuda, imputar a cuenta en la última expensa
                IF @IdDetalleDestino IS NULL
                BEGIN
                    SELECT TOP 1 
                        @IdDetalleDestino = DE.Id_Detalle_Expensa, 
                        @SaldoPendiente = @MontoRestante 
                    FROM liquidacion.Detalle_Expensa_UF DE 
                    JOIN liquidacion.Liquidacion_Mensual LM ON DE.Id_Expensa = LM.Id_Liquidacion_Mensual
                    WHERE DE.Id_Consorcio = @IdConsorcio AND DE.NroUf = @NroUF 
                    ORDER BY LM.Periodo DESC;
                    
                    SET @TipoIngreso = 3; 
                END

                IF @IdDetalleDestino IS NULL BREAK;

                -- Calcular monto a aplicar
                DECLARE @Aplicar DECIMAL(12,2) = CASE WHEN @MontoRestante >= @SaldoPendiente THEN @SaldoPendiente ELSE @MontoRestante END;

                -- Actualizar y registrar detalle
                UPDATE liquidacion.Detalle_Expensa_UF 
                SET Pagos_Recibidos_Mes = Pagos_Recibidos_Mes + @Aplicar 
                WHERE Id_Detalle_Expensa = @IdDetalleDestino;

                INSERT INTO pagos.Detalle_Pago (Id_Pago, Id_Detalle_Expensa, Id_Tipo_Ingreso, Importe_Usado)
                VALUES (@IdPago, @IdDetalleDestino, @TipoIngreso, @Aplicar);

                SET @MontoRestante = @MontoRestante - @Aplicar;
            END

            -- Finalizar pago y recalcular saldos futuros
            UPDATE pagos.Pago SET Procesado = 1 WHERE Id_Pago = @IdPago;
            
			EXEC dbo.sp_Recalcular_Saldos_UF @Id_Consorcio = @IdConsorcio, @NroUF = @NroUF;

            DELETE FROM #PagosPendientes WHERE Id_Pago = @IdPago;
        END

        DROP TABLE #PagosPendientes;
		CLOSE SYMMETRIC KEY Key_DatosSensibles;
    END TRY
    BEGIN CATCH
		IF (SELECT COUNT(*) FROM sys.openkeys) > 0 CLOSE SYMMETRIC KEY Key_DatosSensibles;
        PRINT 'ERROR en sp_Procesar_Pagos: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- MODIFICO EL REPORTE QUE MUESTRA LOS DATOS DE LAS PERSONAS
IF OBJECT_ID('dbo.sp_ReporteTop3MorososPorConsorcioPisoAnio', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ReporteTop3MorososPorConsorcioPisoAnio;
GO
CREATE OR ALTER PROCEDURE dbo.sp_ReporteTop3MorososPorConsorcioPisoAnio
    @Id_Consorcio INT,
    @Piso VARCHAR(5),
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY Key_DatosSensibles
    DECRYPTION BY CERTIFICATE Cert_Cifrado_Datos;

    ;WITH CTE_Deuda AS (
        SELECT 
            p.Id_Persona,
            CONVERT(VARCHAR, DECRYPTBYKEY(p.Apellido)) + ', ' + 
            CONVERT(VARCHAR, DECRYPTBYKEY(p.Nombre)) AS Propietario,
            CONVERT(VARCHAR, DECRYPTBYKEY(p.DNI)) AS DNI,
            CONVERT(VARCHAR, DECRYPTBYKEY(p.Email)) AS Email,
            CONVERT(VARCHAR, DECRYPTBYKEY(p.Telefono)) AS Telefono,
            uf.Piso,
            lm.Periodo,
            (deu.Total_A_Pagar - deu.Pagos_Recibidos_Mes) AS Saldo_Pendiente
        FROM liquidacion.Detalle_Expensa_UF deu 
        INNER JOIN liquidacion.Liquidacion_Mensual lm ON lm.Id_Liquidacion_Mensual = deu.Id_Expensa 
        INNER JOIN unidades.Unidad_Funcional uf ON uf.Id_Consorcio = deu.Id_Consorcio AND uf.NroUF = deu.NroUF 
        INNER JOIN unidades.Unidad_Persona up ON up.Id_Consorcio = uf.Id_Consorcio AND up.NroUF = uf.NroUF 
        INNER JOIN unidades.Persona p ON p.Id_Persona = up.Id_Persona 
        WHERE 
            deu.Id_Consorcio = @Id_Consorcio
            AND uf.Piso = @Piso
            AND YEAR(lm.Periodo) = @Anio
            AND up.Fecha_Fin IS NULL
            AND (deu.Total_A_Pagar - deu.Pagos_Recibidos_Mes) > 0.01 
    )
    SELECT TOP 3
        Propietario,
        DNI,
        Email,
        Telefono,
        Piso,
        SUM(Saldo_Pendiente) AS DeudaTotalAcumulada,
        COUNT(DISTINCT Periodo) AS Cant_Periodos_Adeudados
    FROM CTE_Deuda
    GROUP BY Propietario, DNI, Email, Telefono, Piso
    ORDER BY DeudaTotalAcumulada DESC;

    CLOSE SYMMETRIC KEY Key_DatosSensibles;
END;
GO