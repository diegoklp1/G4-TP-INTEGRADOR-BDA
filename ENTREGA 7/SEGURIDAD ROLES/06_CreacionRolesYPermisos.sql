-- =========================================================
-- SCRIPT: 06_Crear_RolesYPermisos.sql
-- PROPÓSITO: Crea los roles de seguridad y asigna los
--             permisos correspondientes.

-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =========================================================

use master
GO

USE COM5600_G04;
GO




/* =========================================================
				  1. CREACIÓN DE ROLES
========================================================= */
PRINT '--- 1. Creando Roles ---'
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'AdminGeneral')
BEGIN
    CREATE ROLE AdminGeneral;
    PRINT 'Rol [AdminGeneral] creado.';
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'AdminBancario')
BEGIN
    CREATE ROLE AdminBancario;
    PRINT 'Rol [AdminBancario] creado.';
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'AdminOperativo')
BEGIN
    CREATE ROLE AdminOperativo;
    PRINT 'Rol [AdminOperativo] creado.';
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Sistemas')
BEGIN
    CREATE ROLE Sistemas;
    PRINT 'Rol [Sistemas] creado.';
END
GO

PRINT '--- 2. Asignamos permisos ---'
GO


/* =========================================================
			2. ASIGNACIÓN DE PERMISOS
========================================================= */

-- PERMISOS PARA AdminGeneral
-- =========================================================
-- ROL:Administrativo_General
-- Propósito: 
--			Actualizacion de datos de UF		-> SI
--			Importacion sw informacion bancaria -> NO
--			Generacion de Reportes				-> SI
-- =========================================================

-- Permiso para "Actualizacion de datos de UF"
GRANT EXECUTE ON dbo.sp_ModificarUnidadFuncional TO AdminGeneral;

-- Permiso para "Generacion de reportes" (Damos acceso a todos los SP de reporte)
GRANT EXECUTE ON dbo.sp_Importar_Consorcios TO AdminGeneral;
GRANT EXECUTE ON dbo.sp_Importar_Personas TO AdminGeneral;
GRANT EXECUTE ON dbo.sp_Importar_UF_Persona TO AdminGeneral;
GRANT EXECUTE ON dbo.sp_Importar_PagosConsorcios TO AdminGeneral;
GRANT EXECUTE ON dbo.sp_Importar_Proveedores TO AdminGeneral;
GRANT EXECUTE ON dbo.sp_Importar_UnidadesFuncionales TO AdminGeneral;

-- Permiso de lectura (SELECT) para que los reportes funcionen
GRANT SELECT ON SCHEMA::dbo TO AdminGeneral;
-- =========================================================


-- PERMISOS PARA AdminBancario
-- =========================================================
-- ROL:Administrativo_Bancario
-- Propósito: 
--			Actualizacion de datos de UF		-> NO
--			Importacion sw informacion bancaria -> SI
--			Generacion de Reportes				-> SI
-- =========================================================

-- Permiso para "Importacion de informacion bancaria"
GRANT EXECUTE ON dbo.sp_Importar_Consorcios TO AdminBancario;
GRANT EXECUTE ON dbo.sp_Importar_Personas TO AdminBancario;
GRANT EXECUTE ON dbo.sp_Importar_UF_Persona TO AdminBancario;
GRANT EXECUTE ON dbo.sp_Importar_PagosConsorcios TO AdminBancario;
GRANT EXECUTE ON dbo.sp_Importar_Proveedores TO AdminBancario;
GRANT EXECUTE ON dbo.sp_Importar_UnidadesFuncionales TO AdminBancario;

-- Permiso para "Generacion de reportes"
GRANT EXECUTE ON dbo.sp_ReporteRecaudacionSemanal TO AdminBancario;					-- Reporte 1
GRANT EXECUTE ON dbo.sp_ReporteRecaudacionMensualDepartamento TO AdminBancario;		-- Reporte 2
GRANT EXECUTE ON dbo.sp_ReporteRecaudacionPorTipo TO AdminBancario;					-- Reporte 3
GRANT EXECUTE ON dbo.sp_ReporteTopMesesIngresosGastos TO AdminBancario;				-- Reporte 4 
GRANT EXECUTE ON dbo.sp_ReporteTop3MorososPorConsorcioPisoAnio TO AdminBancario;	-- Reporte 5
GRANT EXECUTE ON dbo.sp_ReporteIntervaloPagosOrdinarios TO AdminBancario;			-- Reporte 6

-- Permiso de lectura (SELECT)
GRANT SELECT ON SCHEMA::dbo TO AdminBancario;
-- =========================================================


-- PERMISOS PARA AdminOperativo
-- =========================================================
-- 
-- ROL:Administrativo_Operativo
-- Propósito: 
	
--			Actualizacion de datos de UF		-> SI
--			Importacion sw informacion bancaria -> NO
--			Generacion de Reportes				-> SI
-- =========================================================

-- Permiso para "Actualizacion de datos de UF"
GRANT EXECUTE ON dbo.sp_ModificarUnidadFuncional TO AdminOperativo;

-- Permiso para "Generacion de reportes"

GRANT EXECUTE ON dbo.sp_ReporteRecaudacionSemanal TO AdminOperativo;				-- Reporte 1
GRANT EXECUTE ON dbo.sp_ReporteRecaudacionMensualDepartamento TO AdminOperativo;	-- Reporte 2
GRANT EXECUTE ON dbo.sp_ReporteRecaudacionPorTipo TO AdminOperativo;				-- Reporte 3
GRANT EXECUTE ON dbo.sp_ReporteTopMesesIngresosGastos TO AdminOperativo;			-- Reporte 4 
GRANT EXECUTE ON dbo.sp_ReporteTop3MorososPorConsorcioPisoAnio TO AdminOperativo;	-- Reporte 5
GRANT EXECUTE ON dbo.sp_ReporteIntervaloPagosOrdinarios TO AdminOperativo;			-- Reporte 6

-- Permiso de lectura (SELECT)
GRANT SELECT ON SCHEMA::dbo TO AdminOperativo;


-- PERMISOS PARA Sistemas
-- =========================================================
-- ROL:Sistemas
-- Propósito: 
--			Actualizacion de datos de UF		-> NO
--			Importacion sw informacion bancaria -> NO
--			Generacion de Reportes				-> SI
--
-- =========================================================

-- Permiso para "Generacion de reportes"
GRANT EXECUTE ON dbo.sp_ReporteRecaudacionSemanal TO Sistemas;						-- Reporte 1
GRANT EXECUTE ON dbo.sp_ReporteRecaudacionMensualDepartamento TO Sistemas;			-- Reporte 2
GRANT EXECUTE ON dbo.sp_ReporteRecaudacionPorTipo TO Sistemas;						-- Reporte 3
GRANT EXECUTE ON dbo.sp_ReporteTopMesesIngresosGastos TO Sistemas;					-- Reporte 4 
GRANT EXECUTE ON dbo.sp_ReporteTop3MorososPorConsorcioPisoAnio TO Sistemas;			-- Reporte 5
GRANT EXECUTE ON dbo.sp_ReporteIntervaloPagosOrdinarios TO Sistemas;				-- Reporte 6

-- Permiso de lectura (SELECT)
GRANT SELECT ON SCHEMA::dbo TO Sistemas;
-- =========================================================


