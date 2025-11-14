SELECT * FROM Persona
/* 1. Abrir la clave */
OPEN SYMMETRIC KEY Key_DatosSensibles
DECRYPTION BY CERTIFICATE Cert_Cifrado_Datos;

/* 2. Alterar la tabla (ejemplo con DNI y Cbu_Cvu) */
ALTER TABLE Persona ADD DNI_Cifrado VARBINARY(256) NULL;
ALTER TABLE Persona ADD Cbu_Cvu_Cifrado VARBINARY(256) NULL;
ALTER TABLE Persona ADD nombre_Cifrado VARBINARY(256) NULL;
ALTER TABLE Persona ADD apellido_Cifrado VARBINARY(256) NULL;
ALTER TABLE Persona ADD email_Cifrado VARBINARY(256) NULL;
ALTER TABLE Persona ADD telefono_Cifrado VARBINARY(256) NULL;

ALTER TABLE Pago ADD Cuenta_Origen_Cifrado VARBINARY(256) NULL;
GO

/* 3. Cifrar datos existentes */
UPDATE Persona
SET 
    DNI_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'), DNI),
    Cbu_Cvu_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'), Cbu_Cvu),
	nombre_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'), Nombre),
    apellido_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'), Apellido),
	email_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'), email),
	telefono_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'),Telefono );
GO
UPDATE Pago
SET 
	Cuenta_Origen_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'), Cuenta_Origen);

/* 4. Borrar columnas antiguas (¡CUIDADO! Hacer backup primero) */
ALTER TABLE Persona DROP COLUMN DNI;
ALTER TABLE Persona DROP COLUMN Cbu_Cvu;
ALTER TABLE Persona DROP COLUMN Nombre;
ALTER TABLE Persona DROP COLUMN Apellido;
ALTER TABLE Persona DROP COLUMN email;
ALTER TABLE Persona DROP COLUMN Telefono;

ALTER TABLE Pago DROP COLUMN Cuenta_Origen;

GO

/* 5. Renombrar columnas nuevas */
EXEC sp_rename 'Persona.DNI_Cifrado', 'DNI', 'COLUMN';
EXEC sp_rename 'Persona.Cbu_Cvu_Cifrado', 'Cbu_Cvu', 'COLUMN';
EXEC sp_rename 'Persona.nombre_Cifrado', 'Nombre', 'COLUMN';
EXEC sp_rename 'Persona.apellido_Cifrado', 'Apellido', 'COLUMN';
EXEC sp_rename 'Persona.email_Cifrado', 'email', 'COLUMN';
EXEC sp_rename 'Persona.telefono_Cifrado', 'Telefono', 'COLUMN';

EXEC sp_rename 'Pago.Cuenta_Origen_Cifrado', 'Cuenta_Origen', 'COLUMN';
GO

