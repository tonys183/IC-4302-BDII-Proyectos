--- Mostrar a los clientes que hayan gastado más de 4000 en supplies ---
SELECT (c.first_name || ' ' || c.last_name1) AS nombre_completo, s.supply_name, od.quantity, (od.quantity * od.unit_price) AS total_detalle FROM OrderDetail od
INNER JOIN Supply s ON od.supply_id = s.supply_id
INNER JOIN CustomerOrder o ON od.order_id = o.order_id
INNER JOIN Client c ON o.client_id = c.client_id
WHERE (od.quantity * od.unit_price) >= 4000 AND od.supply_id IS NOT NULL;

--- Mostrar a todos los clientes, y los libros que han comprado, pueden ser 0 ---
SELECT (c.first_name || ' ' || c.last_name1) AS nombre_completo, COUNT(od.book_id) AS libros_comprados FROM OrderDetail od
RIGHT JOIN CustomerOrder o ON od.order_id = o.order_id AND od.book_id IS NOT NULL
RIGHT JOIN Client c ON o.client_id = c.client_id
GROUP BY c.client_id, c.first_name, c.last_name1;

--- Mostrar todos los libros, y sus ventas totales en orden de mayor a menor ---
SELECT b.book_name, (a.first_name || ' ' || a.last_name1 || ' ' || NVL(a.last_name2, '')) AS autor_completo, b.ISBN, p.publisher_name, COUNT(od.book_id) AS libros_vendidos FROM Book b
LEFT JOIN OrderDetail od ON b.book_id = od.book_id
LEFT JOIN Book_Author ba ON b.book_id = ba.book_id
LEFT JOIN Author a ON ba.author_id = a.author_id
LEFT JOIN Publisher p ON b.publisher_id = p.publisher_id
GROUP BY b.book_id, b.book_name, b.ISBN, a.first_name, a.last_name1, a.last_name2, p.publisher_name
ORDER BY libros_vendidos DESC;