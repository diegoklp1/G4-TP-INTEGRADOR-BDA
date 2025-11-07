-- =========================================================
-- SCRIPT: 01_CreacionSPsABM.sql
-- PROPÓSITO:Crea todos los SPs de Alta, Baja y Modificación de las entidades principales.

-- Fecha de entrega:	07/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =========================================================

USE master
GO 

USE COM5600_G04;
GO

PRINT '--- Creando ABM de [Administracion] ---'
GO

-------------------------------
-- Para Tabla Administracion --
-------------------------------

-- 1. ALTA 
IF OBJECT_ID('sp_CrearAdministracion') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_CrearAdministracion;
END
GO

CREATE PROCEDURE sp_CrearAdministracion
    @Razon_Social VARCHAR(100),
    @CUIT VARCHAR(20),
    @Direccion VARCHAR(100),
    @Telefono VARCHAR(20),
    @Email VARCHAR(100),
    @Cuenta_Deposito VARCHAR(22),
    @Precio_Cochera_Default decimal(9,2),
    @Precio_Baulera_Default decimal(9,2)
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        -- Limpieza de parámetros
        SET @Razon_Social = TRIM(ISNULL(@Razon_Social, ''));
        SET @CUIT = TRIM(ISNULL(@CUIT, ''));
        SET @Direccion = TRIM(ISNULL(@Direccion, ''));
        SET @Telefono = TRIM(ISNULL(@Telefono, ''));
        SET @Email = TRIM(ISNULL(@Email, ''));
        SET @Cuenta_Deposito = TRIM(ISNULL(@Cuenta_Deposito, ''));

        -- Validaciones
        IF @Razon_Social = ''
            RAISERROR('La Razón Social no puede estar vacía.', 16, 1);
        IF @CUIT = '' OR @CUIT LIKE '%[^0-9-]%' OR LEN(@CUIT) <> 13 
            RAISERROR('El CUIT no es válido. Debe tener formato XX-XXXXXXXX-X.', 16, 1);
        IF @Email = '' OR @Email NOT LIKE '%_@_%._%'
            RAISERROR('El Email no es válido.', 16, 1);
        IF @Cuenta_Deposito = '' OR @Cuenta_Deposito LIKE '%[^0-9]%' OR LEN(@Cuenta_Deposito) <> 22
            RAISERROR('La Cuenta de Depósito (CBU) no es válida. Debe tener 22 dígitos numéricos.', 16, 1);
        IF @Precio_Cochera_Default < 0 OR @Precio_Baulera_Default < 0
            RAISERROR('Los precios default no pueden ser negativos.', 16, 1);

        INSERT INTO Administracion
            (Razon_Social, CUIT, Direccion, Telefono, Email, Cuenta_Deposito, Precio_Cochera_Default, Precio_Baulera_Default)
        VALUES
            (@Razon_Social, @CUIT, @Direccion, @Telefono, @Email, @Cuenta_Deposito, @Precio_Cochera_Default, @Precio_Baulera_Default);
        
        -- Devolvemos el ID recién creado
        SELECT SCOPE_IDENTITY() AS Id_Administracion_Nueva;

    END TRY
    BEGIN CATCH
        THROW; 
    END CATCH
END
GO

-- 2. MODIFICACIÓN
IF OBJECT_ID('sp_ModificarAdministracion') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ModificarAdministracion;
END
GO

CREATE PROCEDURE sp_ModificarAdministracion
    @Id_Administracion INT,
    @Razon_Social VARCHAR(100),
    @CUIT VARCHAR(20),
    @Direccion VARCHAR(100),
    @Telefono VARCHAR(20),
    @Email VARCHAR(100),
    @Cuenta_Deposito VARCHAR(22),
    @Precio_Cochera_Default decimal(9,2),
    @Precio_Baulera_Default decimal(9,2)
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        -- Validar existencia
        IF NOT EXISTS (SELECT 1 FROM Administracion WHERE Id_Administracion = @Id_Administracion)
            RAISERROR('La administración con el ID %d no existe.', 16, 1, @Id_Administracion);

        -- Limpieza de parámetros
        SET @Razon_Social = TRIM(ISNULL(@Razon_Social, ''));
        SET @CUIT = TRIM(ISNULL(@CUIT, ''));
        SET @Direccion = TRIM(ISNULL(@Direccion, ''));
        SET @Telefono = TRIM(ISNULL(@Telefono, ''));
        SET @Email = TRIM(ISNULL(@Email, ''));
        SET @Cuenta_Deposito = TRIM(ISNULL(@Cuenta_Deposito, ''));

        -- Validaciones
        IF @Razon_Social = ''
            RAISERROR('La Razón Social no puede estar vacía.', 16, 1);
        IF @CUIT = '' OR @CUIT LIKE '%[^0-9-]%' OR LEN(@CUIT) NOT BETWEEN 13 AND 13
            RAISERROR('El CUIT no es válido. Debe tener formato XX-XXXXXXXX-X.', 16, 1);
        IF @Email = '' OR @Email NOT LIKE '%_@_%._%'
            RAISERROR('El Email no es válido.', 16, 1);
        IF @Cuenta_Deposito = '' OR @Cuenta_Deposito LIKE '%[^0-9]%' OR LEN(@Cuenta_Deposito) <> 22
            RAISERROR('La Cuenta de Depósito (CBU) no es válida. Debe tener 22 dígitos numéricos.', 16, 1);
        IF @Precio_Cochera_Default < 0 OR @Precio_Baulera_Default < 0
            RAISERROR('Los precios default no pueden ser negativos.', 16, 1);

        UPDATE Administracion
        SET
            Razon_Social = @Razon_Social,
            CUIT = @CUIT,
            Direccion = @Direccion,
            Telefono = @Telefono,
            Email = @Email,
            Cuenta_Deposito = @Cuenta_Deposito,
            Precio_Cochera_Default = @Precio_Cochera_Default,
            Precio_Baulera_Default = @Precio_Baulera_Default   
        WHERE
            Id_Administracion = @Id_Administracion;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 3. BAJA 
