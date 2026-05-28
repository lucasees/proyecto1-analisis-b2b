-- Productos más vendidos por categoría
SELECT 
    pr.categoria,
    pr.nombre_producto,
    SUM(dp.cantidad)                AS unidades_vendidas,
    ROUND(SUM(dp.subtotal), 2)      AS facturacion_total,
    COUNT(DISTINCT dp.pedido_id)    AS aparece_en_pedidos
FROM detalle_pedidos dp
INNER JOIN productos pr ON dp.producto_id = pr.producto_id
INNER JOIN pedidos p ON dp.pedido_id = p.pedido_id
WHERE p.estado = 'Completado'
GROUP BY pr.categoria, pr.nombre_producto
ORDER BY pr.categoria, facturacion_total DESC;