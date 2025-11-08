```sql
-- =============================================
-- CREACIÓN DE LA BASE DE DATOS DE PRÁCTICA
-- =============================================

CREATE DATABASE PracticaTriggers;
GO

USE PracticaTriggers;
GO

-- =============================================
-- TABLAS PRINCIPALES
-- =============================================

-- Tabla de Productos
CREATE TABLE Productos (
    ProductoID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Precio DECIMAL(10,2) NOT NULL,
    Stock INT NOT NULL DEFAULT 0,
    FechaCreacion DATETIME DEFAULT GETDATE(),
    Activo BIT DEFAULT 1
);

-- Tabla de Clientes
CREATE TABLE Clientes (
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Email VARCHAR(100),
    Telefono VARCHAR(20),
    FechaRegistro DATETIME DEFAULT GETDATE(),
    Activo BIT DEFAULT 1
);

-- Tabla de Ventas
CREATE TABLE Ventas (
    VentaID INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT NOT NULL,
    ProductoID INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    Total DECIMAL(10,2) NOT NULL,
    FechaVenta DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID),
    FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID)
);

-- =============================================
-- TABLAS DE AUDITORÍA (Para los triggers)
-- =============================================

-- Auditoría general
CREATE TABLE Auditoria (
    AuditoriaID INT IDENTITY(1,1) PRIMARY KEY,
    TablaAfectada VARCHAR(50),
    Accion VARCHAR(20),
    RegistroID INT,
    ValorAnterior VARCHAR(500),
    ValorNuevo VARCHAR(500),
    Usuario VARCHAR(100) DEFAULT SYSTEM_USER,
    FechaHora DATETIME DEFAULT GETDATE()
);

-- Histórico de precios
CREATE TABLE HistoricoPrecios (
    HistoricoID INT IDENTITY(1,1) PRIMARY KEY,
    ProductoID INT,
    PrecioAnterior DECIMAL(10,2),
    PrecioNuevo DECIMAL(10,2),
    FechaCambio DATETIME DEFAULT GETDATE(),
    Usuario VARCHAR(100) DEFAULT SYSTEM_USER
);

-- =============================================
-- INSERTAR DATOS DE PRUEBA
-- =============================================

-- Insertar productos
INSERT INTO Productos (Nombre, Precio, Stock) VALUES
('Laptop HP', 4500.00, 10),
('Mouse Inalámbrico', 150.00, 25),
('Teclado Mecánico', 800.00, 15),
('Monitor 24"', 1200.00, 8),
('Tablet Samsung', 1800.00, 12);

-- Insertar clientes
INSERT INTO Clientes (Nombre, Email, Telefono) VALUES
('Ana García', 'ana@email.com', '1234-5678'),
('Luis Martínez', 'luis@email.com', '2345-6789'),
('María López', 'maria@email.com', '3456-7890'),
('Carlos Rodríguez', 'carlos@email.com', '4567-8901');

PRINT 'Base de datos y tablas creadas exitosamente!';
PRINT 'Puedes empezar a practicar con los triggers.';
GO
```

