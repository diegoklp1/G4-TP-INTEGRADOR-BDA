/*
================================================================================
SCRIPT DE CREACI�N DE STORED PROCEDURES DE IMPORTACI�N
Base de Datos: COM5600_G04
================================================================================
*/
-- =============================================================
-- SCRIPT: 02_SP_CREACION_IMPORTACIONES.sql
-- PROPOSITO: Insertar los datos iniciales basicos en las tablas.

-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =============================================================
USE COM5600_G04;
GO

-- ES NECESARIO TENER INSTALADO "MICROSOSFT ACCES DATABASE ENGINE 2016 REDISTRIBUITABLE" PARA OLEDB.16
-- PARA PODER USAR CORRECTAMENTE EL COMANDO OPENROWSET NECESITAMOS ALGUNOS COMANDOS PREVIOS

--EXEC master.dbo.sp_enum_oledb_providers;

use COM5600_G04
--Habilitar opciones avanzadas
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
-- Habilitar la importaci�n de queries (Ad Hoc)
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

-- Para que el driver OLED.16 se ejecute dentro del proceso principal de SQL Server
EXEC master.dbo.sp_MSset_oledb_prop 
    N'Microsoft.ACE.OLEDB.16.0', 
    N'AllowInProcess', 1;
-- Para usar los parametros HDR Y IMEX en OPENROWSET
EXEC master.dbo.sp_MSset_oledb_prop 
    N'Microsoft.ACE.OLEDB.16.0', 
    N'DynamicParameters', 1;


PRINT '--- Creando Stored Procedures de Importaci�n ---';
GO

-- 1. sp_Importar_Consorcios
-- Lee la hoja 'Consorcios' de un archivo Excel (.xlsx) usando OPENROWSET.
-- Realiza el ETL (limpieza de ID) y carga/actualiza la tabla 'Consorcio'.
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
        PRINT 'Importaci�n de Consorcios (XLSX) completada.';

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

-- 2. sp_Importar_UF
-- Importa las unidades funcionales (UFs) desde un CSV a la tabla Unidad_Funcional.
-- Cruza con Consorcio para validar/obtener el Id_Consorcio.
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
		-- VALIDACI�N DE DUPLICADOS EN ORIGEN
		DECLARE @DNIDuplicado VARCHAR(20);
		SELECT TOP 1 @DNIDuplicado = DNI_Limpio
		FROM #TempPersonas
		GROUP BY DNI_Limpio
		HAVING COUNT(*) > 1;

		-- Si encuentro un duplicado
		IF @DNIDuplicado IS NOT NULL
		BEGIN
        DECLARE @ErrorMsg VARCHAR(200) = 'ERROR: El archivo CSV tiene DNIs duplicados. El DNI ' + @DNIDuplicado + ' aparece m�s de una vez. Corregir archivo de origen.'; 
        THROW 50001, @ErrorMsg, 1;
        END
		*/

        -- MERGE
        MERGE INTO Persona AS T -- Target
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
        ON (T.DNI = S.DNI_Limpio AND S.rn = 1)

        -- Si el DNI no existe, inserta la persona
        WHEN NOT MATCHED BY TARGET AND s.rn = 1 THEN
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

        UPDATE T
        SET T.id_persona_limpio = P.id_persona,
            T.Id_TipoRelacion_Limpio = 
			CASE 
				WHEN P.Inquilino = 1 
				THEN 2 --inquilino 
				ELSE 1 --propietario
			END
        FROM #TempLink AS T
        JOIN Persona AS P ON T.CBU_CSV = P.CBU_CVU; -- Ahora CBU_CSV est� limpio

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
        PRINT 'ERROR: No se pudo importar el archivo de v�nculo UF-Persona.';
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
-- (l�gica de conciliaci�n) insertando en 'Detalle_Pago'.
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

        ALTER TABLE #PagosTemp ADD Id_Persona INT NULL, NroUF INT NULL, Es_Asociado BIT NULL;

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
        INNER JOIN Persona AS P ON T.Cuenta_Origen_CSV = P.CBU_CVU
        INNER JOIN Unidad_persona AS UP ON P.id_persona = UP.id_persona
        WHERE UP.Fecha_Fin IS NULL;

        UPDATE #PagosTemp SET Es_Asociado = 0 WHERE Es_Asociado IS NULL;

        
		-- INSERTAR
        INSERT INTO Pago (Id_Pago,Id_Forma_De_Pago, Fecha, Cuenta_Origen, Importe, Es_Pago_Asociado)
        SELECT 
            T.id_PAGO_CSV,1, TRY_CONVERT(DATE, T.Fecha_CSV, 103), T.Cuenta_Origen_CSV, CAST(T.Importe_CSV AS DECIMAL(9,2)), T.Es_Asociado
        FROM #PagosTemp AS T
		LEFT JOIN Pago AS P ON P.Id_Pago = T.id_PAGO_CSV 
		WHERE P.Id_Pago IS NULL;

		DECLARE @FilasInsertadas INT = @@ROWCOUNT;
        PRINT 'Importaci�n completada. Se insertaron ' + CAST(@FilasInsertadas AS VARCHAR) + ' nuevos pagos.';

    END TRY
    BEGIN CATCH
        PRINT ' Error en la importaci�n de pagos consorcios.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH;

    DROP TABLE #PagosTemp;
