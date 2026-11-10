-- ============================================================
-- Proyecto 1 — Segmentación RFM de clientes B2B
-- Recency  = días desde el último pedido completado
-- Frequency= nº de pedidos completados
-- Monetary = facturación total (pedidos completados)
-- Cada dimensión se puntúa 1-5 con NTILE (quintiles) y se asigna
-- un segmento accionable a partir de R y F.
-- Fecha de referencia = último pedido del dataset (RFM estático).
-- Dialecto: SQLite (julianday/strftime/NTILE). En T-SQL: DATEDIFF.
-- ============================================================

WITH ref AS (
    SELECT MAX(fecha_pedido) AS fecha_ref
    FROM pedidos WHERE estado = 'Completado'
),
base AS (
    SELECT
        c.cliente_id,
        c.nombre_empresa,
        c.segmento,
        CAST(julianday((SELECT fecha_ref FROM ref))
             - julianday(MAX(p.fecha_pedido)) AS INT)  AS recency_dias,
        COUNT(p.pedido_id)                               AS frequency,
        ROUND(SUM(p.monto_total), 2)                     AS monetary
    FROM clientes c
    JOIN pedidos  p ON p.cliente_id = c.cliente_id
                   AND p.estado = 'Completado'
    GROUP BY c.cliente_id, c.nombre_empresa, c.segmento
),
scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_dias DESC) AS r_score,  -- más reciente = 5
        NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,  -- más frecuente = 5
        NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score   -- más gasto = 5
    FROM base
)
SELECT
    cliente_id, nombre_empresa, segmento,
    recency_dias, frequency, monetary,
    r_score, f_score, m_score,
    (r_score || f_score || m_score) AS celda_rfm,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 THEN 'Campeones'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Leales'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'Nuevos / Potenciales'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'En riesgo'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernando / Perdidos'
        ELSE 'Necesitan atención'
    END AS segmento_rfm
FROM scores
ORDER BY r_score DESC, f_score DESC, m_score DESC;
