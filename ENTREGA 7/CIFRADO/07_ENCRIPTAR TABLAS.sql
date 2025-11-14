USE COM5600_G04;
GO

SELECT * FROM unidades.Persona;
GO

/* 1. Abrir la clave */
OPEN SYMMETRIC KEY Key_DatosSensibles
DECRYPTION BY CERTIFICATE Cert_Cifrado_Datos;

/* 2. Alterar la tabla */
ALTER TABLE unidades.Persona ADD DNI_Cifrado VARBINARY(256) NULL;
ALTER TABLE unidades.Persona ADD Cbu_Cvu_Cifrado VARBINARY(256) NULL;
ALTER TABLE unidades.Persona ADD nombre_Cifrado VARBINARY(256) NULL;
ALTER TABLE unidades.Persona ADD apellido_Cifrado VARBINARY(256) NULL;
ALTER TABLE unidades.Persona ADD email_Cifrado VARBINARY(256) NULL;
ALTER TABLE unidades.Persona ADD telefono_Cifrado VARBINARY(256) NULL;

ALTER TABLE pagos.Pago ADD Cuenta_Origen_Cifrado VARBINARY(256) NULL;
GO

/* 3. Cifrar datos existentes */
UPDATE unidades.Persona
SET 
    DNI_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'), DNI),
    Cbu_Cvu_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'), Cbu_Cvu),
    nombre_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'), Nombre),
    apellido_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'), Apellido),
    email_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'), email),
    telefono_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'), Telefono);
GO

UPDATE pagos.Pago
SET 
    Cuenta_Origen_Cifrado = ENCRYPTBYKEY(KEY_GUID('Key_DatosSensibles'), Cuenta_Origen);
GO

/* 4. Borrar columnas antiguas */
ALTER TABLE unidades.Persona DROP COLUMN DNI;
ALTER TABLE unidades.Persona DROP COLUMN Cbu_Cvu;
ALTER TABLE unidades.Persona DROP COLUMN Nombre;
ALTER TABLE unidades.Persona DROP COLUMN Apellido;
ALTER TABLE unidades.Persona DROP COLUMN email;
ALTER TABLE unidades.Persona DROP COLUMN Telefono;

ALTER TABLE pagos.Pago DROP COLUMN Cuenta_Origen;
GO

/* 5. Renombrar columnas nuevas */
EXEC sp_rename 'unidades.Persona.DNI_Cifrado', 'DNI', 'COLUMN';
EXEC sp_rename 'unidades.Persona.Cbu_Cvu_Cifrado', 'Cbu_Cvu', 'COLUMN';
EXEC sp_rename 'unidades.Persona.nombre_Cifrado', 'Nombre', 'COLUMN';
EXEC sp_rename 'unidades.Persona.apellido_Cifrado', 'Apellido', 'COLUMN';
EXEC sp_rename 'unidades.Persona.email_Cifrado', 'email', 'COLUMN';
EXEC sp_rename 'unidades.Persona.telefono_Cifrado', 'Telefono', 'COLUMN';

EXEC sp_rename 'pagos.Pago.Cuenta_Origen_Cifrado', 'Cuenta_Origen', 'COLUMN';
GO

/* 6. Cerrar la clave */
CLOSE SYMMETRIC KEY Key_DatosSensibles;
GO