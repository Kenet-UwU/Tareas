```sql

-- 1. Declarar variables para guardar datos
DECLARE @ProductoID INT, @Nombre VARCHAR(50), @Precio DECIMAL(10,2);

-- 2. Crear el cursor (señalar los datos)
DECLARE mi_cursor CURSOR FOR
SELECT ID, Nombre, Precio FROM Productos;

-- 3. Abrir el cursor (empezar a señalar)
OPEN mi_cursor;

-- 4. Señalar la primera fila y guardar sus datos
FETCH NEXT FROM mi_cursor INTO @ProductoID, @Nombre, @Precio;

-- 5. Mientras haya filas por señalar...
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Hacer algo con los datos de esta fila
    PRINT 'Producto: ' + @Nombre + ' - Precio: Q' + CAST(@Precio AS VARCHAR);
    
    -- Señalar la siguiente fila
    FETCH NEXT FROM mi_cursor INTO @ProductoID, @Nombre, @Precio;
END;

-- 6. Cerrar y limpiar
CLOSE mi_cursor;
DEALLOCATE mi_cursor;

```