IF OBJECT_ID('sp_BorrarAdministracion') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_BorrarAdministracion;
END
GO

CREATE PROCEDURE sp_BorrarAdministracion
    @Id_Administracion INT
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        -- Validar existencia
        IF NOT EXISTS (SELECT 1 FROM Administracion WHERE Id_Administracion = @Id_Administracion)
            RAISERROR('La administración con el ID %d no existe.', 16, 1, @Id_Administracion);

        -- Validación: No puedo borrar si tiene consorcios asociados.
        IF EXISTS (SELECT 1 FROM Consorcio WHERE Id_Administracion = @Id_Administracion)
        BEGIN
            RAISERROR ('No se puede borrar la administración porque tiene consorcios asociados.', 16, 1);
        END

        -- Si pasa la validación, borra
        DELETE FROM Administracion
        WHERE Id_Administracion = @Id_Administracion;
        
        PRINT 'Administración borrada exitosamente.';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 4. LECTURA PARA 1
IF OBJECT_ID('sp_GetAdministracionPorID') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_GetAdministracionPorID;
END
GO

CREATE PROCEDURE sp_GetAdministracionPorID
    @Id_Administracion INT
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        SELECT * FROM Administracion 
        WHERE Id_Administracion = @Id_Administracion;

        IF @@ROWCOUNT = 0
            RAISERROR('No se encontró la administración con ID %d.', 16, 1, @Id_Administracion);
            
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 5. LECTURA PARA N
IF OBJECT_ID('sp_ListarAdministraciones') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ListarAdministraciones;
END
GO

CREATE PROCEDURE sp_ListarAdministraciones
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        SELECT Id_Administracion, Razon_Social, CUIT, Telefono, Email 
        FROM Administracion 
        ORDER BY Razon_Social;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

---------------------------
-- Para Tabla Consorcio --
---------------------------

PRINT '--- Creando ABMC de [Consorcio] ---'
GO

-- 1. ALTA 
IF OBJECT_ID('sp_CrearConsorcio') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_CrearConsorcio;
END
GO

CREATE PROCEDURE sp_CrearConsorcio
    @Id_Consorcio INT,          
    @Id_Administracion INT,
    @Nombre VARCHAR(100),
    @Domicilio VARCHAR(100),
    @Cant_unidades SMALLINT,
    @MetrosCuadrados INT,
    @Precio_Cochera DECIMAL(9, 2),
    @Precio_Baulera DECIMAL(9, 2)
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        -- Limpieza
        SET @Nombre = TRIM(ISNULL(@Nombre, ''));
        SET @Domicilio = TRIM(ISNULL(@Domicilio, ''));

        -- Validaciones
        IF @Id_Consorcio <= 0
            RAISERROR('El ID de Consorcio debe ser un número positivo.', 16, 1);
        IF NOT EXISTS (SELECT 1 FROM Administracion WHERE Id_Administracion = @Id_Administracion)
            RAISERROR('La administración con ID %d no existe.', 16, 1, @Id_Administracion);
        IF @Nombre = ''
            RAISERROR('El Nombre no puede estar vacío.', 16, 1);
        IF @Cant_unidades <= 0 OR @MetrosCuadrados <= 0
            RAISERROR('La cantidad de unidades y los M2 deben ser mayores a 0.', 16, 1);
        IF @Precio_Cochera < 0 OR @Precio_Baulera < 0
            RAISERROR('Los precios no pueden ser negativos.', 16, 1);
        IF EXISTS (SELECT 1 FROM Consorcio WHERE Id_Consorcio = @Id_Consorcio)
            RAISERROR ('El Id_Consorcio %d ya existe.', 16, 1, @Id_Consorcio);

        INSERT INTO Consorcio
            (Id_Consorcio, Id_Administracion, Nombre, Domicilio, Cant_unidades, MetrosCuadrados, Precio_Cochera, Precio_Baulera)
        VALUES
            (@Id_Consorcio, @Id_Administracion, @Nombre, @Domicilio, @Cant_unidades, @MetrosCuadrados, @Precio_Cochera, @Precio_Baulera);
        
        PRINT 'Consorcio creado exitosamente.';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 2. MODIFICACIÓN 
