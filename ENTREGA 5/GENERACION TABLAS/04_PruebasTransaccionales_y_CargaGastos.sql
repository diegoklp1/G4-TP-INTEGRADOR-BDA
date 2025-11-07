-- =========================================================
-- SCRIPT: 04_PruebasTransaccionales_y_CargaGastos.sql
-- PROPÓSITO: 1. Cargar las tablas de Catálogo (Tipos).
--            2. Probar SPs transaccionales (Asignar, Registrar Gasto).
--            3. Cargar 3 meses de gastos de prueba.

-- Fecha de entrega:    07/11/2025
-- Comision:            5600
-- Grupo:               04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387
-- =========================================================


USE COM5600_G04;
GO

PRINT '--- INICIO SCRIPT 04_PruebasTransaccionales_y_CargaGastos.sql ---'
GO

-- Declaramos variables para IDs
DECLARE @IdConsorcioA INT, @IdConsorcioB INT;
DECLARE @IdPersonaFranco INT;
DECLARE @IdUF_A1 VARCHAR(10); -- << CORREGIDO: Tipo de dato VARCHAR(10)
DECLARE @IdRelacionPropietario INT, @IdRelacionInquilino INT;
DECLARE @IdGastoAdmin INT, @IdGastoSeguro INT, @IdGastoServicio INT, @IdGastoMantenimiento INT;
DECLARE @IdTipoServicioLuz INT;
DECLARE @IdTipoPagoExtra INT;


