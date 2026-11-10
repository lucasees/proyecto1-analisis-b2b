-- ============================================================
-- Proyecto 1 — Análisis de cohortes / retención B2B
-- Cohorte      = trimestre de alta del cliente (fecha_alta).
-- Período      = trimestres transcurridos desde el alta (offset).
-- Retención    = clientes de la cohorte con ≥1 pedido completado
--                en ese trimestre / tamaño de la cohorte.
-- Índice de trimestre = año*4 + trimestre  (permite restar offsets).
-- Dialecto: SQLite (strftime). En T-SQL: DATEPART(QUARTER,...).
-- ============================================================

WITH c AS (   -- cohorte de cada cliente
    SELECT
        cliente_id,
        CAST(strftime('%Y', fecha_alta) AS INT) * 4
            + (CAST(strftime('%m', fecha_alta) AS INT) + 2) / 3 AS cohorte_q
    FROM clientes
),
a AS (        -- trimestres en los que cada cliente estuvo activo
    SELECT DISTINCT
        p.cliente_id,
        CAST(strftime('%Y', p.fecha_pedido) AS INT) * 4
            + (CAST(strftime('%m', p.fecha_pedido) AS INT) + 2) / 3 AS periodo_q
    FROM pedidos p
    WHERE p.estado = 'Completado'
),
tamano AS (
    SELECT cohorte_q, COUNT(*) AS n_cohorte
    FROM c GROUP BY cohorte_q
),
ret AS (
    SELECT
        c.cohorte_q,
        (a.periodo_q - c.cohorte_q)        AS offset_trim,
        COUNT(DISTINCT a.cliente_id)       AS activos
    FROM c
    JOIN a ON a.cliente_id = c.cliente_id
    WHERE a.periodo_q >= c.cohorte_q
    GROUP BY c.cohorte_q, offset_trim
)
SELECT
    ((r.cohorte_q - 1) / 4) || '-Q'
        || (r.cohorte_q - ((r.cohorte_q - 1) / 4) * 4)  AS cohorte,
    t.n_cohorte,
    r.offset_trim,
    r.activos,
    ROUND(100.0 * r.activos / t.n_cohorte, 1)           AS retencion_pct
FROM ret r
JOIN tamano t ON t.cohorte_q = r.cohorte_q
ORDER BY r.cohorte_q, r.offset_trim;