IF OBJECT_ID('sp_ModificarConsorcio') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ModificarConsorcio;
END
GO

CREATE PROCEDURE sp_ModificarConsorcio
    @Id_Consorcio INT,
    @Id_Administracion INT,
    @Nombre VARCHAR(100),
    @Domicilio VARCHAR(100),
    @Cant_unidades SMALLINT,
    @MetrosCuadrados INT,
    @Precio_Cochera DECIMAL(9, 2),
    @Precio_Baulera DECIMAL(9, 2)
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        -- Validar existencia
        IF NOT EXISTS (SELECT 1 FROM Consorcio WHERE Id_Consorcio = @Id_Consorcio)
            RAISERROR('El consorcio con ID %d no existe.', 16, 1, @Id_Consorcio);

        -- Limpieza
        SET @Nombre = TRIM(ISNULL(@Nombre, ''));
        SET @Domicilio = TRIM(ISNULL(@Domicilio, ''));

        -- Validaciones
        IF NOT EXISTS (SELECT 1 FROM Administracion WHERE Id_Administracion = @Id_Administracion)
            RAISERROR('La administración con ID %d no existe.', 16, 1, @Id_Administracion);
        IF @Nombre = ''
            RAISERROR('El Nombre no puede estar vacío.', 16, 1);
        IF @Cant_unidades <= 0 OR @MetrosCuadrados <= 0
            RAISERROR('La cantidad de unidades y los M2 deben ser mayores a 0.', 16, 1);
        IF @Precio_Cochera < 0 OR @Precio_Baulera < 0
            RAISERROR('Los precios no pueden ser negativos.', 16, 1);
            
        UPDATE Consorcio
        SET
            Id_Administracion = @Id_Administracion,
            Nombre = @Nombre,
            Domicilio = @Domicilio,
            Cant_unidades = @Cant_unidades,
            MetrosCuadrados = @MetrosCuadrados,
            Precio_Cochera = @Precio_Cochera,
            Precio_Baulera = @Precio_Baulera
        WHERE
            Id_Consorcio = @Id_Consorcio;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 3. BAJA 
IF OBJECT_ID('sp_BorrarConsorcio') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_BorrarConsorcio;
END
GO

CREATE PROCEDURE sp_BorrarConsorcio
    @Id_Consorcio INT
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        -- Validar existencia
        IF NOT EXISTS (SELECT 1 FROM Consorcio WHERE Id_Consorcio = @Id_Consorcio)
            RAISERROR('El consorcio con ID %d no existe.', 16, 1, @Id_Consorcio);
        
        -- Validación (No borrar si tiene historial o UFs)
        IF EXISTS (SELECT 1 FROM Unidad_Funcional WHERE Id_Consorcio = @Id_Consorcio)
            RAISERROR ('No se puede borrar el consorcio porque tiene Unidades Funcionales asociadas.', 16, 1);
        
        IF EXISTS (SELECT 1 FROM Gasto_Ordinario WHERE Id_Consorcio = @Id_Consorcio)
            RAISERROR ('No se puede borrar el consorcio porque tiene Gastos Ordinarios asociados.', 16, 1);
        
        IF EXISTS (SELECT 1 FROM Gasto_Extraordinario WHERE Id_Consorcio = @Id_Consorcio)
            RAISERROR ('No se puede borrar el consorcio porque tiene Gastos Extraordinarios asociados.', 16, 1);

        IF EXISTS (SELECT 1 FROM Liquidacion_Mensual WHERE Id_Consorcio = @Id_Consorcio)
            RAISERROR ('No se puede borrar el consorcio porque tiene Liquidaciones (expensas) asociadas.', 16, 1);

        -- Si pasa las validaciones, borra las dependencias "no críticas"
        DELETE FROM Proveedor WHERE Id_Consorcio = @Id_Consorcio;
        DELETE FROM Estado_Financiero WHERE Id_Consorcio = @Id_Consorcio;
        
        -- Borra el consorcio
        DELETE FROM Consorcio
        WHERE Id_Consorcio = @Id_Consorcio;
        
        PRINT 'Consorcio borrado exitosamente.';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO


-- 4. LECTURA PARA 1
IF OBJECT_ID('sp_GetConsorcioPorID') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_GetConsorcioPorID;
END
GO

