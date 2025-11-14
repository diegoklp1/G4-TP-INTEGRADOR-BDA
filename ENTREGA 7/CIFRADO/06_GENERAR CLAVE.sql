USE COM5600_G04;
GO

-- 1. Crear la Clave Maestra de la Base de Datos
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    PRINT 'Creando Master Key...';
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'JoseRaspanding123';
END
GO

-- 2. Crear un Certificado
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'Cert_Cifrado_Datos')
BEGIN
    PRINT 'Creando Certificado...';
    CREATE CERTIFICATE Cert_Cifrado_Datos
    WITH SUBJECT = 'Certificado para cifrar datos sensibles de consorcios';
END
GO

-- 3. Crear la Clave Simetrica
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'Key_DatosSensibles')
BEGIN
    PRINT 'Creando Clave Simetrica...';
    CREATE SYMMETRIC KEY Key_DatosSensibles
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE Cert_Cifrado_Datos;
END
GO

PRINT 'Jerarquia de cifrado creada exitosamente.';