END
GO

-- 6. sp_Importar_Proveedores
-- Lee la hoja 'Proveedores' de un Excel usando OPENROWSET.
-- Utiliza HDR=NO e IMEX=1 (modo seguro) para leer las columnas como F1, F2...
-- Realiza ETL para limpiar t�tulos y cargar/actualizar la tabla Proovedor.
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

        -- TRANSFORMACI�N DE DATOS (ETL)

        -- Borramos las filas de basura (t�tulos y encabezados)
        DELETE FROM #TempProveedores 
        WHERE Tipo_gasto = 'Tipo gasto' OR Tipo_gasto IS NULL OR LTRIM(RTRIM(Tipo_gasto)) = '';

        -- (El resto de tu l�gica ETL ahora funcionar�)
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
        
        PRINT 'Importaci�n de Proveedores (XLSX) completada.';

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

-- 7. sp_Importar_Gastos_JSON
-- Lee un archivo JSON de gastos, lo carga en una variable y usa OPENJSON
-- para leerlo. Realiza un "des-pivoteo" (UNPIVOT) de los datos usando
-- CROSS APPLY VALUES y los inserta en Gasto_Ordinario.

IF OBJECT_ID('sp_Importar_Gastos_JSON', 'P') IS NOT NULL
    DROP PROCEDURE sp_Importar_Gastos_JSON;
GO