CREATE PROCEDURE sp_GetConsorcioPorID
    @Id_Consorcio INT
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        SELECT C.*, A.Razon_Social AS Administracion_Nombre
        FROM Consorcio C
        INNER JOIN Administracion A ON C.Id_Administracion = A.Id_Administracion
        WHERE C.Id_Consorcio = @Id_Consorcio;

        IF @@ROWCOUNT = 0
            RAISERROR('No se encontró el consorcio con ID %d.', 16, 1, @Id_Consorcio);

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 5. LECTURA PARA N
IF OBJECT_ID('sp_ListarConsorcios') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ListarConsorcios;
END
GO

CREATE PROCEDURE sp_ListarConsorcios
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        SELECT C.Id_Consorcio, C.Nombre, C.Domicilio, A.Razon_Social AS Administracion_Nombre
        FROM Consorcio C
        INNER JOIN Administracion A ON C.Id_Administracion = A.Id_Administracion
        ORDER BY C.Nombre;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

------------------------
-- Para Tabla Proveedor --
------------------------

PRINT '--- Creando ABMC de [Proveedor] ---'
GO

-- 1. ALTA 
IF OBJECT_ID('sp_CrearProveedor') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_CrearProveedor;
END
GO

CREATE PROCEDURE sp_CrearProveedor
    @Id_Consorcio INT,
    @Nombre_Gasto VARCHAR(60),
    @Descripcion VARCHAR(100),
    @Cuenta VARCHAR(50)
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        -- Limpieza
        SET @Nombre_Gasto = TRIM(ISNULL(@Nombre_Gasto, ''));
        SET @Descripcion = TRIM(ISNULL(@Descripcion, ''));
        SET @Cuenta = TRIM(ISNULL(@Cuenta, ''));

        -- Validaciones
        IF NOT EXISTS (SELECT 1 FROM Consorcio WHERE Id_Consorcio = @Id_Consorcio)
            RAISERROR('El consorcio con ID %d no existe.', 16, 1, @Id_Consorcio);
        IF @Nombre_Gasto = ''
            RAISERROR('El Nombre de Gasto no puede estar vacío.', 16, 1);
        IF @Cuenta = '' OR @Cuenta LIKE '%[^0-9]%' OR LEN(@Cuenta) > 22
            RAISERROR('La Cuenta no es válida. Debe ser numérica y de 22 dígitos o menos.', 16, 1);

        INSERT INTO Proveedor
            (Id_Consorcio, Nombre_Gasto, Descripcion, Cuenta)
        VALUES
            (@Id_Consorcio, @Nombre_Gasto, @Descripcion, @Cuenta);
        
        SELECT SCOPE_IDENTITY() AS Id_Proveedor_Nuevo;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 2. MODIFICACIÓN
IF OBJECT_ID('sp_ModificarProveedor') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ModificarProveedor;
END
GO

CREATE PROCEDURE sp_ModificarProveedor
    @Id_Proveedor INT,
    @Id_Consorcio INT,
    @Nombre_Gasto VARCHAR(60),
    @Descripcion VARCHAR(100),
    @Cuenta VARCHAR(50)
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        -- Validar existencia
        IF NOT EXISTS (SELECT 1 FROM Proveedor WHERE Id_Proveedor = @Id_Proveedor)
            RAISERROR('El proveedor con ID %d no existe.', 16, 1, @Id_Proveedor);
            
        -- Limpieza
        SET @Nombre_Gasto = TRIM(ISNULL(@Nombre_Gasto, ''));
        SET @Descripcion = TRIM(ISNULL(@Descripcion, ''));
        SET @Cuenta = TRIM(ISNULL(@Cuenta, ''));

        -- Validaciones
        IF NOT EXISTS (SELECT 1 FROM Consorcio WHERE Id_Consorcio = @Id_Consorcio)
            RAISERROR('El consorcio con ID %d no existe.', 16, 1, @Id_Consorcio);
        IF @Nombre_Gasto = ''
            RAISERROR('El Nombre de Gasto no puede estar vacío.', 16, 1);
        IF @Cuenta = '' OR @Cuenta LIKE '%[^0-9]%' OR LEN(@Cuenta) > 22
            RAISERROR('La Cuenta no es válida. Debe ser numérica y de 22 dígitos o menos.', 16, 1);

        UPDATE Proveedor
        SET
            Id_Consorcio = @Id_Consorcio,
            Nombre_Gasto = @Nombre_Gasto,
            Descripcion = @Descripcion,
            Cuenta = @Cuenta
        WHERE
            Id_Proveedor = @Id_Proveedor;
            
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 3. BAJA
IF OBJECT_ID('sp_BorrarProveedor') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_BorrarProveedor;
END
GO