BEGIN TRY
    PRINT '--- 1. Cargando Tablas de Catálogo (Setup) ---'
    PRINT '... (Validando que no existan duplicados)'

    -- (INSERTS de catálogos - Esto está BIEN)
    IF NOT EXISTS (SELECT 1 FROM Tipo_Gasto_Ordinario WHERE Nombre = 'Administracion')
        INSERT INTO Tipo_Gasto_Ordinario(Nombre) VALUES ('Administracion');
    -- ( ... todos los IF NOT EXISTS para los catálogos ... )
    -- (Esta parte la tenías bien)
    IF NOT EXISTS (SELECT 1 FROM Tipo_Servicio WHERE Nombre = 'Luz')
        INSERT INTO Tipo_Servicio (Nombre) VALUES ('Luz');
    IF NOT EXISTS (SELECT 1 FROM TipoRelacionPersonaUnidad WHERE Nombre = 'Propietario')
        INSERT INTO TipoRelacionPersonaUnidad (Nombre) VALUES ('Propietario');
    IF NOT EXISTS (SELECT 1 FROM Forma_De_Pago WHERE Nombre = 'Transferencia/CSV')
        INSERT INTO Forma_De_Pago (Nombre) VALUES ('Transferencia/CSV');
    IF NOT EXISTS (SELECT 1 FROM Tipo_ingreso WHERE Nombre = 'Pago Expensa Ordinaria')
        INSERT INTO Tipo_ingreso (Nombre) VALUES ('Pago Expensa Ordinaria');
    IF NOT EXISTS (SELECT 1 FROM Tipo_Pago_Extraordinario WHERE Nombre = 'Arreglo Ascensor')
        INSERT INTO Tipo_Pago_Extraordinario (Nombre) VALUES ('Arreglo Ascensor');
    IF NOT EXISTS (SELECT 1 FROM Mora WHERE Dias_Desde_Vencimiento = 10)
        INSERT INTO Mora (Porcentajes_Interes, Dias_Desde_Vencimiento) VALUES (2.0, 10);
        
    PRINT '... OK. Catálogos cargados.';
    
    -- Obtenemos los IDs que vamos a necesitar para las pruebas
    SET @IdConsorcioA = 100; -- (Asumimos ID 100 creado en script 02_TestingABMs)
    SET @IdConsorcioB = 101; -- (Asumimos ID 101 creado en script 02_TestingABMs)
    
    SELECT @IdPersonaFranco = Id_Persona FROM Persona WHERE DNI = '30111222';
    
    SET @IdUF_A1 = '1'; -- << CORREGIDO: Es un VARCHAR
    
    SELECT @IdRelacionPropietario = ID_Tipo_Relacion_P_U FROM TipoRelacionPersonaUnidad WHERE Nombre = 'Propietario';
    SELECT @IdGastoAdmin = Id_Tipo_Gasto FROM Tipo_Gasto_Ordinario WHERE Nombre = 'Administracion';
    SELECT @IdGastoSeguro = Id_Tipo_Gasto FROM Tipo_Gasto_Ordinario WHERE Nombre = 'Seguro';
    SELECT @IdGastoServicio = Id_Tipo_Gasto FROM Tipo_Gasto_Ordinario WHERE Nombre = 'Servicio Publico';
    SELECT @IdTipoServicioLuz = Id_Tipo_Servicio FROM Tipo_Servicio WHERE Nombre = 'Luz';
    SELECT @IdTipoPagoExtra = Id_tipo_pago FROM Tipo_Pago_Extraordinario WHERE Nombre = 'Arreglo Ascensor';

    -----------------------------------------------------
    PRINT '--- 2. Probando SPs Transaccionales [sp_AsignarPersonaUnidad] ---'
    
    PRINT 'Prueba: Asignando a Franco como Propietario de la UF 1'
   
    EXEC sp_AsignarPersonaUnidad
        @Id_Consorcio = @IdConsorcioA,      
        @NroUF = @IdUF_A1,                
        @Id_Persona = @IdPersonaFranco,  
        @Id_TipoRelacion = @IdRelacionPropietario

    PRINT '... OK. Verificando asignación:'

    SELECT P.Nombre, P.Apellido, TR.Nombre AS Relacion, UP.Fecha_Inicio, UP.Fecha_Fin
    FROM Unidad_Persona AS UP
    JOIN Persona AS P ON UP.Id_Persona = P.Id_Persona
    JOIN TipoRelacionPersonaUnidad AS TR ON UP.Id_TipoRelacion = TR.ID_Tipo_Relacion_P_U
    WHERE UP.Id_Consorcio = @IdConsorcioA AND UP.NroUF = @IdUF_A1;


    -----------------------------------------------------
    PRINT '--- 3. CARGA DE GASTOS DE PRUEBA (Cumpliendo TP) ---'
    
    -- (El resto de esta sección estaba bien)
    
    PRINT '--- 3.1. GASTOS Mes 1 (ej: Agosto 2025) ---'
    EXEC sp_RegistrarGastoOrdinario @Id_Consorcio = @IdConsorcioA, @Id_Tipo_Gasto = @IdGastoAdmin, @Fecha = '2025-08-05', @Importe_Total = 50000, @Descripcion = 'Honorarios Admin Agosto', @Nro_Factura_Admin = 1001;
    EXEC sp_RegistrarGastoOrdinario @Id_Consorcio = @IdConsorcioA, @Id_Tipo_Gasto = @IdGastoSeguro, @Fecha = '2025-08-10', @Importe_Total = 30000, @Descripcion = 'Seguro Incendio', @Nro_Factura_Seguro = 2002, @NombreSeguro = 'La Segunda';
    EXEC sp_RegistrarGastoOrdinario @Id_Consorcio = @IdConsorcioA, @Id_Tipo_Gasto = @IdGastoServicio, @Fecha = '2025-08-15', @Importe_Total = 25000, @Descripcion = 'Luz espacios comunes', @Id_Tipo_Servicio = @IdTipoServicioLuz, @Nombre_Empresa_Servicio = 'Edenor', @Nro_Factura_Servicio = 3003; 
    PRINT '... OK. Gastos Mes 1 cargados.';

    PRINT '--- 3.2. GASTOS Mes 2 (ej: Septiembre 2025) ---'
    EXEC sp_RegistrarGastoOrdinario @Id_Consorcio = @IdConsorcioA, @Id_Tipo_Gasto = @IdGastoAdmin, @Fecha = '2025-09-05', @Importe_Total = 50000, @Descripcion = 'Honorarios Admin Septiembre', @Nro_Factura_Admin = 1002;
    EXEC sp_RegistrarGastoOrdinario @Id_Consorcio = @IdConsorcioA, @Id_Tipo_Gasto = @IdGastoSeguro, @Fecha = '2025-09-10', @Importe_Total = 30000, @Descripcion = 'Seguro Incendio', @Nro_Factura_Seguro = 2003, @NombreSeguro = 'La Segunda';
    EXEC sp_RegistrarGastoOrdinario @Id_Consorcio = @IdConsorcioA, @Id_Tipo_Gasto = @IdGastoServicio, @Fecha = '2025-09-15', @Importe_Total = 26000, @Descripcion = 'Luz espacios comunes', @Id_Tipo_Servicio = @IdTipoServicioLuz, @Nombre_Empresa_Servicio = 'Edenor', @Nro_Factura_Servicio = 3004;
    PRINT '... OK. Gastos Mes 2 cargados.';

    PRINT '--- 3.3. GASTOS Mes 3 (ej: Octubre 2025) + Gasto Extraordinario ---'
    EXEC sp_RegistrarGastoOrdinario @Id_Consorcio = @IdConsorcioA, @Id_Tipo_Gasto = @IdGastoAdmin, @Fecha = '2025-10-05', @Importe_Total = 50000, @Descripcion = 'Honorarios Admin Octubre', @Nro_Factura_Admin = 1003;
    EXEC sp_RegistrarGastoOrdinario @Id_Consorcio = @IdConsorcioA, @Id_Tipo_Gasto = @IdGastoSeguro, @Fecha = '2025-10-10', @Importe_Total = 30000, @Descripcion = 'Seguro Incendio', @Nro_Factura_Seguro = 2004, @NombreSeguro = 'La Segunda';
    EXEC sp_RegistrarGastoOrdinario @Id_Consorcio = @IdConsorcioA, @Id_Tipo_Gasto = @IdGastoServicio, @Fecha = '2025-10-15', @Importe_Total = 27000, @Descripcion = 'Luz espacios comunes', @Id_Tipo_Servicio = @IdTipoServicioLuz, @Nombre_Empresa_Servicio = 'Edenor', @Nro_Factura_Servicio = 3005;
    
    PRINT 'Prueba: sp_RegistrarGastoExtraordinario (Cumpliendo TP)'
    EXEC sp_RegistrarGastoExtraordinario
        @Id_Consorcio = @IdConsorcioA,
        @Id_tipo_pago = @IdTipoPagoExtra,
        @detalle_trabajo = 'Reparacion motor ascensor',
        @Nro_Cuotas_Actual = 1,
        @Total_Cuotas = 3,
        @Importe = 90000, -- Importe total de la cuota 1
        @Fecha = '2025-10-20';
    
    PRINT '... OK. Gastos Mes 3 (con extraordinario) cargados.';

    -----------------------------------------------------
    PRINT '--- 4. Verificación de Carga de Gastos ---'
    
    PRINT 'SELECT * FROM Gasto_Ordinario (Deberían haber 9 gastos)'
    SELECT * FROM Gasto_Ordinario;

    PRINT 'SELECT * FROM Gasto_Seguro (Deberían haber 3 gastos. Prueba de Herencia)'
    SELECT * FROM Gasto_Seguro;

    PRINT 'SELECT * FROM Gasto_Extraordinario (Debería haber 1 gasto)'
    SELECT * FROM Gasto_Extraordinario;


END TRY
BEGIN CATCH
    -- Mostramos el error que interrumpió la prueba
    PRINT '--- PRUEBA FALLIDA ---'
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '--- FIN SCRIPT 04_PruebasTransaccionales_y_CargaGastos.sql ---'
GO