CREATE PROCEDURE sp_Importar_Gastos_JSON
    @RutaArchivoJSON VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @JsonData NVARCHAR(MAX);
    DECLARE @Sql NVARCHAR(MAX);

    BEGIN TRY
        -- LECTURA
        PRINT 'Leyendo archivo JSON...';
        SET @Sql = N'
            SELECT @JsonDataOUT = BulkColumn
            FROM OPENROWSET (BULK ''' + @RutaArchivoJSON + ''', SINGLE_CLOB) AS J;';

        EXEC sp_executesql 
            @Sql, N'@JsonDataOUT NVARCHAR(MAX) OUTPUT', @JsonDataOUT = @JsonData OUTPUT;

        IF @JsonData IS NULL
        BEGIN
            THROW 50001, 'El archivo JSON est� vac�o o no se pudo leer.', 1;
        END

        PRINT 'Archivo JSON le�do. Procesando...';


        CREATE TABLE #TempGastos (
            Id_Consorcio INT,
            Id_Tipo_Gasto INT,
            Fecha_Gasto DATE,
            Importe_Total DECIMAL(10, 2),
            Descripcion_Gasto VARCHAR(100)
        );

        -- ETL
        DECLARE @AnioActual INT = YEAR(GETDATE());
        
        INSERT INTO #TempGastos (Id_Consorcio, Id_Tipo_Gasto, Fecha_Gasto, Importe_Total, Descripcion_Gasto)
        SELECT
            C.Id_Consorcio,
            TG.Id_Tipo_Gasto,
            DATEFROMPARTS(@AnioActual, MesNumero.MesN, 1) AS Fecha_Gasto,
            TRY_CONVERT(DECIMAL(10, 2), 
                STUFF(REPLACE(REPLACE(Gastos_Unpivot.Importe_JSON, '.', ''), ',', ''), 
                      LEN(REPLACE(REPLACE(Gastos_Unpivot.Importe_JSON, '.', ''), ',', '')) - 1, 
                      0, 
                      '.')
            ) AS Importe_Total,

            Gastos_Unpivot.Tipo_Nombre AS Descripcion_Gasto

        FROM OPENJSON (@JsonData)
        WITH (
            NombreConsorcio_JSON VARCHAR(100) '$."Nombre del consorcio"',
            Mes_JSON VARCHAR(20) '$.Mes',
            Bancarios_JSON VARCHAR(50) '$.BANCARIOS',
            Limpieza_JSON VARCHAR(50) '$.LIMPIEZA',
            Admin_JSON VARCHAR(50) '$.ADMINISTRACION',
            Seguros_JSON VARCHAR(50) '$.SEGUROS',
            Generales_JSON VARCHAR(50) '$."GASTOS GENERALES"',
            Agua_JSON VARCHAR(50) '$."SERVICIOS PUBLICOS-Agua"',
            Luz_JSON VARCHAR(50) '$."SERVICIOS PUBLICOS-Luz"'
        ) AS JSON_Pivote
        
        CROSS APPLY (VALUES
            ('BANCARIOS', Bancarios_JSON),
            ('LIMPIEZA', Limpieza_JSON),
            ('ADMINISTRACION', Admin_JSON),
            ('SEGUROS', Seguros_JSON),
            ('GASTOS GENERALES', Generales_JSON),
            ('SERVICIOS PUBLICOS-Agua', Agua_JSON),
            ('SERVICIOS PUBLICOS-Luz', Luz_JSON)
        ) AS Gastos_Unpivot(Tipo_Nombre, Importe_JSON)

        CROSS APPLY (
            SELECT CASE LOWER(LTRIM(RTRIM(JSON_Pivote.Mes_JSON)))
                WHEN 'enero' THEN 1 WHEN 'febrero' THEN 2 WHEN 'marzo' THEN 3
                WHEN 'abril' THEN 4 WHEN 'mayo' THEN 5 WHEN 'junio' THEN 6
                WHEN 'julio' THEN 7 WHEN 'agosto' THEN 8 WHEN 'septiembre' THEN 9
                WHEN 'octubre' THEN 10 WHEN 'noviembre' THEN 11 WHEN 'diciembre' THEN 12
                ELSE NULL
            END AS MesN
        ) AS MesNumero

        JOIN Consorcio C ON C.Nombre = JSON_Pivote.NombreConsorcio_JSON
        JOIN Tipo_Gasto TG ON TG.Nombre = 
            CASE 
                WHEN Gastos_Unpivot.Tipo_Nombre LIKE 'SERVICIOS PUBLICOS%' THEN 'SERVICIOS PUBLICOS'
                ELSE Gastos_Unpivot.Tipo_Nombre 
            END
        
        WHERE Gastos_Unpivot.Importe_JSON IS NOT NULL 
          AND MesNumero.MesN IS NOT NULL; 

        
        -- INSERTAR
        PRINT 'Insertando datos en Gasto_Ordinario...';

        MERGE INTO Gasto_Ordinario AS T
        USING #TempGastos AS S
        ON (T.Id_Consorcio = S.Id_Consorcio AND T.Id_Tipo_Gasto = S.Id_Tipo_Gasto AND T.Fecha = S.Fecha_Gasto)

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (Id_Consorcio, Id_Tipo_Gasto, Fecha, Importe_Total, Descripcion)
            VALUES (S.Id_Consorcio, S.Id_Tipo_Gasto, S.Fecha_Gasto, S.Importe_Total, S.Descripcion_Gasto)
        
        WHEN MATCHED THEN
            UPDATE SET
                T.Importe_Total = S.Importe_Total,
                T.Descripcion = S.Descripcion_Gasto;
        
        PRINT 'Importaci�n de Gastos JSON completada.';

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo importar el archivo JSON.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH

    DROP TABLE #TempGastos;
    SET NOCOUNT OFF;
END
GO

PRINT '--- Stored Procedures Creados Exitosamente ---';
GO