CREATE PROCEDURE sp_BorrarProveedor
    @Id_Proveedor INT
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        -- Validar existencia
        IF NOT EXISTS (SELECT 1 FROM Proveedor WHERE Id_Proveedor = @Id_Proveedor)
            RAISERROR('El proveedor con ID %d no existe.', 16, 1, @Id_Proveedor);
            
        DELETE FROM Proveedor
        WHERE Id_Proveedor = @Id_Proveedor;
        
        PRINT 'Proveedor borrado exitosamente.';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 4. LECTURA PARA 1
IF OBJECT_ID('sp_GetProveedorPorID') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_GetProveedorPorID;
END
GO

CREATE PROCEDURE sp_GetProveedorPorID
    @Id_Proveedor INT
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        SELECT P.*, C.Nombre AS Consorcio_Nombre
        FROM Proveedor P
        INNER JOIN Consorcio C ON P.Id_Consorcio = C.Id_Consorcio
        WHERE P.Id_Proveedor = @Id_Proveedor;

        IF @@ROWCOUNT = 0
            RAISERROR('No se encontró el proveedor con ID %d.', 16, 1, @Id_Proveedor);

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 5. LECTURA PARA N
IF OBJECT_ID('sp_ListarProveedoresPorConsorcio') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ListarProveedoresPorConsorcio;
END
GO

CREATE PROCEDURE sp_ListarProveedoresPorConsorcio
    @Id_Consorcio INT
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        IF NOT EXISTS (SELECT 1 FROM Consorcio WHERE Id_Consorcio = @Id_Consorcio)
            RAISERROR('El consorcio con ID %d no existe.', 16, 1, @Id_Consorcio);
            
        SELECT Id_Proveedor, Nombre_Gasto, Descripcion, Cuenta
        FROM Proveedor
        WHERE Id_Consorcio = @Id_Consorcio
        ORDER BY Nombre_Gasto;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
------------------------
-- Para Tabla Persona --
------------------------

PRINT '--- Creando ABMC de [Persona] ---'
GO

-- 1. ALTA 
IF OBJECT_ID('sp_CrearPersona') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_CrearPersona;
END
GO

CREATE PROCEDURE sp_CrearPersona
    @Nombre VARCHAR(80),
    @Apellido VARCHAR(80),
    @DNI VARCHAR(15),
    @Email VARCHAR(100),
    @Telefono VARCHAR(20),
    @Cbu_Cvu VARCHAR(22),
    @inquilino bit
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        DECLARE @Id INT;

        -- Usar ISNULL para evitar errores si un parámetro llega como NULL
        SET @DNI = TRIM(ISNULL(@DNI, ''));
        SET @Nombre = TRIM(ISNULL(@Nombre, ''));
        SET @Apellido = TRIM(ISNULL(@Apellido, ''));
        SET @Email = TRIM(ISNULL(@Email, ''));
        SET @Telefono = TRIM(ISNULL(@Telefono, ''));
        SET @inquilino = ISNULL(@inquilino, 0);
		SET @Cbu_Cvu = TRIM(ISNULL(@Cbu_Cvu, ''));
        --Validamos que no exista el mismo DNI--
        SELECT @Id = Id_Persona
        FROM Persona
        WHERE DNI = @DNI;

        IF @Id IS NOT NULL
        BEGIN
            RAISERROR('Ya existe la persona con el DNI ingresado',16,1);
        END

        -- Limpiamos y Validamos el nombre y apellido --
        IF @Nombre ='' OR @Nombre LIKE '%[^a-zA-ZáéíóúÁÉÍÓÚñÑ ]%' OR LEN(@Nombre) > 80
            RAISERROR('El nombre no es válido. Solo se permiten letras, espacios, tildes y ñ.', 16, 1);

        IF @Apellido ='' OR @Apellido LIKE '%[^a-zA-ZáéíóúÁÉÍÓÚñÑ ]%' OR LEN(@Apellido) > 80
            RAISERROR('El apellido no es válido. Solo se permiten letras, espacios, tildes y ñ.', 16, 1);
        
        -- Limpiamos y Validamos el DNI --
        IF @DNI ='' OR @DNI LIKE '%[^0-9]%' OR LEN(@DNI) > 12 
            RAISERROR('El DNI no es válido. Debe ser numérico y tener 12 caracteres o menos.', 16, 1);
            
        -- Limpiamos y Validamos el EMAIL --
        IF @Email ='' OR @Email NOT LIKE '%_@_%._%' OR LEN(@Email) > 100 
            RAISERROR('El Email no es válido.', 16, 1);

        -- Limpiamos y Validamos el Telefono (perimitiendo el +) --
        IF @Telefono <> '' AND @Telefono LIKE '%[^0-9+() ]%'
            RAISERROR('El Teléfono no es válido. Solo puede contener números, +, (), y espacios.', 16, 1);

        -- Limpiamos y Validamos el CBU --
        IF @Cbu_Cvu = '' OR (LEN(@Cbu_Cvu) <> 22 OR @Cbu_Cvu LIKE '%[^0-9]%')
            RAISERROR('El CBU/CVU no es válido. Debe contener exactamente 22 dígitos numéricos.', 16, 1);

        INSERT INTO Persona(DNI, Nombre, Apellido, Email, Telefono, inquilino, Cbu_Cvu)
        VALUES (@DNI, @Nombre, @Apellido, @Email, @Telefono, @inquilino, @Cbu_Cvu);

        SET @Id = SCOPE_IDENTITY();
        SELECT @Id AS Id_Persona_Nueva;

    END TRY
    BEGIN CATCH
        THROW; 
    END CATCH
