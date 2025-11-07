
```sql

  /* === Preparación del entorno por el DOCENTE === */
/* (a) Crear BD y esquemas */
/*IF DB_ID('UG_EvaluacionSeguridad') IS NOT NULL
BEGIN
    ALTER DATABASE UG_EvaluacionSeguridad SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE UG_EvaluacionSeguridad;
END;*/


GO
CREATE DATABASE UG_EvaluacionSeguridad;
GO
USE UG_EvaluacionSeguridad;
GO

CREATE SCHEMA core AUTHORIZATION dbo;
CREATE SCHEMA audit AUTHORIZATION dbo;
GO

/* (b) Tablas de negocio */
CREATE TABLE core.Clientes(
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    DPI NVARCHAR(20) NOT NULL UNIQUE,
    NombreCompleto NVARCHAR(120) NOT NULL,
    FechaAlta DATE NOT NULL DEFAULT (CONVERT(date, GETDATE())),
    EsActivo BIT NOT NULL DEFAULT 1
);

CREATE TABLE core.Cuentas(
    CuentaID INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT NOT NULL REFERENCES core.Clientes(ClienteID),
    NumeroCuenta NVARCHAR(24) NOT NULL UNIQUE,
    TipoCuenta NVARCHAR(20) NOT NULL CHECK (TipoCuenta IN ('Ahorro','Monetaria')),
    Saldo DECIMAL(18,2) NOT NULL DEFAULT 0
);

CREATE TABLE core.Movimientos(
    MovimientoID INT IDENTITY(1,1) PRIMARY KEY,
    CuentaID INT NOT NULL REFERENCES core.Cuentas(CuentaID),
    FechaMov DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    TipoMov NVARCHAR(10) NOT NULL CHECK (TipoMov IN ('ABONO','CARGO')),
    Monto DECIMAL(18,2) NOT NULL CHECK (Monto > 0),
    Descripcion NVARCHAR(200) NULL
);

/* (c) Vista de apoyo */
CREATE VIEW core.vw_Saldos AS
SELECT c.CuentaID, c.NumeroCuenta, c.TipoCuenta, c.Saldo,
       cl.ClienteID, cl.NombreCompleto
FROM core.Cuentas c
JOIN core.Clientes cl ON cl.ClienteID = c.ClienteID;
GO

/* (d) Procedimiento “única vía” para afectar saldo */
CREATE OR ALTER PROCEDURE core.sp_RegistrarMovimiento
    @CuentaID INT,
    @TipoMov NVARCHAR(10), -- 'ABONO' o 'CARGO'
    @Monto DECIMAL(18,2),
    @Descripcion NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF (@TipoMov NOT IN ('ABONO','CARGO')) THROW 50001, 'TipoMov inválido.', 1;
    IF (@Monto <= 0) THROW 50002, 'Monto debe ser > 0.', 1;

    BEGIN TRAN;
    INSERT INTO core.Movimientos(CuentaID, TipoMov, Monto, Descripcion)
    VALUES (@CuentaID, @TipoMov, @Monto, @Descripcion);

    IF (@TipoMov = 'ABONO')
        UPDATE core.Cuentas SET Saldo = Saldo + @Monto WHERE CuentaID = @CuentaID;
    ELSE
        UPDATE core.Cuentas SET Saldo = Saldo - @Monto WHERE CuentaID = @CuentaID;

    COMMIT;
END;
GO

/* (e) Bitácora de auditoría */
CREATE TABLE audit.Bitacora(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Usuario NVARCHAR(128) NOT NULL,
    Accion NVARCHAR(200) NOT NULL,
    Objeto NVARCHAR(128) NULL,
    Detalle NVARCHAR(4000) NULL
);
GO

/* (f) Datos mínimos */
INSERT INTO core.Clientes (DPI, NombreCompleto) VALUES
('1234567890101','Ana López'),
('2345678901212','Luis Pérez');

INSERT INTO core.Cuentas (ClienteID, NumeroCuenta, TipoCuenta, Saldo) VALUES
(1,'1001-001','Ahorro',1500.00),
(2,'1002-001','Monetaria', 500.00);
GO


--- solo para ver

SELECT * FROM core.Movimientos
SELECT * FROM core.Cuentas
SELECT * FROM core.Clientes
SELECT * FROM audit.Bitacora
select * FROM core.vw_Saldos

---------  1. ROLES

CREATE ROLE rol_consulta;
CREATE ROLE rol_cajero;
CREATE ROLE rol_auditor;
CREATE ROLE rol_adminnegocio;

--------- rol consulta
GRANT SELECT ON SCHEMA::core TO rol_consulta;
DENY SELECT ON SCHEMA::audit TO rol_consulta;

--------- rol cajero
GRANT SELECT ON OBJECT::core.Cuentas TO rol_cajero;
GRANT SELECT ON OBJECT::core.Clientes TO rol_cajero;
grant insert on object::core.Movimientos to rol_cajero;
grant execute on object::core.sp_RegistrarMovimiento to rol_cajero;
deny update on object::core.Cuentas(Saldo) to rol_cajero;

-------- rol auditor
grant select on schema::audit to rol_auditor;
deny select on schema::core to rol_auditor;


-------- rol adminnegocio
grant select on schema::core to rol_adminnegocio;
grant update on schema::core to rol_adminnegocio;
grant insert on schema::core to rol_adminnegocio;
deny select on schema::audit to rol_adminnegocio;

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

----- 3. restriccion directa en salgo
deny update on core.Cuentas(Saldo) to rol_cajero;
deny update on core.Cuentas(Saldo) to rol_consulta;

-------- 4. bloqueo de esquema audit para todos menos rol auditor
deny select on schema::audit to rol_consulta, rol_cajeto, rol_adminnegocio;

```
