# Tareas
aqui estare guardando lo que pueda de tareas con codigo



```sql

 ---------  1. ROLES
CREATE ROLE rol_consulta;
CREATE ROLE rol_cajero;
CREATE ROLE rol_auditor;
CREATE ROLE rol_adminnegocio;

--------- rol consulta
GRANT SELECT ON SCHEMA::core TO rol_consulta;
DENY SELECT ON SCHEMA::audit TO rol_consulta;

--------- rol cajero
GRANT SELECT ON core.Cuentas TO rol_cajero;
GRANT SELECT ON core.Clientes TO rol_cajero;
GRANT INSERT ON core.Movimientos TO rol_cajero;
GRANT EXECUTE ON core.sp_RegistrarMovimiento TO rol_cajero;
DENY UPDATE ON core.Cuentas(Saldo) TO rol_cajero;

-------- rol auditor
GRANT SELECT ON SCHEMA::audit TO rol_auditor;
DENY SELECT ON SCHEMA::core TO rol_auditor;

-------- rol adminnegocio
GRANT SELECT, INSERT, UPDATE ON SCHEMA::core TO rol_adminnegocio;
DENY SELECT ON SCHEMA::audit TO rol_adminnegocio;

-- RESTRICCIONES DE SEGURIDAD PARA rol_adminnegocio
DENY ALTER ANY USER TO rol_adminnegocio;
DENY CONTROL ON DATABASE::UG_EvaluacionSeguridad TO rol_adminnegocio;

-------- 2. creacion de usuarios
create user u_consulta1 without login;
create user u_cajera1 without login;
create user u_auditor1 without login;
create user u_admin1 without login;

------- asignacion roles a usuarios
ALTER ROLE rol_consulta ADD MEMBER u_consulta1;
ALTER ROLE rol_cajero ADD MEMBER u_cajera1;
ALTER ROLE rol_auditor ADD MEMBER u_auditor1;
ALTER ROLE rol_adminnegocio ADD MEMBER u_admin1;

----- 3. restriccion directa en saldo
deny update on core.Cuentas(Saldo) to rol_cajero;
deny update on core.Cuentas(Saldo) to rol_consulta;

-------- 4. bloqueo de esquema audit para todos menos rol auditor
deny select on schema::audit to rol_consulta, rol_cajero, rol_adminnegocio;

```