END
GO

-- 2. MODIFICACIÓN 
IF OBJECT_ID('sp_ModificarPersona') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ModificarPersona;
END
GO

CREATE PROCEDURE sp_ModificarPersona
    @Id_Persona INT,
    @DNI VARCHAR(15),
    @Nombre VARCHAR(80),
    @Apellido VARCHAR(80),
    @Email VARCHAR(100),
    @Telefono VARCHAR(20),
    @inquilino bit,
    @Cbu_Cvu VARCHAR(22)
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        -- Validar existencia
        IF NOT EXISTS (SELECT 1 FROM Persona WHERE Id_Persona = @Id_Persona)
            RAISERROR('La persona con ID %d no existe.', 16, 1, @Id_Persona);

        -- Limpieza
        SET @DNI = TRIM(ISNULL(@DNI, ''));
        SET @Nombre = TRIM(ISNULL(@Nombre, ''));
        SET @Apellido = TRIM(ISNULL(@Apellido, ''));
        SET @Email = TRIM(ISNULL(@Email, ''));
        SET @Telefono = TRIM(ISNULL(@Telefono, ''));
        SET @Cbu_Cvu = TRIM(ISNULL(@Cbu_Cvu, ''));
        SET @inquilino = ISNULL(@inquilino, 0);

        -- Validación: No permitir cambiar el DNI a uno que ya exista
        IF EXISTS (SELECT 1 FROM Persona WHERE DNI = @DNI AND Id_Persona <> @Id_Persona)
            RAISERROR ('Ya existe otra persona con el DNI %s.', 16, 1, @DNI);
            
        -- Validaciones de formato
        IF @Nombre ='' OR @Nombre LIKE '%[^a-zA-ZáéíóúÁÉÍÓÚñÑ ]%' OR LEN(@Nombre) > 80
            RAISERROR('El nombre no es válido.', 16, 1);
        IF @Apellido ='' OR @Apellido LIKE '%[^a-zA-ZáéíóúÁÉÍÓÚñÑ ]%' OR LEN(@Apellido) > 80
            RAISERROR('El apellido no es válido.', 16, 1);
        IF @DNI ='' OR @DNI LIKE '%[^0-9]%' OR LEN(@DNI) > 12 
            RAISERROR('El DNI no es válido.', 16, 1);
        IF @Email ='' OR @Email NOT LIKE '%_@_%._%' OR LEN(@Email) > 100 
            RAISERROR('El Email no es válido.', 16, 1);
        IF @Telefono <> '' AND @Telefono LIKE '%[^0-9+() ]%'
            RAISERROR('El Teléfono no es válido.', 16, 1);
        IF @Cbu_Cvu = '' OR (LEN(@Cbu_Cvu) <> 22 OR @Cbu_Cvu LIKE '%[^0-9]%')
            RAISERROR('El CBU/CVU no es válido.', 16, 1);

        UPDATE Persona
        SET
            DNI = @DNI,
            Nombre = @Nombre,
            Apellido = @Apellido,
            Email = @Email,
            Telefono = @Telefono,
            inquilino = @inquilino,
            Cbu_Cvu = @Cbu_Cvu
        WHERE
            Id_Persona = @Id_Persona;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 3. BAJA 
IF OBJECT_ID('sp_BorrarPersona') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_BorrarPersona;
END
GO

CREATE PROCEDURE sp_BorrarPersona
    @Id_Persona INT
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        -- Validar existencia
        IF NOT EXISTS (SELECT 1 FROM Persona WHERE Id_Persona = @Id_Persona)
            RAISERROR('La persona con ID %d no existe.', 16, 1, @Id_Persona);
        
        -- Validación: No puedo borrar una persona si está asignada a una UF
        IF EXISTS (SELECT 1 FROM Unidad_Persona WHERE Id_Persona = @Id_Persona AND Fecha_Fin IS NULL)
            RAISERROR ('No se puede borrar la persona porque está asignada como propietaria o inquilino activo en una Unidad Funcional.', 16, 1);

        -- Si pasa la validación, borra
        DELETE FROM Persona
        WHERE Id_Persona = @Id_Persona;
        
        PRINT 'Persona borrada exitosamente.';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 4. LECTURA PARA 1