```sql
-- =============================================
-- 1. TRIGGERS BÁSICOS (AFTER)
-- =============================================

-- 🔹 AFTER INSERT - Se ejecuta DESPUÉS de insertar
CREATE TRIGGER trg_DespuesInsertarProducto
ON Productos
AFTER INSERT
AS
BEGIN
    PRINT '=== TRIGGER AFTER INSERT ACTIVADO ===';
    PRINT 'Se insertó un nuevo producto:';
    
    -- Mostrar lo que se insertó
    SELECT 'NUEVO PRODUCTO' as Mensaje, * FROM inserted;
    
    -- Guardar en auditoría
    INSERT INTO Auditoria (TablaAfectada, Accion, RegistroID, ValorNuevo)
    SELECT 'Productos', 'INSERT', ProductoID, 
           'Nombre: ' + Nombre + ', Precio: ' + CAST(Precio AS VARCHAR)
    FROM inserted;
    
    PRINT 'Registro guardado en auditoría.';
END;
GO

-- 🔹 AFTER UPDATE - Se ejecuta DESPUÉS de actualizar
CREATE TRIGGER trg_DespuesActualizarProducto
ON Productos
AFTER UPDATE
AS
BEGIN
    PRINT '=== TRIGGER AFTER UPDATE ACTIVADO ===';
    
    -- Verificar si cambió el precio
    IF UPDATE(Precio)
    BEGIN
        PRINT 'El precio de un producto cambió:';
        
        -- Mostrar cambios
        SELECT 'PRECIO ANTIGUO' as Tipo, d.ProductoID, d.Nombre, d.Precio
        FROM deleted d;
        
        SELECT 'PRECIO NUEVO' as Tipo, i.ProductoID, i.Nombre, i.Precio  
        FROM inserted i;
        
        -- Guardar en histórico de precios
        INSERT INTO HistoricoPrecios (ProductoID, PrecioAnterior, PrecioNuevo)
        SELECT d.ProductoID, d.Precio, i.Precio
        FROM deleted d
        INNER JOIN inserted i ON d.ProductoID = i.ProductoID
        WHERE d.Precio <> i.Precio;
    END
    
    -- Guardar en auditoría general
    INSERT INTO Auditoria (TablaAfectada, Accion, RegistroID, ValorAnterior, ValorNuevo)
    SELECT 'Productos', 'UPDATE', i.ProductoID,
           'Nombre: ' + d.Nombre + ', Precio: ' + CAST(d.Precio AS VARCHAR),
           'Nombre: ' + i.Nombre + ', Precio: ' + CAST(i.Precio AS VARCHAR)
    FROM inserted i
    INNER JOIN deleted d ON i.ProductoID = d.ProductoID;
    
    PRINT 'Cambios guardados en auditoría.';
END;
GO

-- 🔹 AFTER DELETE - Se ejecuta DESPUÉS de eliminar
CREATE TRIGGER trg_DespuesEliminarProducto
ON Productos
AFTER DELETE
AS
BEGIN
    PRINT '=== TRIGGER AFTER DELETE ACTIVADO ===';
    PRINT 'Se eliminó un producto:';
    
    -- Mostrar lo eliminado
    SELECT 'PRODUCTO ELIMINADO' as Mensaje, * FROM deleted;
    
    -- Guardar en auditoría
    INSERT INTO Auditoria (TablaAfectada, Accion, RegistroID, ValorAnterior)
    SELECT 'Productos', 'DELETE', ProductoID,
           'Nombre: ' + Nombre + ', Precio: ' + CAST(Precio AS VARCHAR)
    FROM deleted;
    
    PRINT 'Registro guardado en auditoría.';
END;
GO
```

```sql
-- =============================================
-- 2. TRIGGERS INSTEAD OF (EN LUGAR DE)
-- =============================================

-- 🔹 INSTEAD OF DELETE - En lugar de eliminar
CREATE TRIGGER trg_EnLugarEliminar
ON Productos
INSTEAD OF DELETE
AS
BEGIN
    PRINT '=== TRIGGER INSTEAD OF DELETE ACTIVADO ===';
    PRINT 'En lugar de eliminar, marcamos como INACTIVO';
    
    -- Mostrar lo que se intentó eliminar
    SELECT 'SE INTENTÓ ELIMINAR:' as Mensaje, * FROM deleted;
    
    -- En lugar de eliminar, marcamos como inactivo
    UPDATE Productos 
    SET Activo = 0 
    WHERE ProductoID IN (SELECT ProductoID FROM deleted);
    
    PRINT 'Producto marcado como INACTIVO (no eliminado físicamente)';
    
    -- Guardar en auditoría
    INSERT INTO Auditoria (TablaAfectada, Accion, RegistroID, ValorAnterior)
    SELECT 'Productos', 'DELETE LOGICO', ProductoID,
           'Marcado como inactivo: ' + Nombre
    FROM deleted;
END;
GO

-- 🔹 INSTEAD OF INSERT - Con validaciones
CREATE TRIGGER trg_EnLugarInsertar
ON Productos
INSTEAD OF INSERT
AS
BEGIN
    PRINT '=== TRIGGER INSTEAD OF INSERT ACTIVADO ===';
    PRINT 'Validando datos antes de insertar...';
    
    -- Validación 1: No precio negativo
    IF EXISTS (SELECT * FROM inserted WHERE Precio < 0)
    BEGIN
        PRINT 'ERROR: No se permiten precios negativos';
        RAISERROR('Precio negativo no permitido', 16, 1);
        RETURN;
    END
    
    -- Validación 2: No stock negativo  
    IF EXISTS (SELECT * FROM inserted WHERE Stock < 0)
    BEGIN
        PRINT 'ERROR: No se permiten stocks negativos';
        RAISERROR('Stock negativo no permitido', 16, 1);
        RETURN;
    END
    
    -- Validación 3: Precio muy bajo
    IF EXISTS (SELECT * FROM inserted WHERE Precio < 50)
    BEGIN
        PRINT 'ADVERTENCIA: Precio muy bajo - revisar';
    END
    
    -- Si pasa todas las validaciones, hacer el INSERT real
    INSERT INTO Productos (Nombre, Precio, Stock, FechaCreacion, Activo)
    SELECT Nombre, Precio, Stock, GETDATE(), 1
    FROM inserted;
    
    PRINT 'Producto insertado correctamente después de validaciones';
END;
GO
```

