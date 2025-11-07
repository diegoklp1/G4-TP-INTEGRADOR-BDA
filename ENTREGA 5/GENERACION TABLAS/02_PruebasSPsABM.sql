-- =========================================================
-- SCRIPT:  02_TestingABMs.sql (CORREGIDO)
-- PROPÓSITO: Pruebas de los SPs de ABM

-- Fecha de entrega:	07/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =========================================================
USE COM5600_G04;
GO

PRINT '=====================================================';
PRINT '-------------- INICIO DE PRUEBAS ABM ----------------';
PRINT '=====================================================';
GO

IF OBJECT_ID('tempdb..#TestIDs') IS NOT NULL
    DROP TABLE #TestIDs;

CREATE TABLE #TestIDs (
    ID_ADMIN_PRUEBA INT,
    ID_CONSORCIO_PRUEBA INT,
    ID_PERSONA_PRUEBA INT,
    ID_PROVEEDOR_PRUEBA INT
);

-- Insertamos los valores iniciales
INSERT INTO #TestIDs (ID_CONSORCIO_PRUEBA) VALUES (101);
GO

PRINT '--- 1. Probando ABM [Administracion] ---'
GO

PRINT 'Prueba 1.1: Intentar crear Admin con CUIT inválido (debe fallar).'
GO
BEGIN TRY
    EXEC sp_CrearAdministracion
        @Razon_Social = 'Admin Falla',
        @CUIT = '12345', -- CUIT Inválido
        @Direccion = 'Calle Falsa 123',
        @Telefono = '555-1234',
        @Email = 'test@test.com',
        @Cuenta_Deposito = '0110022003300440055006',
        @Precio_Cochera_Default = 5000,
        @Precio_Baulera_Default = 2000;
END TRY
BEGIN CATCH
    PRINT '-> PRUEBA 1.1 PASÓ. Error esperado: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'Prueba 1.2: Crear una Administración VÁLIDA.'
GO
EXEC sp_CrearAdministracion
    @Razon_Social = 'AdminPrueba S.A.',
    @CUIT = '30-11223344-5',
    @Direccion = 'Av. de Prueba 789',
    @Telefono = '555-4321',
    @Email = 'contacto@adminprueba.com',
    @Cuenta_Deposito = '1110002220003330004445',
    @Precio_Cochera_Default = 10000,
    @Precio_Baulera_Default = 3000;
GO

-- Obtenemos y guardamos el ID en la tabla temporal
UPDATE #TestIDs
SET ID_ADMIN_PRUEBA = (SELECT Id_Administracion FROM Administracion WHERE CUIT = '30-11223344-5');

-- Declaramos la variable para el ID
DECLARE @AdminID_Prueba1 INT;
SELECT @AdminID_Prueba1 = ID_ADMIN_PRUEBA FROM #TestIDs;

PRINT '-> Administración de prueba creada con ID: ' + CAST(@AdminID_Prueba1 AS VARCHAR);
SELECT * FROM Administracion WHERE Id_Administracion = @AdminID_Prueba1;
GO


PRINT 'Prueba 1.3: Modificar la Administración VÁLIDA.'
GO

-- << CORRECCIÓN LÓGICA: Usar la variable de Admin, no la de Consorcio >>
DECLARE @AdminID_Prueba2 INT;
SELECT @AdminID_Prueba2 = ID_ADMIN_PRUEBA FROM #TestIDs;

EXEC sp_ModificarAdministracion
    @Id_Administracion = @AdminID_Prueba2, -- <-- CORREGIDO
    @Razon_Social = 'AdminPrueba S.A. (Modificada)',
    @CUIT = '30-11223344-5',
    @Direccion = 'Av. de Prueba 789 - Oficina 2', 
    @Telefono = '555-9999', 
    @Email = 'contacto@adminprueba.com',
    @Cuenta_Deposito = '1110002220003330004445',
    @Precio_Cochera_Default = 11000, 
    @Precio_Baulera_Default = 3300;
GO