IF OBJECT_ID('sp_GetPersonaPorID') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_GetPersonaPorID;
END
GO

CREATE PROCEDURE sp_GetPersonaPorID
    @Id_Persona INT
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        SELECT * FROM Persona 
        WHERE Id_Persona = @Id_Persona;

        IF @@ROWCOUNT = 0
            RAISERROR('No se encontró la persona con ID %d.', 16, 1, @Id_Persona);
            
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 5. LECTURA PARA N
IF OBJECT_ID('sp_ListarPersonas') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ListarPersonas;
END
GO

CREATE PROCEDURE sp_ListarPersonas
    @Busqueda VARCHAR(100) = NULL -- Parámetro opcional para buscar
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        SELECT Id_Persona, DNI, Nombre, Apellido, Telefono, Email, inquilino
        FROM Persona 
        WHERE @Busqueda IS NULL
            OR DNI LIKE '%' + @Busqueda + '%'
            OR Nombre LIKE '%' + @Busqueda + '%'
            OR Apellido LIKE '%' + @Busqueda + '%'
        ORDER BY Apellido, Nombre;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-------------------------------
-- Para Tabla Unidad_Funcional --
-------------------------------

PRINT '--- Creando ABMC de [Unidad_Funcional] ---'
GO

-- 1. ALTA 
IF OBJECT_ID('sp_CrearUnidadFuncional') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_CrearUnidadFuncional;
END
GO

CREATE PROCEDURE sp_CrearUnidadFuncional
    @Id_Consorcio INT,
    @NroUF INT,                 -- CAMBIO CRÍTICO: Se recibe por parámetro
    @Piso VARCHAR(5),
    @Departamento VARCHAR(2),
    @Coeficiente DECIMAL(5, 2),
    @M2_UF SMALLINT,
    @Baulera BIT,
    @Cochera BIT,
    @M2_Baulera TINYINT,
    @M2_Cochera TINYINT
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        -- Limpieza
        SET @Piso = TRIM(ISNULL(@Piso, ''));
        SET @Departamento = TRIM(ISNULL(@Departamento, ''));
        SET @Baulera = ISNULL(@Baulera, 0);
        SET @Cochera = ISNULL(@Cochera, 0);

        -- Validaciones
        IF NOT EXISTS (SELECT 1 FROM Consorcio WHERE Id_Consorcio = @Id_Consorcio)
            RAISERROR('El consorcio con ID %d no existe.', 16, 1, @Id_Consorcio);
        IF @NroUF <= 0
            RAISERROR('El NroUF debe ser un número positivo.', 16, 1);
        IF @Piso = '' OR @Departamento = ''
            RAISERROR('El Piso y el Departamento no pueden estar vacíos.', 16, 1);
        IF @Coeficiente <= 0
            RAISERROR('El Coeficiente debe ser mayor a 0.', 16, 1);
        IF @M2_UF <= 0
            RAISERROR('Los M2 deben ser mayores a 0.', 16, 1);

        -- Validación: No permitir duplicados de Clave Primaria Compuesta
        IF EXISTS (SELECT 1 FROM Unidad_Funcional WHERE Id_Consorcio = @Id_Consorcio AND NroUf = @NroUF)
            RAISERROR ('La unidad funcional Nro %d ya existe para el consorcio %d.', 16, 1, @NroUF, @Id_Consorcio);

        INSERT INTO Unidad_Funcional
            (Id_Consorcio, NroUF, Piso, Departamento, Coeficiente, M2_UF, Baulera, Cochera, M2_Baulera, M2_Cochera)
        VALUES
            (@Id_Consorcio, @NroUF, @Piso, @Departamento, @Coeficiente, @M2_UF, @Baulera, @Cochera, @M2_Baulera, @M2_Cochera);
        
        PRINT 'Unidad Funcional creada exitosamente.';
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 2. MODIFICACIÓN
IF OBJECT_ID('sp_ModificarUnidadFuncional') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ModificarUnidadFuncional;
END
GO