```sql
-- =============================================
-- 3. TRIGGERS COMBINADOS
-- =============================================

-- 🔹 Trigger para múltiples eventos
CREATE TRIGGER trg_TodoEnUno
ON Clientes
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    PRINT '=== TRIGGER COMBINADO ACTIVADO ===';
    
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        PRINT 'Acción: UPDATE en Clientes';
        INSERT INTO Auditoria (TablaAfectada, Accion, RegistroID)
        SELECT 'Clientes', 'UPDATE', ClienteID FROM inserted;
    END
    ELSE IF EXISTS (SELECT * FROM inserted)
    BEGIN
        PRINT 'Acción: INSERT en Clientes'; 
        INSERT INTO Auditoria (TablaAfectada, Accion, RegistroID)
        SELECT 'Clientes', 'INSERT', ClienteID FROM inserted;
    END
    ELSE IF EXISTS (SELECT * FROM deleted)
    BEGIN
        PRINT 'Acción: DELETE en Clientes';
        INSERT INTO Auditoria (TablaAfectada, Accion, RegistroID)
        SELECT 'Clientes', 'DELETE', ClienteID FROM deleted;
    END
    
    PRINT 'Acción registrada en auditoría';
END;
GO

-- 🔹 Trigger que calcula automáticamente
CREATE TRIGGER trg_CalcularTotalVenta
ON Ventas
AFTER INSERT, UPDATE
AS
BEGIN
    PRINT '=== TRIGGER CALCULADOR ACTIVADO ===';
    
    -- Calcular el total automáticamente
    UPDATE Ventas
    SET Total = Cantidad * PrecioUnitario
    WHERE VentaID IN (SELECT VentaID FROM inserted);
    
    PRINT 'Total calculado automáticamente: Cantidad * PrecioUnitario';
    
    -- Actualizar stock del producto
    UPDATE Productos
    SET Stock = Stock - i.Cantidad
    FROM Productos p
    INNER JOIN inserted i ON p.ProductoID = i.ProductoID;
    
    PRINT 'Stock actualizado automáticamente';
END;
GO
```

```sql
-- =============================================
-- INSTRUCCIONES PARA PRACTICAR
-- =============================================

PRINT '¡BASE DE DATOS LISTA PARA PRACTICAR!';
PRINT '';
PRINT 'INSTRUCCIONES:';
PRINT '1. ABRE UNA NUEVA CONSULTA SQL';
PRINT '2. USA ESTA BASE: USE PracticaTriggers;';
PRINT '3. EJECUTA LOS SIGUIENTES COMANDOS:';
PRINT '';
PRINT '=== PROBAR AFTER INSERT ===';
PRINT 'INSERT INTO Productos (Nombre, Precio, Stock) VALUES (''Smartphone'', 2500.00, 5);';
PRINT '';
PRINT '=== PROBAR AFTER UPDATE ===';  
PRINT 'UPDATE Productos SET Precio = 5000.00 WHERE Nombre = ''Laptop HP'';';
PRINT '';
PRINT '=== PROBAR INSTEAD OF DELETE ===';
PRINT 'DELETE FROM Productos WHERE Nombre = ''Mouse Inalámbrico'';';
PRINT '';
PRINT '=== PROBAR INSTEAD OF INSERT (ERROR) ===';
PRINT 'INSERT INTO Productos (Nombre, Precio, Stock) VALUES (''Producto Malo'', -100, 5);';
PRINT '';
PRINT '=== PROBAR TRIGGER COMBINADO ===';
PRINT 'UPDATE Clientes SET Email = ''nuevo@email.com'' WHERE Nombre = ''Ana García'';';
PRINT '';
PRINT '=== VER RESULTADOS ===';
PRINT 'SELECT * FROM Auditoria;';
PRINT 'SELECT * FROM HistoricoPrecios;';
PRINT 'SELECT * FROM Productos;';
GO
```