PRINT '-> Verificando modificación:';
DECLARE @AdminID_Prueba3 INT;
SELECT @AdminID_Prueba3 = ID_ADMIN_PRUEBA FROM #TestIDs;
SELECT * FROM Administracion WHERE Id_Administracion = @AdminID_Prueba3;
GO

---------------------------------------------
--- 2. Pruebas ABM [Consorcio]
---------------------------------------------
PRINT '--- 2. Probando ABM [Consorcio] ---'
GO

PRINT 'Prueba 2.1: Intentar crear Consorcio con Admin ID inválido (debe fallar).'
GO

-- << CORRECCIÓN SINTAXIS: Usar variable para el parámetro >>
DECLARE @ConsorcioID_Prueba1 INT;
SELECT @ConsorcioID_Prueba1 = ID_CONSORCIO_PRUEBA FROM #TestIDs;

BEGIN TRY
    EXEC sp_CrearConsorcio
        @Id_Consorcio = @ConsorcioID_Prueba1, -- <-- CORREGIDO
        @Id_Administracion = 99999, 
        @Nombre = 'Consorcio Falla',
        @Domicilio = 'Dir Falla 123',
        @Cant_unidades = 10,
        @MetrosCuadrados = 1000,
        @Precio_Cochera = 0,
        @Precio_Baulera = 0;
END TRY
BEGIN CATCH
    PRINT '-> PRUEBA 2.1 PASÓ. Error esperado: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'Prueba 2.2: Crear un Consorcio VÁLIDO (asociado a la Admin de prueba).'
GO

-- << CORRECCIÓN SINTAXIS: Usar variables para los parámetros >>
DECLARE @ConsorcioID_Prueba2 INT, @AdminID_Prueba4 INT;
SELECT @ConsorcioID_Prueba2 = ID_CONSORCIO_PRUEBA, @AdminID_Prueba4 = ID_ADMIN_PRUEBA FROM #TestIDs;

EXEC sp_CrearConsorcio
    @Id_Consorcio = @ConsorcioID_Prueba2, -- <-- CORREGIDO
    @Id_Administracion = @AdminID_Prueba4, -- <-- CORREGIDO
    @Nombre = 'Consorcio Las Pruebas I',
    @Domicilio = 'Calle del Consorcio 456',
    @Cant_unidades = 20,
    @MetrosCuadrados = 2500,
    @Precio_Cochera = 12000,
    @Precio_Baulera = 4000;
GO

PRINT '-> Verificando creación:';
DECLARE @ConsorcioID_Prueba3 INT;
SELECT @ConsorcioID_Prueba3 = ID_CONSORCIO_PRUEBA FROM #TestIDs;
SELECT * FROM Consorcio WHERE Id_Consorcio = @ConsorcioID_Prueba3;
GO

PRINT 'Prueba 2.3: Modificar el Consorcio VÁLIDO.'
GO

-- << CORRECCIÓN SINTAXIS: Usar variables para los parámetros >>
DECLARE @ConsorcioID_Prueba4 INT, @AdminID_Prueba5 INT;
SELECT @ConsorcioID_Prueba4 = ID_CONSORCIO_PRUEBA, @AdminID_Prueba5 = ID_ADMIN_PRUEBA FROM #TestIDs;

EXEC sp_ModificarConsorcio
    @Id_Consorcio = @ConsorcioID_Prueba4, -- <-- CORREGIDO
    @Id_Administracion = @AdminID_Prueba5, -- <-- CORREGIDO
    @Nombre = 'Consorcio Las Pruebas I (Modificado)', 
    @Domicilio = 'Calle del Consorcio 456, CABA', 
    @Cant_unidades = 22, 
    @MetrosCuadrados = 2500,
    @Precio_Cochera = 12500,
    @Precio_Baulera = 4500;
GO

PRINT '-> Verificando modificación:';
DECLARE @ConsorcioID_Prueba5 INT;
SELECT @ConsorcioID_Prueba5 = ID_CONSORCIO_PRUEBA FROM #TestIDs;
SELECT * FROM Consorcio WHERE Id_Consorcio = @ConsorcioID_Prueba5;
GO