CREATE PROCEDURE sp_ModificarUnidadFuncional
    @Id_Consorcio INT,          -- CAMBIO CRÍTICO: Parte de la Clave
    @NroUF INT,                 -- CAMBIO CRÍTICO: Parte de la Clave
    @Piso VARCHAR(5),
    @Departamento VARCHAR(2),
    @Coeficiente DECIMAL(5, 2),
    @M2_UF SMALLINT,
    @Baulera BIT,
    @Cochera BIT,
    @M2_Baulera TINYINT,
    @M2_Cochera TINYINT
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        -- Validar existencia
        IF NOT EXISTS (SELECT 1 FROM Unidad_Funcional WHERE Id_Consorcio = @Id_Consorcio AND NroUf = @NroUF)
            RAISERROR ('La unidad funcional Nro %d del consorcio %d no existe.', 16, 1, @NroUF, @Id_Consorcio);

        -- Limpieza
        SET @Piso = TRIM(ISNULL(@Piso, ''));
        SET @Departamento = TRIM(ISNULL(@Departamento, ''));
        SET @Baulera = ISNULL(@Baulera, 0);
        SET @Cochera = ISNULL(@Cochera, 0);

        -- Validaciones
        IF @Piso = '' OR @Departamento = ''
            RAISERROR('El Piso y el Departamento no pueden estar vacíos.', 16, 1);
        IF @Coeficiente <= 0
            RAISERROR('El Coeficiente debe ser mayor a 0.', 16, 1);
        IF @M2_UF <= 0
            RAISERROR('Los M2 deben ser mayores a 0.', 16, 1);

        -- (NOTA: No se permite cambiar Id_Consorcio o NroUF porque son Clave Primaria)
        UPDATE Unidad_Funcional
        SET
            Piso = @Piso,
            Departamento = @Departamento,
            Coeficiente = @Coeficiente,
            M2_UF = @M2_UF,
            Baulera = @Baulera,
            Cochera = @Cochera,
            M2_Baulera = @M2_Baulera,
            M2_Cochera = @M2_Cochera
        WHERE
            Id_Consorcio = @Id_Consorcio AND NroUf = @NroUF;
            
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 3. BAJA 
IF OBJECT_ID('sp_BorrarUnidadFuncional') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_BorrarUnidadFuncional;
END
GO

CREATE PROCEDURE sp_BorrarUnidadFuncional
    @Id_Consorcio INT,         
    @NroUF INT                  
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        -- Validar existencia
        IF NOT EXISTS (SELECT 1 FROM Unidad_Funcional WHERE Id_Consorcio = @Id_Consorcio AND NroUf = @NroUF)
            RAISERROR ('La unidad funcional Nro %d del consorcio %d no existe.', 16, 1, @NroUF, @Id_Consorcio);
        
        -- Validación CRÍTICA: No borrar si tiene historial de expensas
        IF EXISTS (SELECT 1 FROM Detalle_Expensa_UF WHERE Id_Consorcio = @Id_Consorcio AND NroUf = @NroUF)
            RAISERROR ('No se puede borrar la UF porque tiene de historial expensas.', 16, 1);
        
        -- Validación: No borrar si tiene personas asignadas
        IF EXISTS (SELECT 1 FROM Unidad_Persona WHERE Id_Consorcio = @Id_Consorcio AND NroUF = @NroUF)
            RAISERROR ('No se puede borrar la UF porque tiene personas (propietarios/inquilinos) asignadas.', 16, 1);

        -- Si pasa las validaciones, borra
        DELETE FROM Unidad_Funcional
        WHERE Id_Consorcio = @Id_Consorcio AND NroUf = @NroUF;
        
        PRINT 'Unidad Funcional borrada exitosamente.';
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 4. LECTURA PARA 1
IF OBJECT_ID('sp_GetUnidadFuncionalPorID') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_GetUnidadFuncionalPorID;
END
GO

CREATE PROCEDURE sp_GetUnidadFuncionalPorID
    @Id_Consorcio INT,
    @NroUF VARCHAR(10) -- << CORREGIDO: VARCHAR
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        SELECT UF.*, C.Nombre AS Consorcio_Nombre
        FROM Unidad_Funcional UF
        INNER JOIN Consorcio C ON UF.Id_Consorcio = C.Id_Consorcio
        WHERE UF.Id_Consorcio = @Id_Consorcio AND UF.NroUf = @NroUF;

        IF @@ROWCOUNT = 0
            RAISERROR('No se encontró la UF Nro %s del consorcio %d.', 16, 1, @NroUF, @Id_Consorcio);

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 5. LECTURA PARA N
IF OBJECT_ID('sp_ListarUnidadesPorConsorcio') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ListarUnidadesPorConsorcio;
END
GO

CREATE PROCEDURE sp_ListarUnidadesPorConsorcio
    @Id_Consorcio INT
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        IF NOT EXISTS (SELECT 1 FROM Consorcio WHERE Id_Consorcio = @Id_Consorcio)
            RAISERROR('El consorcio con ID %d no existe.', 16, 1, @Id_Consorcio);
            
        SELECT UF.*, P.Nombre AS Propietario_Nombre, P.Apellido AS Propietario_Apellido
        FROM Unidad_Funcional AS UF
        -- Busca el propietario/inquilino activo
        LEFT JOIN Unidad_Persona AS UP ON UF.Id_Consorcio = UP.Id_Consorcio AND UF.NroUF = UP.NroUF AND UP.Fecha_Fin IS NULL
        LEFT JOIN Persona AS P ON UP.Id_Persona = P.Id_Persona
        WHERE UF.Id_Consorcio = @Id_Consorcio
        ORDER BY UF.Piso, UF.Departamento;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO