USE bd_tp_testeo

IF NOT EXISTS (SELECT 1 FROM Forma_De_Pago WHERE Id_Forma_De_Pago = 1)
    INSERT INTO Forma_De_Pago (Nombre) VALUES ('Transferencia Bancaria');

IF NOT EXISTS (SELECT 1 FROM Forma_De_Pago WHERE Id_Forma_De_Pago = 2)
    INSERT INTO Forma_De_Pago (Nombre) VALUES ('Efectivo');

IF NOT EXISTS (SELECT 1 FROM Forma_De_Pago WHERE Id_Forma_De_Pago = 3)
    INSERT INTO Forma_De_Pago (Nombre) VALUES ('Débito Automático');


/*
IF OBJECT_ID('Liquidacion_Mensual') IS NULL
BEGIN
	CREATE TABLE Liquidacion_Mensual
	(
		Id_Liquidacion_Mensual int IDENTITY(1,1) PRIMARY KEY,
		Id_Consorcio int,
		Periodo datetime,
		Fecha_Emision datetime,
		Fecha_Vencimiento1 datetime,
		Fecha_Vencimiento2 datetime,
		Total_Gasto_Ordinarios decimal(10,2),
		Total_Gasto_Extraordinarios decimal(10,2),
		CONSTRAINT FK_Liquidacion_Mensual_Consorcio FOREIGN KEY (Id_Consorcio) REFERENCES Consorcio(Id),
	);
END
IF OBJECT_ID('Detalle_Expensa_UF') IS NULL
BEGIN
	CREATE TABLE Detalle_Expensa_UF
	(
		Id_Detalle_Expensa int IDENTITY(1,1) PRIMARY KEY,
		Id_Expensa int,
		NroUf int,
		Saldo_Anterior decimal(9,2),
		Pagos_Recibidos_Mes decimal(9,2),
		Deuda decimal(9,2),
		Interes_Por_Mora decimal(9,2),
		Importe_Ordinario_Prorrateado decimal(9,2),
		Importe_Extraordinario_Prorrateado decimal(9,2),
		Total_A_Pagar decimal(9,2),
		CONSTRAINT FK_Detalle_Expensa_UF_Liquidacion_Mensual FOREIGN KEY (Id_Expensa) REFERENCES Liquidacion_Mensual(Id_Liquidacion_Mensual),
	);
END
IF OBJECT_ID('Forma_De_Pago') IS NULL
BEGIN

	CREATE TABLE Forma_De_Pago 
	(
		Id_Forma_De_Pago int IDENTITY(1,1) PRIMARY KEY,
		Nombre varchar(50),
	);
END


IF OBJECT_ID('Pago') IS NULL
BEGIN
	CREATE TABLE Pago 
	(
		Id_Pago int IDENTITY(1,1) PRIMARY KEY,
		Id_Forma_De_Pago int,
		Fecha DATE,
		Cuenta_Origen varchar(22) NOT NULL,
		Importe decimal(9,2),
		Es_Pago_Asociado bit,
		CONSTRAINT FK_Pago__Forma_De_Pago FOREIGN KEY (Id_Forma_De_Pago) REFERENCES Forma_De_Pago(Id_Forma_De_Pago),
	);
END


IF OBJECT_ID('Tipo_ingreso') IS NULL
BEGIN
	CREATE TABLE Tipo_ingreso 
	(
		Id_Tipo_Ingreso int IDENTITY(1,1) PRIMARY KEY,
		Nombre varchar(50),
	);
END

IF OBJECT_ID('Detalle_Pago') IS NULL
BEGIN
	CREATE TABLE Detalle_Pago 
	(
		Id_Detalle_Pago int IDENTITY(1,1) PRIMARY KEY,
		Id_Pago int,
		Id_Detalle_Expensa int,
		Id_Tipo_Ingreso int,
		Importe_Usado decimal(10,2),	
		CONSTRAINT FK_Detalle_Pago__Pago FOREIGN KEY (Id_Pago) REFERENCES Pago(Id_Pago),
		CONSTRAINT FK_Detalle_Pago__Detalle_Expensa_UF FOREIGN KEY (Id_Detalle_Expensa) REFERENCES Detalle_Expensa_UF(Id_Detalle_Expensa),
		CONSTRAINT FK_Detalle_Pago__Tipo_ingreso FOREIGN KEY (Id_Tipo_Ingreso) REFERENCES Tipo_ingreso(Id_Tipo_Ingreso),
	);
END
*/

USE bd_tp_testeo
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
        INSERT INTO Pago (Id_Forma_De_Pago, Fecha, Cuenta_Origen, Importe, Es_Pago_Asociado)
        SELECT 
            1, TRY_CONVERT(DATE, Fecha_CSV, 103), Cuenta_Origen_CSV, CAST(Importe_CSV AS DECIMAL(9,2)), Es_Asociado
        FROM #PagosTemp;

        PRINT 'Importación completada correctamente.';
    END TRY
    BEGIN CATCH
        PRINT ' Error en la importación de pagos consorcios.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH;

    DROP TABLE #PagosTemp;
END
GO


EXEC sp_Importar_PagosConsorcios 
    @RutaArchivoCSV = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\pagos_consorcios.csv';


SELECT * FROM Pago
select COUNT(es_pago_asociado) from pago GROUP BY (es_pago_asociado)
TRUNCATE TABLE PAGO