---------------------------------------------
--- 3. Prueba de Borrado con Dependencia (Admin -> Consorcio)
---------------------------------------------
PRINT '--- 3. Probando Borrado con Dependencia (Admin -> Consorcio) ---'
GO

PRINT 'Prueba 3.1: Intentar borrar Admin (tiene Consorcio). Debe fallar (Validación de SP).'
GO

-- << CORRECCIÓN SINTAXIS: Usar variable para el parámetro >>
DECLARE @AdminID_Prueba6 INT;
SELECT @AdminID_Prueba6 = ID_ADMIN_PRUEBA FROM #TestIDs;

BEGIN TRY
    EXEC sp_BorrarAdministracion
        @Id_Administracion = @AdminID_Prueba6; -- <-- CORREGIDO
END TRY
BEGIN CATCH
    PRINT '-> PRUEBA 3.1 PASÓ. Error esperado: ' + ERROR_MESSAGE();
END CATCH
GO

---------------------------------------------
--- 4. Pruebas ABM [Proveedor]
---------------------------------------------
PRINT '--- 4. Probando ABM [Proveedor] ---'
GO

PRINT 'Prueba 4.1: Crear un Proveedor VÁLIDO (asociado al Consorcio de prueba).'
GO

-- << CORRECCIÓN SINTAXIS: Usar variable para el parámetro >>
DECLARE @ConsorcioID_Prueba6 INT;
SELECT @ConsorcioID_Prueba6 = ID_CONSORCIO_PRUEBA FROM #TestIDs;

EXEC sp_CrearProveedor
    @Id_Consorcio = @ConsorcioID_Prueba6, -- <-- CORREGIDO
    @Nombre_Gasto = 'Electricista Prueba',
    @Descripcion = 'Mantenimiento eléctrico general',
    @Cuenta = '0001112223334445556667';
GO

