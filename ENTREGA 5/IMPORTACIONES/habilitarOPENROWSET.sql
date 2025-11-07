
-- ES NECESARIO TENER INSTALADO "MICROSOSFT ACCES DATABASE ENGINE 2016 REDISTRIBUITABLE" PARA OLEDB.16
EXEC master.dbo.sp_enum_oledb_providers;


use bd_tp_testeo
--Habilitar opciones avanzadas
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
-- Habilitar la importación de queries (Ad Hoc)
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO
EXEC sp_configure 'Ad Hoc Distributed Queries';


EXEC master.dbo.sp_MSset_oledb_prop 
    N'Microsoft.ACE.OLEDB.16.0', 
    N'AllowInProcess', 1;
    
EXEC master.dbo.sp_MSset_oledb_prop 
    N'Microsoft.ACE.OLEDB.16.0', 
    N'DynamicParameters', 1;