-- Obtenemos y guardamos el ID del proveedor creado
UPDATE #TestIDs
SET ID_PROVEEDOR_PRUEBA = (SELECT Id_Proveedor
                            FROM Proveedor
                            WHERE Nombre_Gasto = 'Electricista Prueba'
                            AND Id_Consorcio = (SELECT ID_CONSORCIO_PRUEBA FROM #TestIDs));

DECLARE @ProveedorID_Prueba1 INT;
SELECT @ProveedorID_Prueba1 = ID_PROVEEDOR_PRUEBA FROM #TestIDs;

PRINT '-> Proveedor de prueba creado con ID: ' + CAST(@ProveedorID_Prueba1 AS VARCHAR);
SELECT * FROM Proveedor WHERE Id_Proveedor = @ProveedorID_Prueba1;
GO

PRINT 'Prueba 4.2: Modificar el Proveedor VÁLIDO.'
GO

-- << CORRECCIÓN SINTAXIS: Usar variables para los parámetros >>
DECLARE @ProveedorID_Prueba2 INT, @ConsorcioID_Prueba7 INT;
SELECT @ProveedorID_Prueba2 = ID_PROVEEDOR_PRUEBA, @ConsorcioID_Prueba7 = ID_CONSORCIO_PRUEBA FROM #TestIDs;

EXEC sp_ModificarProveedor
    @Id_Proveedor = @ProveedorID_Prueba2, -- <-- CORREGIDO
    @Id_Consorcio = @ConsorcioID_Prueba7, -- <-- CORREGIDO
    @Nombre_Gasto = 'Electricista Matriculado Prueba', 
    @Descripcion = 'Mantenimiento eléctrico general y ascensores',
    @Cuenta = '9998887776665554443332';
GO

PRINT '-> Verificando modificación:';
DECLARE @ProveedorID_Prueba3 INT;
SELECT @ProveedorID_Prueba3 = ID_PROVEEDOR_PRUEBA FROM #TestIDs;
SELECT * FROM Proveedor WHERE Id_Proveedor = @ProveedorID_Prueba3;
GO

---------------------------------------------
--- 5. Pruebas ABM [Persona]
---------------------------------------------
PRINT '--- 5. Probando ABM [Persona] ---'
GO

PRINT 'Prueba 5.1: Crear una Persona VÁLIDA (Propietario 1).'
GO
BEGIN TRY
    EXEC sp_CrearPersona
        @Nombre = 'Juan',
        @Apellido = 'Perez',
        @DNI = '30111222',
        @Email = 'jperez@mail.com',
        @Telefono = '+54 (11) 5555 1111',
        @Cbu_Cvu = '0123456789012345678901',
        @inquilino = 0;
END TRY
BEGIN CATCH
    PRINT '-> ERROR INESPERADO EN PRUEBA 5.1: ' + ERROR_MESSAGE();
END CATCH
GO

-- Obtenemos y guardamos el ID de la persona creada
UPDATE #TestIDs
SET ID_PERSONA_PRUEBA = (SELECT Id_Persona FROM Persona WHERE DNI = '30111222');

DECLARE @PersonaID_Prueba1 INT;
SELECT @PersonaID_Prueba1 = ID_PERSONA_PRUEBA FROM #TestIDs;

PRINT '-> Persona de prueba creada con ID: ' + CAST(@PersonaID_Prueba1 AS VARCHAR);
SELECT * FROM Persona WHERE Id_Persona = @PersonaID_Prueba1;
GO

PRINT 'Prueba 5.2: Intentar crear Persona con DNI duplicado (debe fallar).'
GO
BEGIN TRY
    EXEC sp_CrearPersona
        @Nombre = 'Otro',
        @Apellido = 'Nombre',
        @DNI = '30111222', -- DNI Duplicado
        @Email = 'otro@mail.com',
        @Telefono = '(11) 4444 3333',
        @Cbu_Cvu = '0987654321098765432109',
        @inquilino = 0;
END TRY
BEGIN CATCH
    PRINT '-> PRUEBA 5.2 PASÓ. Error esperado: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'Prueba 5.3: Modificar la Persona VÁLIDA.'
GO

-- << CORRECCIÓN SINTAXIS: Usar variable para el parámetro >>
DECLARE @PersonaID_Prueba2 INT;
SELECT @PersonaID_Prueba2 = ID_PERSONA_PRUEBA FROM #TestIDs;

EXEC sp_ModificarPersona
    @Id_Persona = @PersonaID_Prueba2, -- <-- CORREGIDO
    @DNI = '30111222',
    @Nombre = 'Juan Ignacio', 
    @Apellido = 'Perez',
    @Email = 'juan.perez.nuevo@mail.com',
    @Telefono = '+54 (11) 5555 3333',
    @inquilino = 0,
    @Cbu_Cvu = '0123456789012345678901';
GO

PRINT '-> Verificando modificación:';
DECLARE @PersonaID_Prueba3 INT;
SELECT @PersonaID_Prueba3 = ID_PERSONA_PRUEBA FROM #TestIDs;
SELECT * FROM Persona WHERE Id_Persona = @PersonaID_Prueba3;
GO

---------------------------------------------
--- 6. Pruebas ABM [Unidad_Funcional]
---------------------------------------------
PRINT '--- 6. Probando ABM [Unidad_Funcional] ---'
GO

PRINT 'Prueba 6.1: Crear una UF VÁLIDA (UF "1" en Consorcio 101).'
GO

-- << CORRECCIÓN SINTAXIS: Usar variable para el parámetro >>
DECLARE @ConsorcioID_Prueba8 INT;
SELECT @ConsorcioID_Prueba8 = ID_CONSORCIO_PRUEBA FROM #TestIDs;

EXEC sp_CrearUnidadFuncional
    @Id_Consorcio = @ConsorcioID_Prueba8, 
    @NroUF = '1', 
    @Piso = 'PB',
    @Departamento = 'A',
    @Coeficiente = 5.25,
    @M2_UF = 50,
    @Baulera = 1,
    @Cochera = 1,
    @M2_Baulera = 5,
    @M2_Cochera = 15;
GO

PRINT '-> Verificando creación:';
DECLARE @ConsorcioID_Prueba9 INT;
SELECT @ConsorcioID_Prueba9 = ID_CONSORCIO_PRUEBA FROM #TestIDs;
SELECT * FROM Unidad_Funcional WHERE Id_Consorcio = @ConsorcioID_Prueba9 AND NroUf = '1'; 
GO

PRINT 'Prueba 6.2: Intentar crear UF con PK duplicada (mismo Consorcio, mismo NroUF). Debe fallar.'
GO


DECLARE @ConsorcioID_Prueba10 INT;
SELECT @ConsorcioID_Prueba10 = ID_CONSORCIO_PRUEBA FROM #TestIDs;

BEGIN TRY
    EXEC sp_CrearUnidadFuncional
        @Id_Consorcio = @ConsorcioID_Prueba10, 
        @NroUF = '1', 
        @Piso = '1',
        @Departamento = 'B',
        @Coeficiente = 3.00,
        @M2_UF = 40,
        @Baulera = 0,
        @Cochera = 0,
        @M2_Baulera = 0,
        @M2_Cochera = 0;
END TRY
BEGIN CATCH
    PRINT '-> PRUEBA 6.2 PASÓ. Error esperado: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'Prueba 6.3: Modificar la UF VÁLIDA.'
GO

-- << CORRECCIÓN SINTAXIS: Usar variable para el parámetro >>
DECLARE @ConsorcioID_Prueba11 INT;
SELECT @ConsorcioID_Prueba11 = ID_CONSORCIO_PRUEBA FROM #TestIDs;

EXEC sp_ModificarUnidadFuncional
    @Id_Consorcio = @ConsorcioID_Prueba11,
    @NroUF = '1', 
    @Piso = 'PB',
    @Departamento = 'A',
    @Coeficiente = 5.50, 
    @M2_UF = 52, 
    @Baulera = 1,
    @Cochera = 1,
    @M2_Baulera = 5,
    @M2_Cochera = 15;
GO

PRINT '-> Verificando modificación:';
DECLARE @ConsorcioID_Prueba12 INT;
SELECT @ConsorcioID_Prueba12 = ID_CONSORCIO_PRUEBA FROM #TestIDs;
SELECT * FROM Unidad_Funcional WHERE Id_Consorcio = @ConsorcioID_Prueba12 AND NroUf = '1'; -- <-- CORRECCIÓN TIPO DATO
GO


/* 
--- 7. Pruebas de Borrado en Orden (Limpieza)
---------------------------------------------
PRINT '--- 7. Pruebas de Borrado en Orden (Limpieza) ---'
GO

PRINT 'Prueba 7.1: Intentar borrar Consorcio 101 (tiene UF y Proveedor). Debe fallar.'
GO

DECLARE @ConsorcioID_Prueba13 INT;
SELECT @ConsorcioID_Prueba13 = ID_CONSORCIO_PRUEBA FROM #TestIDs;

BEGIN TRY
    EXEC sp_BorrarConsorcio
        @Id_Consorcio = @ConsorcioID_Prueba13;
END TRY
BEGIN CATCH
    PRINT '-> PRUEBA 7.1 PASÓ. Error esperado: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'Prueba 7.2: Borrar UF (Hijo de Consorcio).'
GO

DECLARE @ConsorcioID_Prueba14 INT;
SELECT @ConsorcioID_Prueba14 = ID_CONSORCIO_PRUEBA FROM #TestIDs;

EXEC sp_BorrarUnidadFuncional
    @Id_Consorcio = @ConsorcioID_Prueba14,
    @NroUF = '1'; -- <-- CORRECCIÓN TIPO DATO
GO
PRINT '-> UF Borrada. Verificando...';
DECLARE @ConsorcioID_Prueba15 INT;
SELECT @ConsorcioID_Prueba15 = ID_CONSORCIO_PRUEBA FROM #TestIDs;
SELECT * FROM Unidad_Funcional WHERE Id_Consorcio = @ConsorcioID_Prueba15 AND NroUf = '1';
GO

PRINT 'Prueba 7.3: Borrar Persona (Independiente, no asociada).'
GO

DECLARE @PersonaID_Prueba4 INT;
SELECT @PersonaID_Prueba4 = ID_PERSONA_PRUEBA FROM #TestIDs;

EXEC sp_BorrarPersona
    @Id_Persona = @PersonaID_Prueba4;
GO
PRINT '-> Persona Borrada. Verificando...';
DECLARE @PersonaID_Prueba5 INT;
SELECT @PersonaID_Prueba5 = ID_PERSONA_PRUEBA FROM #TestIDs;
SELECT * FROM Persona WHERE Id_Persona = @PersonaID_Prueba5;
GO

PRINT 'Prueba 7.4: Borrar Proveedor (Hijo de Consorcio).'
GO

DECLARE @ProveedorID_Prueba4 INT;
SELECT @ProveedorID_Prueba4 = ID_PROVEEDOR_PRUEBA FROM #TestIDs;

EXEC sp_BorrarProveedor
    @Id_Proveedor = @ProveedorID_Prueba4;
GO
PRINT '-> Proveedor Borrado. Verificando...';
DECLARE @ProveedorID_Prueba5 INT;
SELECT @ProveedorID_Prueba5 = ID_PROVEEDOR_PRUEBA FROM #TestIDs;
SELECT * FROM Proveedor WHERE Id_Proveedor = @ProveedorID_Prueba5;
GO

PRINT 'Prueba 7.5: Borrar Consorcio 101 (ahora vacío). Debe funcionar.'
GO

DECLARE @ConsorcioID_Prueba16 INT;
SELECT @ConsorcioID_Prueba16 = ID_CONSORCIO_PRUEBA FROM #TestIDs;

EXEC sp_BorrarConsorcio
    @Id_Consorcio = @ConsorcioID_Prueba16;
GO
PRINT '-> Consorcio Borrado. Verificando...';
DECLARE @ConsorcioID_Prueba17 INT;
SELECT @ConsorcioID_Prueba17 = ID_CONSORCIO_PRUEBA FROM #TestIDs;
SELECT * FROM Consorcio WHERE Id_Consorcio = @ConsorcioID_Prueba17;
GO

PRINT 'Prueba 7.6: Borrar Admin (ahora vacío). Debe funcionar.'
GO

DECLARE @AdminID_Prueba7 INT;
SELECT @AdminID_Prueba7 = ID_ADMIN_PRUEBA FROM #TestIDs;

EXEC sp_BorrarAdministracion
    @Id_Administracion = @AdminID_Prueba7;
GO
PRINT '-> Administración Borrada. Verificando...';
DECLARE @AdminID_Prueba8 INT;
SELECT @AdminID_Prueba8 = ID_ADMIN_PRUEBA FROM #TestIDs;
SELECT * FROM Administracion WHERE Id_Administracion = @AdminID_Prueba8;
GO


PRINT '=====================================================';
PRINT '--- FIN DE PRUEBAS ABM ---';
PRINT '--- Todas las tablas de prueba deben estar vacías ---';
PRINT '=====================================================';
GO

-- Verificación final de limpieza
SELECT 'Administracion' as Tabla, COUNT(*) as Filas FROM Administracion WHERE Id_Administracion = (SELECT ID_ADMIN_PRUEBA FROM #TestIDs);
SELECT 'Consorcio' as Tabla, COUNT(*) as Filas FROM Consorcio WHERE Id_Consorcio = (SELECT ID_CONSORCIO_PRUEBA FROM #TestIDs);
SELECT 'Proveedor' as Tabla, COUNT(*) as Filas FROM Proveedor WHERE Id_Proveedor = (SELECT ID_PROVEEDOR_PRUEBA FROM #TestIDs);
SELECT 'Persona' as Tabla, COUNT(*) as Filas FROM Persona WHERE Id_Persona = (SELECT ID_PERSONA_PRUEBA FROM #TestIDs);
SELECT 'Unidad_Funcional' as Tabla, COUNT(*) as Filas FROM Unidad_Funcional WHERE Id_Consorcio = (SELECT ID_CONSORCIO_PRUEBA FROM #TestIDs);
GO

*/ -- << COMENTAR HASTA AQUÍ

-- Limpieza final de la tabla temporal
DROP TABLE #TestIDs;
GO